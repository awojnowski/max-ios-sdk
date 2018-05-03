//
//  MAXObjCVungleInterstitialAdapter.m
//  MAX
//
//  Created by Bryan Boyko on 5/3/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

#import "MAXObjCVungleInterstitialAdapter.h"
#import <VungleSDK/VungleSDK.h>
#import "MaxCommonLogger.h"

// For some reason Vungle chose to combine it's interstitial logic with the main VungleSDK shared instance. Since the logic is shared, this class will hijack the VungleSDK delegate from MAXObjCVungleConfiguration as soon as loadAd is called.

// NOTE: Logging should be refactored in this class when objc rewrite is done. (Top level logging logic is currently in a Swift class and this file can't import swift until the rewrite is done)

@interface MAXObjCVungleInterstitialAdapter () <VungleSDKDelegate>

@property (nonatomic, strong) NSString *placementId;

@end


@implementation MAXObjCVungleInterstitialAdapter

- (instancetype)initWithPlacementId:(NSString *)placementId
{
    if (self = [super init]) {
        _placementId = placementId;
    }
    return self;
}

- (void)loadAd
{
    if (![VungleSDK sharedSDK].isInitialized) {
        [self reportError:[NSString stringWithFormat:@"%@: cannot load an ad because the Vungle SDK hasn't been initialized yet. MAXCongfiguration.initializeVungleSDK() must be called first.", self]];
        return;
    }
    
    if ([[VungleSDK sharedSDK] isAdCachedForPlacementID:self.placementId]) {
        [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@: attempted to load an ad for placement id <%@>, which Vungle has already loaded into its cache", self, self.placementId]];
        if ([self.delegate respondsToSelector:@selector(interstitialDidLoad:)]) {
            [self.delegate interstitialDidLoad:self];
        }
        return;
    }
    
    // Only set this instance as a delegate of the vungle sdk when load is called. For initialization, the vungle delegate will be set to another class
    [VungleSDK sharedSDK].delegate = self;
    
    NSError *error = nil;
    [[VungleSDK sharedSDK] loadPlacementWithID:self.placementId error:&error];
    
    if (error != nil) {
        [self reportError:[NSString stringWithFormat:@"%@: Unable to load placement with reference <%@>, error <%@>", self, self.placementId, error.localizedDescription]];
    }
}

- (void)showAdFromRootViewController:(UIViewController *)rvc
{
    if (![VungleSDK sharedSDK].isInitialized) {
        [self reportError:[NSString stringWithFormat:@"%@: cannot load an ad because the Vungle SDK hasn't been initialized yet. MAXCongfiguration.initializeVungleSDK() must be called first.", self]];
        return;
    }
    
    if (rvc == nil) {
        [self reportError:[NSString stringWithFormat:@"%@: cannot show an ad on a nil view controller.", self]];
        return;
    }
    
    NSError *error = nil;
    [[VungleSDK sharedSDK] playAd:rvc options:nil placementID:self.placementId error:&error];
    
    if (error != nil) {
        [self reportError:[NSString stringWithFormat:@"%@: error encountered while attempting to play ad <%@>", self, error.localizedDescription]];
    }
}


#pragma mark - VungleSDKDelegate

// Once the SDK finishes caching an ad for a placement, the following callback method is called:
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(NSString *)placementID error:(NSError *)error
{
    [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@: VungleSDKDelegate - vungleAdPlayabilityUpdate for placementId: <%@>", self, placementID]];
    
    if (![self.placementId isEqualToString:placementID]) {
        [self reportError:[NSString stringWithFormat:@"%@: registered an attempt by Vungle to show ad with a placement id <%@> different than its own placement id <%@>", self, placementID, self.placementId]];
        return;
    }
    
    if (error != nil) {
        [self reportError:[NSString stringWithFormat:@"%@: vungle ad playability error <%@>", self, error.localizedDescription]];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidLoad:)]) {
        [self.delegate interstitialDidLoad:self];
    }
}

- (void)vungleWillShowAdForPlacementID:(NSString *)placementID
{
    if (![self.placementId isEqualToString:placementID]) {
        [self reportError:[NSString stringWithFormat:@"%@: registered an attempt by Vungle to show ad with a placement id <%@> different than its own placement id <%@>", self, placementID, self.placementId]];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(interstitialWillLogImpression:)]) {
        [self.delegate interstitialWillLogImpression:self];
    }
}

- (void)vungleWillCloseAdWithViewInfo:(VungleViewInfo *)info placementID:(NSString *)placementID
{
    if (![self.placementId isEqualToString:placementID]) {
        [self reportError:[NSString stringWithFormat:@"%@: registered an attempt by Vungle to show ad with a placement id <%@> different than its own placement id <%@>", self, placementID, self.placementId]];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidClose:)]) {
        [self.delegate interstitialDidClose:self];
    }
}


#pragma mark - errors

- (void)reportError:(NSString *)errorMessage
{
    if ([self.delegate respondsToSelector:@selector(vungleError:)]) {
        [self.delegate vungleError:errorMessage];
    }
}

@end
