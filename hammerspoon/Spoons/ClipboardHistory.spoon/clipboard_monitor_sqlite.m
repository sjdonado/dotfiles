#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <stdio.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Get database limit from command line argument, default to 1000
        int maxEntries = 1000;
        if (argc > 1) {
            maxEntries = atoi(argv[1]);
            if (maxEntries <= 0) {
                maxEntries = 1000;
            }
        }

        // Get database path in current working directory
        NSString *currentDir = [[NSFileManager defaultManager] currentDirectoryPath];
        NSString *dbPath = [currentDir stringByAppendingPathComponent:@"clipboard_history.db"];
        const char *dbPathCString = [dbPath UTF8String];

        sqlite3 *db;
        int rc = sqlite3_open(dbPathCString, &db);

        if (rc != SQLITE_OK) {
            printf("ERROR: Cannot open database: %s\n", sqlite3_errmsg(db));
            sqlite3_close(db);
            return 1;
        }

        // Create tables with FTS5 support
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

        // Get clipboard content
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        if (!pasteboard) {
            printf("ERROR: Could not access pasteboard\n");
            sqlite3_close(db);
            return 1;
        }

        NSArray<NSString *> *types = [pasteboard types];
        if (!types || [types count] == 0) {
            printf("ERROR: No pasteboard types\n");
            sqlite3_close(db);
            return 1;
        }

        // Determine content type and get content
        NSString *contentType = @"Text";
        NSString *content = nil;
        NSString *preview = nil;
        NSString *sizeDisplay = @"";

        // Check for images first (screenshots)
        if ([types containsObject:@"public.png"]) {
            contentType = @"PNG image";
            NSData *imageData = [pasteboard dataForType:@"public.png"];
            if (imageData && [imageData length] > 0) {
                double sizeKB = (double)[imageData length] / 1024.0;

                // Save image to temp file
                NSString *tempDir = NSTemporaryDirectory();
                NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
                NSString *tempImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"clipboard_image_%@.png", timestamp]];

                BOOL saved = [imageData writeToFile:tempImagePath atomically:YES];
                if (saved) {
                    content = tempImagePath;
                } else {
                    NSString *desktopPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd 'at' HH.mm.ss"];
                    NSString *formattedTime = [formatter stringFromDate:[NSDate date]];
                    content = [desktopPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Screenshot %@.png", formattedTime]];
                }

                preview = [NSString stringWithFormat:@"Screenshot (%.1f KB)", sizeKB];
                if ([imageData length] >= 1024 * 1024) {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f MB", sizeKB / 1024.0];
                } else {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f KB", sizeKB];
                }
            }
        } else if ([types containsObject:@"public.jpeg"]) {
            contentType = @"JPEG image";
            NSData *imageData = [pasteboard dataForType:@"public.jpeg"];
            if (imageData && [imageData length] > 0) {
                double sizeKB = (double)[imageData length] / 1024.0;

                NSString *tempDir = NSTemporaryDirectory();
                NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
                NSString *tempImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"clipboard_image_%@.jpg", timestamp]];

                BOOL saved = [imageData writeToFile:tempImagePath atomically:YES];
                if (saved) {
                    content = tempImagePath;
                } else {
                    NSString *desktopPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd 'at' HH.mm.ss"];
                    NSString *formattedTime = [formatter stringFromDate:[NSDate date]];
                    content = [desktopPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Image %@.jpg", formattedTime]];
                }

                preview = [NSString stringWithFormat:@"JPEG Image (%.1f KB)", sizeKB];
                if ([imageData length] >= 1024 * 1024) {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f MB", sizeKB / 1024.0];
                } else {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f KB", sizeKB];
                }
            }
        } else if ([types containsObject:@"public.file-url"]) {
            contentType = @"File path";
            NSString *fileURL = [pasteboard stringForType:@"public.file-url"];
            if (fileURL && [fileURL length] > 0) {
                NSURL *url = [NSURL URLWithString:fileURL];
                if (url && [url path]) {
                    content = [url path];
                    preview = [url lastPathComponent];
                } else {
                    content = fileURL;
                    preview = fileURL;
                }
                NSUInteger urlLength = [fileURL length];
                if (urlLength >= 1024) {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f KB", (double)urlLength / 1024.0];
                } else {
                    sizeDisplay = [NSString stringWithFormat:@"%lu bytes", (unsigned long)urlLength];
                }
            }
        } else {
            // Try to get text content
            NSString *stringContent = [pasteboard stringForType:@"public.utf8-plain-text"];
            if (!stringContent || [stringContent length] == 0) {
                stringContent = [pasteboard stringForType:@"NSStringPboardType"];
            }

            if (stringContent && [stringContent length] > 0) {
                NSString *strippedContent = [stringContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([strippedContent length] == 0) {
                    printf("ERROR: Content is only whitespace\n");
                    sqlite3_close(db);
                    return 1;
                }

                contentType = @"Text";
                content = stringContent;
                preview = stringContent;
                NSUInteger textLength = [stringContent length];
                if (textLength >= 1024) {
                    sizeDisplay = [NSString stringWithFormat:@"%.1f KB", (double)textLength / 1024.0];
                } else {
                    sizeDisplay = [NSString stringWithFormat:@"%lu bytes", (unsigned long)textLength];
                }
            }
        }

        if (!content || [content length] == 0) {
            printf("ERROR: No clipboard content found\n");
            sqlite3_close(db);
            return 1;
        }

        // Clean up preview
        if ([preview length] > 80) {
            preview = [[preview substringToIndex:77] stringByAppendingString:@"..."];
        }
        preview = [preview stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        preview = [preview stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        preview = [preview stringByReplacingOccurrencesOfString:@"\t" withString:@" "];

        // Get timestamp
        NSDate *now = [NSDate date];
        NSUInteger timestamp = (NSUInteger)[now timeIntervalSince1970];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *timeString = [dateFormatter stringFromDate:now];

        // Check for duplicates in last 25 entries
        const char *checkDuplicateSQL =
            "SELECT id, timestamp, time FROM clipboard_history "
            "WHERE content = ? "
            "ORDER BY timestamp DESC "
            "LIMIT 25";

        sqlite3_stmt *stmt;
        rc = sqlite3_prepare_v2(db, checkDuplicateSQL, -1, &stmt, NULL);

        if (rc != SQLITE_OK) {
            printf("ERROR: Cannot prepare statement: %s\n", sqlite3_errmsg(db));
            sqlite3_close(db);
            return 1;
        }

        sqlite3_bind_text(stmt, 1, [content UTF8String], -1, SQLITE_STATIC);

        long long existingId = -1;
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            existingId = sqlite3_column_int64(stmt, 0);
        }
        sqlite3_finalize(stmt);

        if (existingId >= 0) {
            // Update existing entry
            const char *updateSQL =
                "UPDATE clipboard_history SET timestamp = ?, time = ? WHERE id = ?";

            rc = sqlite3_prepare_v2(db, updateSQL, -1, &stmt, NULL);
            if (rc == SQLITE_OK) {
                sqlite3_bind_int64(stmt, 1, timestamp);
                sqlite3_bind_text(stmt, 2, [timeString UTF8String], -1, SQLITE_STATIC);
                sqlite3_bind_int64(stmt, 3, existingId);

                sqlite3_step(stmt);
                sqlite3_finalize(stmt);

                // Output the updated entry
                printf("{\"id\":%lld,\"content\":\"%s\",\"type\":\"%s\",\"preview\":\"%s\",\"size\":\"%s\",\"timestamp\":%lu,\"time\":\"%s\",\"action\":\"moved\"}",
                       existingId,
                       [[content stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] UTF8String],
                       [contentType UTF8String],
                       [[preview stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] UTF8String],
                       [sizeDisplay UTF8String],
                       (unsigned long)timestamp,
                       [timeString UTF8String]);
            }
        } else {
            // Insert new entry
            const char *insertSQL =
                "INSERT INTO clipboard_history (content, type, preview, size, timestamp, time) "
                "VALUES (?, ?, ?, ?, ?, ?)";

            rc = sqlite3_prepare_v2(db, insertSQL, -1, &stmt, NULL);
            if (rc == SQLITE_OK) {
                sqlite3_bind_text(stmt, 1, [content UTF8String], -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 2, [contentType UTF8String], -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 3, [preview UTF8String], -1, SQLITE_STATIC);
                sqlite3_bind_text(stmt, 4, [sizeDisplay UTF8String], -1, SQLITE_STATIC);
                sqlite3_bind_int64(stmt, 5, timestamp);
                sqlite3_bind_text(stmt, 6, [timeString UTF8String], -1, SQLITE_STATIC);

                if (sqlite3_step(stmt) == SQLITE_DONE) {
                    long long newId = sqlite3_last_insert_rowid(db);

                    // Check if we need to remove old entries to maintain entry limit
                    const char *countSQL = "SELECT COUNT(*) FROM clipboard_history";
                    sqlite3_stmt *countStmt;
                    rc = sqlite3_prepare_v2(db, countSQL, -1, &countStmt, NULL);
                    if (rc == SQLITE_OK) {
                        if (sqlite3_step(countStmt) == SQLITE_ROW) {
                            int totalCount = sqlite3_column_int(countStmt, 0);
                            if (totalCount > maxEntries) {
                                // Remove oldest entries to keep only maxEntries
                                const char *cleanupSQL =
                                    "DELETE FROM clipboard_history "
                                    "WHERE id NOT IN ("
                                    "  SELECT id FROM clipboard_history "
                                    "  ORDER BY timestamp DESC "
                                    "  LIMIT ?"
                                    ")";
                                sqlite3_stmt *cleanupStmt;
                                rc = sqlite3_prepare_v2(db, cleanupSQL, -1, &cleanupStmt, NULL);
                                if (rc == SQLITE_OK) {
                                    sqlite3_bind_int(cleanupStmt, 1, maxEntries);
                                    sqlite3_step(cleanupStmt);
                                    sqlite3_finalize(cleanupStmt);
                                }
                            }
                        }
                        sqlite3_finalize(countStmt);
                    }

                    // Output the new entry
                    printf("{\"id\":%lld,\"content\":\"%s\",\"type\":\"%s\",\"preview\":\"%s\",\"size\":\"%s\",\"timestamp\":%lu,\"time\":\"%s\",\"action\":\"added\"}",
                           newId,
                           [[content stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] UTF8String],
                           [contentType UTF8String],
                           [[preview stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] UTF8String],
                           [sizeDisplay UTF8String],
                           (unsigned long)timestamp,
                           [timeString UTF8String]);
                }
                sqlite3_finalize(stmt);
            }
        }

        sqlite3_close(db);
    }
    return 0;
}
