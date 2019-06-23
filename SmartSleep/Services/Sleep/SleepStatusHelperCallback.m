//
//  SleepStatusHelperCallback.m
//  SmartSleep
//
//  Created by Anders Borch on 17/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

#import "SleepStatusHelperCallback.h"
#import "SmartSleep-Swift.h"

static bool sleeping = false;

void sleepStatusChanged(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    sleeping = !sleeping;
    NSLog(@"sleep status changed to %@", sleeping ? @"sleeping" : @"awake");
    [SleepStatusService storeSleepUpdate: sleeping];
    [SleepStatusService backgroundSync];
}

void sleepLockComplete(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    NSLog(@"sleep lock complete");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        setSleeping();
    });
}

void setAwake() {
    if (sleeping == false) return;
    sleeping = false;
    [SleepStatusService storeSleepUpdate: sleeping];
    [SleepStatusService backgroundSync];
}

void setSleeping() {
    if (sleeping == true) return;
    sleeping = true;
    [SleepStatusService storeSleepUpdate: sleeping];
    [SleepStatusService backgroundSync];
}
