//
//  MaxMRAIDResizeProperties.m
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "MaxMRAIDResizeProperties.h"

@implementation MaxMRAIDResizeProperties

- (id)init
{
    self = [super init];
    if (self) {
        _width = 0;
        _height = 0;
        _offsetX = 0;
        _offsetY = 0;
        _customClosePosition = MRAIDCustomClosePositionTopRight;
        _allowOffscreen = YES;
    }
    return self;
}

+ (MaxMRAIDCustomClosePosition)MRAIDCustomClosePositionFromString:(NSString *)s
{
    NSArray *names = @[
                       @"top-left",
                       @"top-center",
                       @"top-right",
                       @"center",
                       @"bottom-left",
                       @"bottom-center",
                       @"bottom-right"
                       ];
    NSUInteger i = [names indexOfObject:s];
    if (i != NSNotFound) {
        return (MaxMRAIDCustomClosePosition)i;
    }
    // Use top-right for the default value
    return MRAIDCustomClosePositionTopRight;;
}

@end
