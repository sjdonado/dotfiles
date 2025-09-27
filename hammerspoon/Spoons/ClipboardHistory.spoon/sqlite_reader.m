#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <stdio.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            printf("Usage: %s <db_file> <mode> [limit] [query]\n", argv[0]);
            printf("Modes:\n");
            printf("  recent <limit>           - Get recent N entries\n");
            printf("  search <query> [limit]   - Search entries using FTS5\n");
            printf("  search_sorted <query> [limit] - Search with prefix/contains sorting\n");
            printf("  count                    - Get total entry count\n");
            return 1;
        }

        NSString *dbPath = [NSString stringWithUTF8String:argv[1]];
        NSString *mode = [NSString stringWithUTF8String:argv[2]];

        sqlite3 *db;
        int rc = sqlite3_open([dbPath UTF8String], &db);

        if (rc != SQLITE_OK) {
            printf("ERROR: Cannot open database: %s\n", sqlite3_errmsg(db));
            sqlite3_close(db);
            return 1;
        }

        // Create tables with FTS5 support if they don't exist
        const char *createSQL =
            "CREATE TABLE IF NOT EXISTS clipboard_history ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "content TEXT NOT NULL,"
            "type TEXT NOT NULL,"
            "preview TEXT NOT NULL,"
            "size TEXT NOT NULL,"
            "timestamp INTEGER NOT NULL,"
            "time TEXT NOT NULL"
            ");"

            "CREATE VIRTUAL TABLE IF NOT EXISTS clipboard_fts USING fts5("
            "content, preview, content=clipboard_history, content_rowid=id"
            ");"

            "CREATE TRIGGER IF NOT EXISTS clipboard_fts_insert AFTER INSERT ON clipboard_history BEGIN"
            "  INSERT INTO clipboard_fts(rowid, content, preview) VALUES (new.id, new.content, new.preview);"
            "END;"

            "CREATE TRIGGER IF NOT EXISTS clipboard_fts_delete AFTER DELETE ON clipboard_history BEGIN"
            "  INSERT INTO clipboard_fts(clipboard_fts, rowid, content, preview) VALUES('delete', old.id, old.content, old.preview);"
            "END;"

            "CREATE TRIGGER IF NOT EXISTS clipboard_fts_update AFTER UPDATE ON clipboard_history BEGIN"
            "  INSERT INTO clipboard_fts(clipboard_fts, rowid, content, preview) VALUES('delete', old.id, old.content, old.preview);"
            "  INSERT INTO clipboard_fts(rowid, content, preview) VALUES (new.id, new.content, new.preview);"
            "END;";

        char *errMsg = 0;
        rc = sqlite3_exec(db, createSQL, 0, 0, &errMsg);

        if (rc != SQLITE_OK) {
            printf("ERROR: SQL error: %s\n", errMsg);
            sqlite3_free(errMsg);
            sqlite3_close(db);
            return 1;
        }

        sqlite3_stmt *stmt;
        const char *sql;

        if ([mode isEqualToString:@"recent"]) {
            int limit = (argc > 3) ? atoi(argv[3]) : 25;

            sql = "SELECT id, content, type, preview, size, timestamp, time "
                  "FROM clipboard_history "
                  "ORDER BY timestamp DESC "
                  "LIMIT ?";

            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("ERROR: Cannot prepare statement: %s\n", sqlite3_errmsg(db));
                sqlite3_close(db);
                return 1;
            }

            sqlite3_bind_int(stmt, 1, limit);

        } else if ([mode isEqualToString:@"search"]) {
            if (argc < 4) {
                printf("ERROR: Search query required\n");
                sqlite3_close(db);
                return 1;
            }

            NSString *query = [NSString stringWithUTF8String:argv[3]];

            int limit = (argc > 4) ? atoi(argv[4]) : 100;

            sql = "SELECT h.id, h.content, h.type, h.preview, h.size, h.timestamp, h.time "
                  "FROM clipboard_history h "
                  "JOIN clipboard_fts f ON h.id = f.rowid "
                  "WHERE clipboard_fts MATCH ? "
                  "ORDER BY h.timestamp DESC "
                  "LIMIT ?";

            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("ERROR: Cannot prepare statement: %s\n", sqlite3_errmsg(db));
                sqlite3_close(db);
                return 1;
            }

            sqlite3_bind_text(stmt, 1, [query UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 2, limit);

        } else if ([mode isEqualToString:@"search_sorted"]) {
            if (argc < 4) {
                printf("ERROR: Search query required\n");
                sqlite3_close(db);
                return 1;
            }

            NSString *query = [NSString stringWithUTF8String:argv[3]];
            int limit = (argc > 4) ? atoi(argv[4]) : 100;
            NSString *escapedQuery = [query stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];

            // Create different FTS5 queries for different match types
            // 1. Exact prefix matching with word boundaries
            NSString *prefixQuery = [NSString stringWithFormat:@"\"%@\"*", escapedQuery];
            // 2. Word prefix matching (any word starting with query)
            NSString *wordPrefixQuery = [NSString stringWithFormat:@"%@*", escapedQuery];
            // 3. Contains matching (phrase anywhere in text)
            NSString *containsQuery = [NSString stringWithFormat:@"\"%@\"", escapedQuery];

            // Use UNION to combine different match types with priorities:
            // Priority 1: Exact prefix matches (text starts with query)
            // Priority 2: Word prefix matches (any word starts with query)
            // Priority 3: Contains matches (query appears anywhere)
            sql = "SELECT h.id, h.content, h.type, h.preview, h.size, h.timestamp, h.time, 1 as match_priority "
                  "FROM clipboard_history h "
                  "JOIN clipboard_fts f ON h.id = f.rowid "
                  "WHERE clipboard_fts MATCH ? "
                  "UNION "
                  "SELECT h.id, h.content, h.type, h.preview, h.size, h.timestamp, h.time, 2 as match_priority "
                  "FROM clipboard_history h "
                  "JOIN clipboard_fts f ON h.id = f.rowid "
                  "WHERE clipboard_fts MATCH ? "
                  "AND h.id NOT IN ("
                  "  SELECT h2.id FROM clipboard_history h2 "
                  "  JOIN clipboard_fts f2 ON h2.id = f2.rowid "
                  "  WHERE clipboard_fts MATCH ?"
                  ") "
                  "UNION "
                  "SELECT h.id, h.content, h.type, h.preview, h.size, h.timestamp, h.time, 3 as match_priority "
                  "FROM clipboard_history h "
                  "JOIN clipboard_fts f ON h.id = f.rowid "
                  "WHERE clipboard_fts MATCH ? "
                  "AND h.id NOT IN ("
                  "  SELECT h2.id FROM clipboard_history h2 "
                  "  JOIN clipboard_fts f2 ON h2.id = f2.rowid "
                  "  WHERE clipboard_fts MATCH ? OR clipboard_fts MATCH ?"
                  ") "
                  "ORDER BY match_priority ASC, timestamp DESC "
                  "LIMIT ?";

            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("ERROR: Cannot prepare statement: %s\n", sqlite3_errmsg(db));
                sqlite3_close(db);
                return 1;
            }

            sqlite3_bind_text(stmt, 1, [prefixQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 2, [wordPrefixQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 3, [prefixQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 4, [containsQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 5, [prefixQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(stmt, 6, [wordPrefixQuery UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 7, limit);

        } else if ([mode isEqualToString:@"count"]) {
            sql = "SELECT COUNT(*) FROM clipboard_history";

            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                printf("ERROR: Cannot prepare statement: %s\n", sqlite3_errmsg(db));
                sqlite3_close(db);
                return 1;
            }

        } else {
            printf("ERROR: Invalid mode '%s'\n", [mode UTF8String]);
            sqlite3_close(db);
            return 1;
        }

        // Execute query and build JSON
        NSMutableArray *results = [[NSMutableArray alloc] init];

        if ([mode isEqualToString:@"count"]) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                int count = sqlite3_column_int(stmt, 0);
                printf("{\"count\":%d}", count);
            }
        } else {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                NSMutableDictionary *entry = [[NSMutableDictionary alloc] init];

                [entry setObject:[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)] forKey:@"id"];
                [entry setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 1)] forKey:@"content"];
                [entry setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 2)] forKey:@"type"];
                [entry setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 3)] forKey:@"preview"];
                [entry setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 4)] forKey:@"size"];
                [entry setObject:[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 5)] forKey:@"timestamp"];
                [entry setObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, 6)] forKey:@"time"];

                // Only include match_priority for search_sorted mode
                if ([mode isEqualToString:@"search_sorted"] && sqlite3_column_count(stmt) > 7) {
                    [entry setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 7)] forKey:@"match_priority"];
                }

                [results addObject:entry];
            }

            // Output JSON array
            NSError *jsonError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:results
                                                               options:0
                                                                 error:&jsonError];
            if (jsonData && !jsonError) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                printf("%s", [jsonString UTF8String]);
            } else {
                printf("ERROR: JSON serialization failed\n");
                sqlite3_finalize(stmt);
                sqlite3_close(db);
                return 1;
            }
        }

        sqlite3_finalize(stmt);
        sqlite3_close(db);
    }
    return 0;
}
