//
//  SleepStatusHelper.h
//  SmartSleep
//
//  Created by Anders Borch on 14/04/2019.
//  Copyright © 2019 Anders Borch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SleepStatusHelper : NSObject

-(void)registerAppforSleepStatus;
+(void)setAwake;

@end

NS_ASSUME_NONNULL_END
