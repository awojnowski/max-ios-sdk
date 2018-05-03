//
//  MAXObjCVungleConfiguration.m
//  MAX
//
//  Created by Bryan Boyko on 5/2/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

#import "MAXObjCVungleConfiguration.h"
#import <VungleSDK/VungleSDK.h>
#import <VungleSDK/VungleSDKHeaderBidding.h>
#import "MaxCommonLogger.h"


// NOTE: After ObjC rewrite, error and debug logging in this class should be refactored (Currently error logging is done through a swift class that ultimately depends on MAXCommonLogger)

// NOTE: For ObjC rewrite, this class should be turned into a category on MAXConfiguration (MAXConfiguration+Vungle.h)


@interface MAXObjCVungleConfiguration () <VungleSDKDelegate, VungleSDKHeaderBidding>

@property (nonatomic, strong) NSArray <NSString *> *placementIds;

@end


@implementation MAXObjCVungleConfiguration

+ (MAXObjCVungleConfiguration *)shared
{
    static dispatch_once_t pred = 0;
    static MAXObjCVungleConfiguration *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)initializeVungleSDKWithAppId:(NSString *)appId placementIds:(NSArray <NSString *> *)placementIds enabledLogging:(BOOL)enableLogging
{
    [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@ initializing vungle integration", self]];
    
    self.placementIds = placementIds;
    
    VungleSDK *shared = [VungleSDK sharedSDK];
    [shared setLoggingEnabled:enableLogging];
    shared.delegate = self;
    shared.headerBiddingDelegate = self;
    NSError *error = nil;
    [shared startWithAppId:appId placements:placementIds error:&error];
    
    if (error != nil) {
        [self reportError:error];
    }
}

- (NSString *)vungleSDKVersion
{
    return VungleSDKVersion;
}


#pragma mark - VungleSDKDelegate

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(nullable NSString *)placementID error:(nullable NSError *)error
{
    [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@ VungleSDKDelegate - vungleAdPlayabilityUpdate for placement Id <%@> is playable <%d>", self, placementID, isAdPlayable]];
    
    if (error != nil) {
        [self reportError:error];
    }
}

- (void)vungleSDKDidInitialize
{
    [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@ VungleSDKDelegate - vungleSDKDidInitialize", self]];
    
    [self.placementIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSError *error = nil;
        [[VungleSDK sharedSDK] loadPlacementWithID:obj error:&error];
        if (error != nil) {
            [self reportError:error];
        }
    }];
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error
{
    [self reportError:error];
}


#pragma mark - VungleSDKHeaderBidding

- (void)placementPrepared:(NSString *)placement withBidToken:(NSString *)bidToken
{
    [MaxCommonLogger debug:@"MAX" withMessage:[NSString stringWithFormat:@"%@ VungleSDKDelegate - placementPrepared <%@> with bid token <%@>", self, placement, bidToken]];
}


#pragma mark - helper

- (void)reportError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(vungleError:)]) {
        [self.delegate vungleError:error];
    }
}

@end
