//
//  BannerViewController.m
//  MAXiOSSampleAppObjC
//
//  Created by Bryan Boyko on 3/14/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//


/* ============================
 
 
 NOTE DUE TO COCOAPODS INTEGRATION ISSUES FOR MAX SDK INTO OBJC PROJECTS, MAX FILES HAVE BEEN MANUALLY ADDED. SINCE THEY'VE BEEN MANUALLY ADDED, THERE CAN EASILY BE VERSION MISMATCHES. CHECK TO SEE THAT YOU HAVE FILES FROM THE LATEST SDK VERSION.
 
 
 ============================ */


/* TODO
 - add button to load banner (masonry)
 */



#import <Masonry/Masonry.h>
#import "BannerViewController.h"
#import <MoPub/MoPub.h>
#import <MAX/MAX-Swift.h>

static NSString *bannerMAXAdUnitId = @"ag9zfm1heGFkcy0xNTY1MTlyEwsSBkFkVW5pdBiAgICAvKGCCQw";
static NSString *bannerMoPubAdUnitId = @"75fac5e613f54ae5b3087f18becaf395";

@interface BannerViewController () <MPAdViewDelegate, MAXBannerAdViewDelegate>

@end

@implementation BannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize size = CGSizeMake(320, 50);
    MPAdView *mpAdView = [[MPAdView alloc] initWithAdUnitId:bannerMoPubAdUnitId size:size];
    MAXMoPubBanner *maxMpBanner = [[MAXMoPubBanner alloc] initWithMpAdView: mpAdView];
    maxMpBanner.mpAdViewDelegate = self;
    maxMpBanner.maxBannerAdViewDelegate = self;
    maxMpBanner.frame = CGRectMake(50, 100, 320, 50);
    [self.view addSubview:maxMpBanner];
    
    [maxMpBanner loadWithMaxAdUnitId:bannerMAXAdUnitId mpAdUnitId:bannerMoPubAdUnitId];
}

#pragma mark - MPAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view {
    
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view {
    
}

- (void)willPresentModalViewForAd:(MPAdView *)view {
    
}

- (void)didDismissModalViewForAd:(MPAdView *)view {
    
}

- (void)willLeaveApplicationFromAd:(MPAdView *)view {
    
}


#pragma mark - MAXBannerAdViewDelegate

- (void)onBannerLoaded:(MAXBannerAdView *)banner {
    
}

- (void)onBannerClickedWithBanner:(MAXBannerAdView *)banner {
    
}

- (void)onBannerErrorWithBanner:(MAXBannerAdView *)banner error:(MAXClientError *)error {
    
}



@end
