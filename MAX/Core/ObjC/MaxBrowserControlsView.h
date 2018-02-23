//
//  MaxBrowserControlsView.h
//  Nexage
//
//  Created by Tom Poland on 6/23/14.
//  Copyright (c) 2014 Nexage Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MaxBrowser;
@protocol SourceKitBrowserControlsViewDelegate <NSObject>

@required

- (void)back;
- (void)forward;
- (void)refresh;
- (void)launchSafari;
- (void)dismiss;

@end

@interface MaxBrowserControlsView : UIView

@property (nonatomic, retain) IBOutlet UIBarButtonItem *MaxCommonBackButton;
@property (nonatomic, retain) IBOutlet UIToolbar *controlsToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *MaxForwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *loadingIndicator;

- (id)initWithSourceKitBrowser:(MaxBrowser *)p_skBrowser;

@end
