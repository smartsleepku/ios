//
//  SleepStatusHelperCallback.h
//  SmartSleep
//
//  Created by Anders Borch on 17/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void sleepStatusChanged(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo);


NS_ASSUME_NONNULL_END
