//
//  MAXInterstitialAd.h
//  MoVideo
//
//  Copyright © 2016 MoLabs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MAXInterstitialAdDelegate;

/*!
 @class MAXInterstitialAd
 @abstract A modal view controller to represent a Facebook interstitial ad. This
 is a full-screen ad shown in your application.
 */
@interface MAXInterstitialAd : UIViewController

/*!
 @property
 @abstract Typed access to the id of the ad placement.
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/*!
 @property
 @abstract the delegate
 */
@property (nonatomic, weak) id<MAXInterstitialAdDelegate> delegate;

/*!
 @method
 @abstract
 This is a method to initialize an MAXInterstitialAd matching the given placement id.
 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 */
- (instancetype)initWithPlacementID:(NSString *)placementID;

/*!
 @property
 @abstract
 Returns true if the interstitial ad has been successfully loaded.
 @discussion You should check `isAdValid` before trying to show the ad.
 */
@property (nonatomic, getter=isAdValid, readonly) BOOL adValid;

/*!
 @method
 @abstract
 Begins loading the MAXInterstitialAd content.
 @discussion You can implement `interstitialAdDidLoad:` and `interstitialAd:didFailWithError:` methods
 of `MAXInterstitialAdDelegate` if you would like to be notified as loading succeeds or fails.
 */
- (void)loadAd;

/*!
 @method
 @abstract
 Presents the interstitial ad modally from the specified view controller.
 @param rootViewController The view controller that will be used to present the interstitial ad.
 @discussion You can implement `interstitialAdDidClick:`, `interstitialAdWillClose:` and `interstitialAdWillClose`
 methods of `MAXInterstitialAdDelegate` if you would like to stay informed for thoses events
 */
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController;

@end

/*!
 @protocol
 @abstract
 The methods declared by the MAXInterstitialAdDelegate protocol allow the adopting delegate to respond
 to messages from the MAXInterstitialAd class and thus respond to operations such as whether the
 interstitial ad has been loaded, user has clicked or closed the interstitial.
 */
@protocol MAXInterstitialAdDelegate <NSObject>

@optional

/*!
 @method
 @abstract
 Sent after an ad in the MAXInterstitialAd object is clicked. The appropriate app store view or
 app browser will be launched.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(MAXInterstitialAd *)interstitialAd;

/*!
 @method
 @abstract
 Sent after an MAXInterstitialAd object has been dismissed from the screen, returning control
 to your application.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(MAXInterstitialAd *)interstitialAd;

/*!
 @method
 @abstract
 Sent immediately before an MAXInterstitialAd object will be dismissed from the screen.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 */
- (void)interstitialAdWillClose:(MAXInterstitialAd *)interstitialAd;

/*!
 @method
 @abstract
 Sent when an MAXInterstitialAd successfully loads an ad.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(MAXInterstitialAd *)interstitialAd;

/*!
 @method
 @abstract
 Sent when an MAXInterstitialAd failes to load an ad.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)interstitialAd:(MAXInterstitialAd *)interstitialAd didFailWithError:(NSError *)error;

/*!
 @method
 @abstract
 Sent immediately before the impression of an MAXInterstitialAd object will be logged.
 @param interstitialAd An MAXInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(MAXInterstitialAd *)interstitialAd;

@end