//
//  SleepStatusHelper.m
//  SmartSleep
//
//  Created by Anders Borch on 14/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

#import "SleepStatusHelper.h"
#import "SleepStatusHelperCallback.h"
#include <stdint.h>
#include <stdlib.h>

static bool registered = false;

static char *fetch_state_command(void);
static char *fetch_complete_command(void);
static void register_command(char *command, CFNotificationCallback function);

@implementation SleepStatusHelper

-(void)registerAppforSleepStatus {
    if (registered) return;
    registered = YES;
    
    char *command = fetch_state_command();
    register_command(command, sleepStatusChanged);
    free(command);

    command = fetch_complete_command();
    register_command(command, sleepLockComplete);
    free(command);
}

+ (void)setAwake {
    setAwake();
}

@end

static void reverse(char string[]) {
    char temp;
    char *begin = string;
    char *end = string + strlen(string) - 1;
    while (begin < end) {
        temp = *begin;
        *begin++ = *end;
        *end-- = temp;
    }
}



static char *fetch_state_command() {
    char *command = "etatskcol.draobgnirps.elppa.moc";
    char *reversed = malloc(strlen(command) + 1);
    strcpy(reversed, command);
    reverse(reversed);
    return reversed;
}

static char *fetch_complete_command() {
    char *command = "etelpmockcol.draobgnirps.elppa.moc";
    char *reversed = malloc(strlen(command) + 1);
    strcpy(reversed, command);
    reverse(reversed);
    return reversed;
}

static void register_command(char *command, CFNotificationCallback function) {
    CFStringRef string = CFStringCreateWithCString(NULL, command, kCFStringEncodingUTF8);
    NSLog(@"command: %@", string);
    if (string == NULL) return;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    NULL, // observer
                                    function, // callback
                                    string, // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFRelease(string);
}
