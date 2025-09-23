#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>
#import <stdio.h>

int main() {
    @autoreleasepool {
        EKEventStore *store = [[EKEventStore alloc] init];

        // Request access to calendar
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block BOOL accessGranted = NO;

        [store requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError * _Nullable error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        }];

        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

        if (!accessGranted) {
            printf("ACCESS_DENIED");
            return 1;
        }

        // Get today's date range
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *now = [NSDate date];
        NSDate *startOfDay = [calendar startOfDayForDate:now];
        NSDate *endOfDay = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];

        // Create predicate for today's events
        NSPredicate *predicate = [store predicateForEventsWithStartDate:startOfDay endDate:endOfDay calendars:nil];
        NSArray<EKEvent *> *events = [store eventsMatchingPredicate:predicate];

        printf("COUNT:%lu||", (unsigned long)[events count]);

        for (EKEvent *event in events) {
            NSTimeInterval timeDiff = [event.startDate timeIntervalSinceDate:now];
            NSString *title = event.title ?: @"";
            NSString *notes = event.notes ?: @"";
            BOOL hasRecurrence = (event.recurrenceRules.count > 0);

            // Format times
            NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
            timeFormatter.dateFormat = @"HH:mm";
            NSString *startTime = [timeFormatter stringFromDate:event.startDate];
            NSString *endTime = [timeFormatter stringFromDate:event.endDate];
            NSString *timeRange = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];

            // Handle recurring events - calculate today's occurrence
            if (hasRecurrence && (timeDiff < -86400 || timeDiff > 86400)) {
                NSCalendar *cal = [NSCalendar currentCalendar];
                NSDateComponents *timeComponents = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
                                                           fromDate:event.startDate];
                NSDateComponents *todayComponents = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                                            fromDate:now];
                todayComponents.hour = timeComponents.hour;
                todayComponents.minute = timeComponents.minute;
                todayComponents.second = timeComponents.second;

                NSDate *todayOccurrence = [cal dateFromComponents:todayComponents];
                timeDiff = [todayOccurrence timeIntervalSinceDate:now];
            }

            printf("%s|%.0f|%s|%s|%s||",
                   [title UTF8String], timeDiff, [timeRange UTF8String],
                   [notes UTF8String], hasRecurrence ? "true" : "false");
        }
    }
    return 0;
}
