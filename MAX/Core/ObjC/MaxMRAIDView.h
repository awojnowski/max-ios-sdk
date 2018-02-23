//
//  MaxMRAIDView.h
//  MRAID
//
//  Created by Jay Tucker on 9/13/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MaxMRAIDView;
@protocol MaxMRAIDServiceDelegate;

// A delegate for MRAIDView to listen for notification on ad ready or expand related events.
@protocol MaxMRAIDViewDelegate <NSObject>

@optional

// These callbacks are for basic banner ad functionality.
- (void)mraidViewAdReady:(MaxMRAIDView *)mraidView;
- (void)mraidViewAdFailed:(MaxMRAIDView *)mraidView error:(NSError *)error;
- (void)mraidViewWillExpand:(MaxMRAIDView *)mraidView;
- (void)mraidViewDidClose:(MaxMRAIDView *)mraidView;
- (void)mraidViewNavigate:(MaxMRAIDView *)mraidView withURL:(NSURL *)url;

// This callback is to ask permission to resize an ad.
- (BOOL)mraidViewShouldResize:(MaxMRAIDView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen;

@end

@interface MaxMRAIDView : UIView

@property (nonatomic, weak) id<MaxMRAIDViewDelegate> delegate;
@property (nonatomic, weak) id<MaxMRAIDServiceDelegate> serviceDelegate;
@property (nonatomic, weak, setter = setRootViewController:) UIViewController *rootViewController;
@property (nonatomic, assign, getter = isViewable, setter = setIsViewable:) BOOL isViewable;

// IMPORTANT: This is the only valid initializer for an MRAIDView; -init and -initWithFrame: will throw exceptions
- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
  supportedFeatures:(NSArray *)features
           delegate:(id<MaxMRAIDViewDelegate>)delegate
   serviceDelegate:(id<MaxMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController;

- (void)cancel;

@end
