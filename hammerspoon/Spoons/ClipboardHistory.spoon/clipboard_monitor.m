#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <stdio.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Hardcode JSON file path to current working directory
        NSString *currentDir = [[NSFileManager defaultManager] currentDirectoryPath];
        NSString *jsonFilePath = [currentDir stringByAppendingPathComponent:@"clipboard_history.json"];

        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        if (!pasteboard) {
            printf("ERROR: Could not access pasteboard\n");
            return 1;
        }

        NSArray<NSString *> *types = [pasteboard types];
        if (!types || [types count] == 0) {
            printf("ERROR: No pasteboard types\n");
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

                // Save image to temp file for preview
                NSString *tempDir = NSTemporaryDirectory();
                NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
                NSString *tempImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"clipboard_image_%@.png", timestamp]];

                BOOL saved = [imageData writeToFile:tempImagePath atomically:YES];
                if (saved) {
                    content = tempImagePath;
                } else {
                    // Fallback to suggested desktop path
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

                // Save image to temp file for preview
                NSString *tempDir = NSTemporaryDirectory();
                NSString *timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
                NSString *tempImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"clipboard_image_%@.jpg", timestamp]];

                BOOL saved = [imageData writeToFile:tempImagePath atomically:YES];
                if (saved) {
                    content = tempImagePath;
                } else {
                    // Fallback to suggested desktop path
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
                    // Store full file path for content, filename for preview
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
                // Strip whitespace and check if content is meaningful
                NSString *strippedContent = [stringContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([strippedContent length] == 0) {
                    printf("ERROR: Content is only whitespace\n");
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

        // If no content found, exit
        if (!content || [content length] == 0) {
            printf("ERROR: No clipboard content found\n");
            return 1;
        }

        // Clean up preview
        if ([preview length] > 80) {
            preview = [[preview substringToIndex:77] stringByAppendingString:@"..."];
        }

        // Replace newlines with spaces
        preview = [preview stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        preview = [preview stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
        preview = [preview stringByReplacingOccurrencesOfString:@"\t" withString:@" "];

        // Get timestamp and date
        NSDate *now = [NSDate date];
        NSTimeInterval timestamp = [now timeIntervalSince1970];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateString = [dateFormatter stringFromDate:now];

        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *timeString = [dateFormatter stringFromDate:now];

        // Load existing history
        NSMutableArray *history = [[NSMutableArray alloc] init];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:jsonFilePath]) {
            NSData *existingData = [NSData dataWithContentsOfFile:jsonFilePath];
            if (existingData && [existingData length] > 0) {
                NSError *parseError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:existingData options:0 error:&parseError];
                if (!parseError && [jsonObject isKindOfClass:[NSArray class]]) {
                    NSArray *existingHistory = (NSArray *)jsonObject;
                    [history addObjectsFromArray:existingHistory];
                }
            }
        }

        // Remove duplicates
        for (NSInteger i = [history count] - 1; i >= 0; i--) {
            id item = [history objectAtIndex:i];
            if ([item isKindOfClass:[NSDictionary class]]) {
                NSDictionary *entry = (NSDictionary *)item;
                id existingContent = [entry objectForKey:@"content"];
                if ([existingContent isKindOfClass:[NSString class]] &&
                    [(NSString *)existingContent isEqualToString:content]) {
                    [history removeObjectAtIndex:i];
                }
            }
        }

        // Create new entry
        NSMutableDictionary *newEntry = [[NSMutableDictionary alloc] init];
        [newEntry setObject:content forKey:@"content"];
        [newEntry setObject:contentType forKey:@"type"];
        [newEntry setObject:preview forKey:@"preview"];
        [newEntry setObject:sizeDisplay forKey:@"size"];
        [newEntry setObject:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
        [newEntry setObject:dateString forKey:@"date"];
        [newEntry setObject:timeString forKey:@"time"];

        // Add to beginning
        [history insertObject:newEntry atIndex:0];

        // Limit to 1000 entries
        if ([history count] > 1000) {
            NSRange rangeToRemove = NSMakeRange(1000, [history count] - 1000);
            [history removeObjectsInRange:rangeToRemove];
        }

        // Save to JSON
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:history
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&jsonError];
        if (jsonData && !jsonError) {
            BOOL success = [jsonData writeToFile:jsonFilePath atomically:YES];
            if (success) {
                printf("SUCCESS: %s entry added\n", [contentType UTF8String]);
            } else {
                printf("ERROR: Failed to write file\n");
                return 1;
            }
        } else {
            printf("ERROR: JSON serialization failed\n");
            return 1;
        }
    }
    return 0;
}
