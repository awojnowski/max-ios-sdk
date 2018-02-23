//
//  MaxCommonLogger.m
//  SourceKit
//
//  Created by Tom Poland on 9/24/13.
//  Copyright 2013 Nexage Inc. All rights reserved.
//

#import "MaxCommonLogger.h"

// Default setting is SourceKitLogLevelNone.
static SourceKitLogLevel logLevel;

@implementation MaxCommonLogger

+ (void)setLogLevel:(SourceKitLogLevel)level
{
    logLevel = level;
}

+ (void)error:(NSString *)tag withMessage:(NSString *)message
{
    if (logLevel >= SourceKitLogLevelError) {
        NSLog(@"%@: (E) %@", tag, message);
    }
}

+ (void)warning:(NSString *)tag withMessage:(NSString *)message
{
    if (logLevel >= SourceKitLogLevelWarning) {
        NSLog(@"%@: (W) %@", tag, message);
    }
}

+ (void)info:(NSString *)tag withMessage:(NSString *)message
{
    if (logLevel >= SourceKitLogLevelInfo) {
        NSLog(@"%@: (I) %@", tag, message);
    }
}

+ (void)debug:(NSString *)tag withMessage:(NSString *)message
{
    if (logLevel >= SourceKitLogLevelDebug) {
        NSLog(@"%@: (D) %@", tag, message);
    }
}

@end
