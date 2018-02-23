//
//  MaxMRAIDInterstitial.m
//  MRAID
//
//  Created by Jay Tucker on 10/18/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "MaxMRAIDInterstitial.h"
#import "MaxMRAIDView.h"
#import "MaxCommonLogger.h"
#import "MaxMRAIDServiceDelegate.h"

@interface MaxMRAIDInterstitial () <MaxMRAIDViewDelegate, MaxMRAIDServiceDelegate>
{
    BOOL isReady;
    MaxMRAIDView *mraidView;
    NSArray* supportedFeatures;
}

@end

@interface MaxMRAIDView()

- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
     asInterstitial:(BOOL)isInter
  supportedFeatures:(NSArray *)features
           delegate:(id<MaxMRAIDViewDelegate>)delegate
   serviceDelegate:(id<MaxMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController;

@end

static NSString *MaxMRAIDInterstitialErrorDomain = @"MaxMRAIDInterstitialErrorDomain";

@implementation MaxMRAIDInterstitial

@synthesize isViewable=_isViewable;
@synthesize rootViewController=_rootViewController;

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class MRAIDInterstitial"
                                 userInfo:nil];
    return nil;
}

- (void) dealloc
{
    mraidView = nil;
    supportedFeatures = nil;
}

// designated initializer
- (id)initWithSupportedFeatures:(NSArray *)features
                   withHtmlData:(NSString*)htmlData
                    withBaseURL:(NSURL*)bsURL
                       delegate:(id<MaxMRAIDInterstitialDelegate>)delegate
               serviceDelegate:(id<MaxMRAIDServiceDelegate>)serviceDelegate
             rootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self) {
        supportedFeatures = features;
        _delegate = delegate;
        _serviceDelegate = serviceDelegate;
        _rootViewController = rootViewController;
        
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        mraidView = [[MaxMRAIDView alloc] initWithFrame:screenRect
                                        withHtmlData:htmlData
                                         withBaseURL:bsURL
                                      asInterstitial:YES
                                   supportedFeatures:supportedFeatures
                                            delegate:self
                                    serviceDelegate:self
                                  rootViewController:self.rootViewController];
        _isViewable = NO;
        isReady = NO;
    }
    return self;
}

- (BOOL)isAdReady
{
    return isReady;
}

- (void)show
{
    if (!isReady) {
        NSString *message = @"interstitial is not ready to show";
        [MaxCommonLogger warning:@"MRAID - Interstitial" withMessage:message];
        if ([self.delegate respondsToSelector:@selector(mraidInterstitialAdFailed:error:)]) {
            NSError *error = [self errorWithMessage:message];
            [self.delegate mraidInterstitialAdFailed:self error:error];
        }
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [mraidView performSelector:@selector(showAsInterstitial)];
#pragma clang diagnostic pop
}

-(void)setIsViewable:(BOOL)newIsViewable
{
    [MaxCommonLogger debug:@"MRAID - Interstitial" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    mraidView.isViewable=newIsViewable;
}

-(BOOL)isViewable
{
    [MaxCommonLogger debug:@"MRAID - Interstitial" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    return _isViewable;
}

- (void)setRootViewController:(UIViewController *)newRootViewController
{
    mraidView.rootViewController = newRootViewController;
    [MaxCommonLogger debug:@"MRAID - Interstitial" withMessage:[NSString stringWithFormat:@"setRootViewController: %@", newRootViewController]];
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    mraidView.backgroundColor = backgroundColor;
}

#pragma mark - MRAIDViewDelegate

- (void)mraidViewAdReady:(MaxMRAIDView *)mraidView
{
    NSLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    isReady = YES;
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialAdReady:)]) {
        [self.delegate mraidInterstitialAdReady:self];
    }
}

- (void)mraidViewAdFailed:(MaxMRAIDView *)mraidView error:(NSError *)error
{
    NSLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    isReady = YES;
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialAdFailed:error:)]) {
        [self.delegate mraidInterstitialAdFailed:self error:error];
    }
}

- (void)mraidViewWillExpand:(MaxMRAIDView *)mraidView
{
    NSLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialWillShow:)]) {
        [self.delegate mraidInterstitialWillShow:self];
    }
}

- (void)mraidViewDidClose:(MaxMRAIDView *)mv
{
    NSLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialDidHide:)]) {
        [self.delegate mraidInterstitialDidHide:self];
    }
    mraidView.delegate = nil;
    mraidView.rootViewController = nil;
    mraidView = nil;
    isReady = NO;
}

- (void)mraidViewNavigate:(MaxMRAIDView *)mraidView withURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialNavigate:withURL:)]) {
        [self.delegate mraidInterstitialNavigate:self withURL:url];
    }
}

#pragma mark - MRAIDServiceDelegate callbacks

- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceCreateCalendarEventWithEventJSON:)]) {
        [self.serviceDelegate mraidServiceCreateCalendarEventWithEventJSON:eventJSON];
    }
}

- (void)mraidServicePlayVideoWithUrlString:(NSString *)urlString
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServicePlayVideoWithUrlString:)]) {
        [self.serviceDelegate mraidServicePlayVideoWithUrlString:urlString];
    }
}

- (void)mraidServiceOpenBrowserWithUrlString:(NSString *)urlString
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceOpenBrowserWithUrlString:)]) {
        [self.serviceDelegate mraidServiceOpenBrowserWithUrlString:urlString];
    }
}

- (void)mraidServiceStorePictureWithUrlString:(NSString *)urlString
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceStorePictureWithUrlString:)]) {
        [self.serviceDelegate mraidServiceStorePictureWithUrlString:urlString];
    }
}


#pragma mark - helper (After MRAID refactor we should have a dedicated error class)

- (NSError *)errorWithMessage:(NSString *)message
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: message
                               };
    NSError *error = [NSError errorWithDomain:MaxMRAIDInterstitialErrorDomain
                                         code:0
                                     userInfo:userInfo];
    return error;
}

@end
