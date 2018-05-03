//
//  InterstitialViewController.m
//  MAXiOSSampleAppObjC
//
//  Created by Bryan Boyko on 3/15/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//


/* ============================
 
 
 NOTE DUE TO COCOAPODS INTEGRATION ISSUES FOR MAX SDK INTO OBJC PROJECTS, MAX FILES HAVE BEEN MANUALLY ADDED. SINCE THEY'VE BEEN MANUALLY ADDED, THERE CAN EASILY BE VERSION MISMATCHES. CHECK TO SEE THAT YOU HAVE FILES FROM THE LATEST SDK VERSION.
 
 
 ============================ */


/* TODO

 - add button to load interstitial (masonry)
 - add button to show interstitial (masonry)
 */

#import <Masonry/Masonry.h>
#import "InterstitialViewController.h"
#import <MoPub/MoPub.h>
#import <MAX/MAX-Swift.h>

static NSString *interstitialMAXAdUnitId = @"olej28v2vej";
static NSString *interstitialMoPubAdUnitId = @"afa7b8256ba841edbb7d10c43d3614e2";

@interface InterstitialViewController () <MPInterstitialAdControllerDelegate, MAXInterstitialAdDelegate>

@property (nonatomic, strong) MAXMoPubInterstitial *maxMoPubInterstitial;

@end

@implementation InterstitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    // NOTE: An instance of MAXMoPubInterstitial must be created for each ad unit id
    MPInterstitialAdController *mpInterstitialController = [MPInterstitialAdController interstitialAdControllerForAdUnitId:interstitialMoPubAdUnitId];
    self.maxMoPubInterstitial = [[MAXMoPubInterstitial alloc] initWithMaxAdUnitId:interstitialMAXAdUnitId mpInterstitial:mpInterstitialController rootViewController:self];
    self.maxMoPubInterstitial.mpInterstitialDelegate = self;
    self.maxMoPubInterstitial.maxInterstitialDelegate = self;
    [self.maxMoPubInterstitial load];
}

#pragma mark - MPInterstitialAdControllerDelegate

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
    [self.maxMoPubInterstitial show];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialDidAppear:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial {
    
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
    
}


#pragma mark - MAXInterstitialAdDelegate

- (void)interstitialAdDidLoad:(MAXInterstitialAd * _Nonnull)interstitialAd {
    [self.maxMoPubInterstitial show];
}

- (void)interstitialAdDidClick:(MAXInterstitialAd * _Nonnull)interstitialAd {
    
}

- (void)interstitialAdWillClose:(MAXInterstitialAd * _Nonnull)interstitialAd {
    
}

- (void)interstitialAdDidClose:(MAXInterstitialAd * _Nonnull)interstitialAd {
    
}

- (void)interstitial:(MAXInterstitialAd * _Nullable)interstitialAd didFailWithError:(MAXClientError * _Nonnull)error {
    
}

@end
