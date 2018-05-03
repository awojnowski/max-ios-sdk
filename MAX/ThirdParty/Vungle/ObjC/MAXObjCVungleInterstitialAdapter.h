//
//  MAXObjCVungleInterstitialAdapter.h
//  MAX
//
//  Created by Bryan Boyko on 5/3/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

#import <UIKit/UIKit.h>

// NOTE: this delegate can be removed during ObjC rewrite
@protocol MAXObjCVungleInterstitialAdapterDelegate;

// NOTE: This class can't subclass MAXInterstitialAdapater until MAXInterstitialAdapter is rewritten in ObjC (If this class imports a Swift file and a Swift file imports this class, there seems to be issues generating the -Swift.h file)

@interface MAXObjCVungleInterstitialAdapter : NSObject

@property (nonatomic, strong) id<MAXObjCVungleInterstitialAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId;
- (void)loadAd;
- (void)showAdFromRootViewController:(UIViewController *)rvc;

@end


@protocol MAXObjCVungleInterstitialAdapterDelegate <NSObject>

- (void)interstitialDidLoad:(MAXObjCVungleInterstitialAdapter *)interstitialAdapter;
- (void)interstitialWillLogImpression:(MAXObjCVungleInterstitialAdapter *)interstitialAdapter;
- (void)interstitialDidClose:(MAXObjCVungleInterstitialAdapter *)interstitialAdapter;
- (void)vungleError:(NSString *)errorMessage;

@end
