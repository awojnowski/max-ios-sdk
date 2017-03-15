//
//  SKVASTEventProcessor.m
//  VAST
//
//  Created by Thomas Poland on 10/3/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "SKVASTEventProcessor.h"
#import "SKVASTUrlWithId.h"
#import "SKLogger.h"

@interface SKVASTEventProcessor()

@property(nonatomic, strong) NSDictionary *trackingEvents;
@property(nonatomic, strong) SKVASTViewController *vastVC;
@property(nonatomic, strong) id<SKVASTViewControllerDelegate> delegate;

@end


@implementation SKVASTEventProcessor

// designated initializer
- (id)initWithTrackingEvents:(NSDictionary *)trackingEvents withViewController:(SKVASTViewController *)vastVC withDelegate:(id<SKVASTViewControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.trackingEvents = trackingEvents;
        self.vastVC = vastVC;
        self.delegate = delegate;
    }
    return self;
}

- (void)trackEvent:(SKVASTEvent)vastEvent
{
    switch (vastEvent) {
     
        case VASTEventTrackStart:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"start"];
            }

            for (NSURL *aURL in (self.trackingEvents)[@"start"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent track start to url: %@", [aURL absoluteString]]];
            }
         break;
            
        case VASTEventTrackFirstQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"firstQuartile"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"firstQuartile"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent firstQuartile to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackMidpoint:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"midpoint"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"midpoint"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent midpoint to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackThirdQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"thirdQuartile"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"thirdQuartile"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent thirdQuartile to url: %@", [aURL absoluteString]]];
            }
            break;
 
        case VASTEventTrackComplete:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"complete"];
            }
            
            for( NSURL *aURL in (self.trackingEvents)[@"complete"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent complete to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackClose:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"close"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"close"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent close to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackPause:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"pause"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"pause"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent pause start to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackResume:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"resume"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"resume"]) {
                [self sendTrackingRequest:aURL];
                [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent resume start to url: %@", [aURL absoluteString]]];
            }
            break;
            
        default:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"Unknown"];
            }

            break;
    }
}

- (void)sendVASTUrlsWithId:(NSArray *)vastUrls
{
    for (SKVASTUrlWithId *urlWithId in vastUrls) {
        [self sendTrackingRequest:urlWithId.url];
        if (urlWithId.id_) {
            [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent http request %@ to url: %@", urlWithId.id_, urlWithId.url]];
        } else {
            [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent http request to url: %@", urlWithId.url]];
        }
    }
}

- (void)trackError:(SKVASTError)vastError withVASTUrls:(NSArray*)vastUrls {
    int errorCode;
    switch(vastError) {
        case VASTErrorNoCompatibleMediaFile:
            errorCode = 403;
            break;
        case VASTErrorPlaybackError:
            errorCode = 405;
            break;
        case VASTErrorMovieTooShort:
            errorCode = 203;
            break;
        case VASTErrorPlayerHung:
            errorCode = 402;
            break;
        case VASTErrorLoadTimeout:
            errorCode = 301;
            break;
        default:
            errorCode = 900;
    }
    
    for (SKVASTUrlWithId *urlWithId in vastUrls) {
        NSURLComponents* components = [[NSURLComponents alloc] initWithURL:urlWithId.url resolvingAgainstBaseURL:false ];
        components.query = [components.query stringByReplacingOccurrencesOfString:@"[ERRORCODE]" withString:[NSString stringWithFormat:@"%d", errorCode]];
        
        [self sendTrackingRequest:components.URL];
        [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent VAST Error to url: %@", components.URL]];
    }
}

- (void)sendTrackingRequest:(NSURL *)trackingURL
{
    NSMutableString *URLString = [[trackingURL absoluteString] mutableCopy];

    NSTimeInterval timeOffset = self.vastVC.currentPlaybackTime;
    if (timeOffset >= 0) {
        NSDateComponentsFormatter* formatter = [[NSDateComponentsFormatter alloc] init];
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        formatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        
        NSString *timeOffsetString = [formatter stringFromTimeInterval:timeOffset];
        [URLString replaceOccurrencesOfString:@"[CONTENTPLAYHEAD]" withString:timeOffsetString options:0 range:NSMakeRange(0, [URLString length])];
        [URLString replaceOccurrencesOfString:@"%5BCONTENTPLAYHEAD%5D" withString:timeOffsetString options:0 range:NSMakeRange(0, [URLString length])];
    }
    
    NSString *assetURI = [self.vastVC.assetURI absoluteString];
    if (assetURI) {
        [URLString replaceOccurrencesOfString:@"[ASSETURI]" withString:assetURI options:0 range:NSMakeRange(0, [URLString length])];
        [URLString replaceOccurrencesOfString:@"%5BASSETURI%5D" withString:assetURI options:0 range:NSMakeRange(0, [URLString length])];
    }
    
    NSString *cachebuster = [NSString stringWithFormat:@"%u", arc4random() % 90000000 + 10000000];
    [URLString replaceOccurrencesOfString:@"[CACHEBUSTING]" withString:cachebuster options:0 range:NSMakeRange(0, [URLString length])];
    [URLString replaceOccurrencesOfString:@"%5BCACHEBUSTING%5D" withString:cachebuster options:0 range:NSMakeRange(0, [URLString length])];

    NSString *timestamp = [[[NSISO8601DateFormatter alloc] init] stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    [URLString replaceOccurrencesOfString:@"[TIMESTAMP]" withString:timestamp options:0 range:NSMakeRange(0, [URLString length])];
    [URLString replaceOccurrencesOfString:@"%5BTIMESTAMP%5D" withString:timestamp options:0 range:NSMakeRange(0, [URLString length])];
    
    trackingURL = [NSURL URLWithString:URLString];
    
    dispatch_queue_t sendTrackRequestQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(sendTrackRequestQueue, ^{
        NSURLRequest* trackingURLrequest = [ NSURLRequest requestWithURL:trackingURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1.0];
        NSOperationQueue *senderQueue = [[NSOperationQueue alloc] init];
        [SKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Event processor sending request to url: %@", [trackingURL absoluteString]]];
        [NSURLConnection sendAsynchronousRequest:trackingURLrequest
                                           queue:senderQueue
                               completionHandler:^(NSURLResponse *_response, NSData *_data, NSError *_error) {

        }];
    });
}

@end
