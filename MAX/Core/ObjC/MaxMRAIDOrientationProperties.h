//
//  MaxMRAIDOrientationProperties.h
//  MRAID
//
//  Created by Jay Tucker on 9/16/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MRAIDForceOrientationPortrait,
    MRAIDForceOrientationLandscape,
    MRAIDForceOrientationNone
} MaxMRAIDForceOrientation;

@interface MaxMRAIDOrientationProperties : NSObject

@property (nonatomic, assign) BOOL allowOrientationChange;
@property (nonatomic, assign) MaxMRAIDForceOrientation forceOrientation;

+ (MaxMRAIDForceOrientation)MRAIDForceOrientationFromString:(NSString *)s;

@end
