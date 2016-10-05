//
//  MAXInterstitialAd.m
//  MoVideo
//
//  Copyright © 2016 MoLabs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdSupport/ASIdentifierManager.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "MAXInterstitialAd.h"
#import "SKReachability.h"
#import "SKLogger.h"
#import "SKVASTViewController.h"

@interface MAXInterstitialAd() <SKVASTViewControllerDelegate>

@end

@implementation MAXInterstitialAd {
    NSString* _placementID;
    SKVASTViewController* _vc;
    NSData* _videoData;
}

- (instancetype)initWithPlacementID:(NSString*)placementID {
    _placementID = placementID;
    return self;
}

- (void) loadAd {
    // Detect connection characteristics
    bool wifi = [[SKReachability reachabilityForInternetConnection] isReachableViaWiFi];
    bool wwan = [[SKReachability reachabilityForInternetConnection] isReachableViaWWAN];
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];

    // Proceed
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://sprl.com/ads/req/%@", _placementID]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSError *error = nil;
    

    NSDictionary *dictionary = @{
                                 @"ifa": [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString],
                                 @"lmt": [[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled] ? @NO : @YES,
                                 @"vendor_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                 @"tz": [[NSTimeZone systemTimeZone] abbreviation],
                                 @"locale": [[NSLocale systemLocale] localeIdentifier],
                                 @"orientation": UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]) ? @"portrait" : @"landscape",

                                 @"w": @(floor([[UIScreen mainScreen] bounds].size.width)),
                                 @"h": @(floor([[UIScreen mainScreen] bounds].size.height)),
                                 @"carrier": wifi ? @"WIFI" : (wwan ? [carrier carrierName] : @"")
                                 };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions
                                                     error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data
                                                          completionHandler:^(NSData *data,
                                                                              NSURLResponse *response,
                                                                              NSError *error)
                                              {
                                                  if (!error) {
                                                      _videoData = data;
                                                      _adValid = true;
                                                      [_delegate interstitialAdDidLoad:self];
                                                  } else {
                                                      _videoData = nil;
                                                      _adValid = false;
                                                      [_delegate interstitialAd:self didFailWithError:error];
                                                  }
                                              }];
        [uploadTask resume];
    } else {
        _videoData = nil;
        _adValid = false;
        [_delegate interstitialAd:self didFailWithError:error];
    }
}

- (BOOL) showAdFromRootViewController:(UIViewController*)rootViewController {
    [SKLogger setLogLevel:SourceKitLogLevelDebug];
    _vc = [[SKVASTViewController alloc] initWithDelegate:self withViewController:rootViewController];
    [_vc loadVideoWithData:_videoData];
    return true;
}

//
//
//

-(void) vastReady: (SKVASTViewController*) vastVC {
    [vastVC play];
}

-(void) vastTrackingEvent: (NSString*) eventName {
    NSLog(@"vastTrackingEvent(%@)", eventName);
}

-(void) vastDidDismissFullScreen: (SKVASTViewController*) vastVC {
}

-(void) vastOpenBrowseWithUrl:(SKVASTViewController *)vastVC url:(NSURL *)url {
    [vastVC dismissViewControllerAnimated:false completion:^{
        [[UIApplication sharedApplication] openURL:url];
    }];
}


@end