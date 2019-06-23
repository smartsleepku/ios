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

static char encoding_table[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8', '9', '+', '/'};
static char *decoding_table = NULL;

void build_decoding_table() {
    
    decoding_table = malloc(256);
    
    for (int i = 0; i < 64; i++)
        decoding_table[(unsigned char) encoding_table[i]] = i;
}

static unsigned char *base64_decode(const char *data,
                             size_t input_length,
                             size_t *output_length) {
    
    if (decoding_table == NULL) build_decoding_table();
    
    if (input_length % 4 != 0) return NULL;
    
    *output_length = input_length / 4 * 3;
    if (data[input_length - 1] == '=') (*output_length)--;
    if (data[input_length - 2] == '=') (*output_length)--;
    
    unsigned char *decoded_data = malloc(*output_length);
    if (decoded_data == NULL) return NULL;
    
    for (int i = 0, j = 0; i < input_length;) {
        
        uint32_t sextet_a = data[i] == '=' ? 0 & i++ : decoding_table[data[i++]];
        uint32_t sextet_b = data[i] == '=' ? 0 & i++ : decoding_table[data[i++]];
        uint32_t sextet_c = data[i] == '=' ? 0 & i++ : decoding_table[data[i++]];
        uint32_t sextet_d = data[i] == '=' ? 0 & i++ : decoding_table[data[i++]];
        
        uint32_t triple = (sextet_a << 3 * 6)
        + (sextet_b << 2 * 6)
        + (sextet_c << 1 * 6)
        + (sextet_d << 0 * 6);
        
        if (j < *output_length) decoded_data[j++] = (triple >> 2 * 8) & 0xFF;
        if (j < *output_length) decoded_data[j++] = (triple >> 1 * 8) & 0xFF;
        if (j < *output_length) decoded_data[j++] = (triple >> 0 * 8) & 0xFF;
    }
    
    return decoded_data;
}

void base64_cleanup() {
    free(decoding_table);
}

static char *fetch_state_command() {
    char *command = "ZXRhdHNrY29sLmRyYW9iZ25pcnBzLmVscHBhLm1vYw==";
    char *encoded = malloc(strlen(command) + 1);
    assert(encoded);
    strcpy(encoded, command);
    size_t length = 0;
    char *decoded = (char *)base64_decode(encoded, strlen(encoded), &length);
    assert(decoded);
    free(encoded);
    reverse(decoded);
    assert(decoded);
    return decoded;
}

static char *fetch_complete_command() {
    char *command = "ZXRlbHBtb2NrY29sLmRyYW9iZ25pcnBzLmVscHBhLm1vYw==";
    char *encoded = malloc(strlen(command) + 1);
    assert(encoded);
    strcpy(encoded, command);
    size_t length = 0;
    char *decoded = (char *)base64_decode(encoded, strlen(encoded), &length);
    assert(decoded);
    free(encoded);
    reverse(decoded);
    assert(decoded);
    return decoded;
}

static void register_command(char *command, CFNotificationCallback function) {
    CFStringRef string = CFStringCreateWithCString(NULL, command, kCFStringEncodingUTF8);
    NSLog(@"command: %@", string);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    NULL, // observer
                                    function, // callback
                                    string, // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFRelease(string);
}
