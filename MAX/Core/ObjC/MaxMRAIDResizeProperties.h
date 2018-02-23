//
//  MaxMRAIDResizeProperties.h
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All Rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MRAIDCustomClosePositionTopLeft,
    MRAIDCustomClosePositionTopCenter,
    MRAIDCustomClosePositionTopRight,
    MRAIDCustomClosePositionCenter,
    MRAIDCustomClosePositionBottomLeft,
    MRAIDCustomClosePositionBottomCenter,
    MRAIDCustomClosePositionBottomRight
} MaxMRAIDCustomClosePosition;

@interface MaxMRAIDResizeProperties : NSObject

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int offsetX;
@property (nonatomic, assign) int offsetY;
@property (nonatomic, assign) MaxMRAIDCustomClosePosition customClosePosition;
@property (nonatomic, assign) BOOL allowOffscreen;

+ (MaxMRAIDCustomClosePosition)MRAIDCustomClosePositionFromString:(NSString *)s;

@end
