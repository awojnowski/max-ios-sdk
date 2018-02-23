//
//  MaxMRAIDModalViewController.h
//  MRAID
//
//  Created by Jay Tucker on 9/20/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MaxMRAIDModalViewController;
@class MaxMRAIDOrientationProperties;

@protocol MaxMRAIDModalViewControllerDelegate <NSObject>

- (void)mraidModalViewControllerDidRotate:(MaxMRAIDModalViewController *)modalViewController;

@end

@interface MaxMRAIDModalViewController : UIViewController

@property (nonatomic, unsafe_unretained) id<MaxMRAIDModalViewControllerDelegate> delegate;

- (id)initWithOrientationProperties:(MaxMRAIDOrientationProperties *)orientationProperties;
- (void)forceToOrientation:(MaxMRAIDOrientationProperties *)orientationProperties;

@end
