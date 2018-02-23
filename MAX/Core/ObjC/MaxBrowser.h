//
//  MaxBrowser.h
//  Nexage
//
//  Created by Thomas Poland on 6/20/14.
//  Copyright (c) 2014 Nexage Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MaxBrowserControlsView.h"

extern NSString * const kSourceKitBrowserFeatureSupportInlineMediaPlayback;
extern NSString * const kSourceKitBrowserFeatureDisableStatusBar;
extern NSString * const kSourceKitBrowserFeatureScalePagesToFit;

@class MaxBrowser;

@protocol MaxBrowserDelegate <NSObject>

@required

- (void)sourceKitBrowserClosed:(MaxBrowser *)sourceKitBrowser;  // sent when the SourceKitBrowser viewController has dismissed - required
- (void)sourceKitBrowserWillExitApp:(MaxBrowser *)sourceKitBrowser;  // sent when the SourceKitBrowser exits by opening the system openURL command

@optional

- (void)sourceKitTelPopupOpen:(MaxBrowser *)sourceKitBrowser; // sent when the telephone dial confirmation popup is on the screen
- (void)sourceKitTelPopupClosed:(MaxBrowser *)sourceKitBrowser; // sent when the telephone dial confirmation popip is dismissed

@end

@interface MaxBrowser : UIViewController <SourceKitBrowserControlsViewDelegate>

@property (nonatomic, unsafe_unretained) id<MaxBrowserDelegate>delegate;

- (id)initWithDelegate:(id<MaxBrowserDelegate>)delegate withFeatures:(NSArray *)sourceKitBrowserFeatures;  // designated initializer for SourceKitBrowser

- (void)loadRequest:(NSURLRequest *)urlRequest;   // load urlRequest and present the souceKitBrowserViewController Note: requests such as tel: will immediately be presented using the UIApplication openURL: method without presenting the SourceKitBrowser's viewController

@end
