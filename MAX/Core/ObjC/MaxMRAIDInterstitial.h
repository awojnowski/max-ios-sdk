//
//  MaxMRAIDInterstitial.h
//  MRAID
//
//  Created by Jay Tucker on 10/18/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class MaxMRAIDInterstitial;
@protocol MaxMRAIDServiceDelegate;

// A delegate for MRAIDInterstitial to handle callbacks for the interstitial lifecycle.
@protocol MaxMRAIDInterstitialDelegate <NSObject>

@optional

- (void)mraidInterstitialAdReady:(MaxMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialAdFailed:(MaxMRAIDInterstitial *)mraidInterstitial error:(NSError *)error;
- (void)mraidInterstitialWillShow:(MaxMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialDidHide:(MaxMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialNavigate:(MaxMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url;

@end

// A class which handles interstitials and offers optional callbacks for its states and services (sms, tel, calendar, etc.)
@interface MaxMRAIDInterstitial : NSObject

@property (nonatomic, unsafe_unretained) id<MaxMRAIDInterstitialDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<MaxMRAIDServiceDelegate> serviceDelegate;
@property (nonatomic, unsafe_unretained, setter = setRootViewController:) UIViewController *rootViewController;
@property (nonatomic, assign, getter = isViewable, setter = setIsViewable:) BOOL isViewable;
@property (nonatomic, copy) UIColor *backgroundColor;

// IMPORTANT: This is the only valid initializer for an MRAIDInterstitial; -init will throw an exception
- (id)initWithSupportedFeatures:(NSArray *)features
                   withHtmlData:(NSString*)htmlData
                    withBaseURL:(NSURL*)bsURL
                       delegate:(id<MaxMRAIDInterstitialDelegate>)delegate
               serviceDelegate:(id<MaxMRAIDServiceDelegate>)serviceDelegate
             rootViewController:(UIViewController *)rootViewController;
- (BOOL)isAdReady;
- (void)show;

@end
