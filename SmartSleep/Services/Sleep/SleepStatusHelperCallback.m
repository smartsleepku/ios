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
}

