//
//  MaxBrowserControlsView.m
//  Nexage
//
//  Created by Tom Poland on 6/23/14.
//  Copyright (c) 2014 Nexage Inc. All rights reserved.
//

#import "MaxBrowserControlsView.h"
#import "MaxBrowser.h"
#import "MaxCommonBackButton.h"
#import "MaxForwardButton.h"

static const float kControlsToobarHeight = 44.0;
static const float kControlsLoadingIndicatorWidthHeight = 30.0;

@interface MaxBrowserControlsView ()
{
    // MaxCommonBackButton is a property
    UIBarButtonItem *flexBack;
    // MaxForwardButton is a property
    UIBarButtonItem *flexForward;
    // loadingIndicator is a property
    UIBarButtonItem *flexLoading;
    UIBarButtonItem *refreshButton;
    UIBarButtonItem *flexRefresh;
    UIBarButtonItem *launchSafariButton;
    UIBarButtonItem *flexLaunch;
    UIBarButtonItem *stopButton;
    __unsafe_unretained MaxBrowser *skBrowser;
}

@end

@implementation MaxBrowserControlsView

- (id)initWithSourceKitBrowser:(MaxBrowser *)p_skBrowser
{
    self = [super initWithFrame:CGRectMake(0, 0, p_skBrowser.view.bounds.size.width, kControlsToobarHeight)];
    
    if (self) {
        _controlsToolbar = [[ UIToolbar alloc] initWithFrame:CGRectMake(0, 0, p_skBrowser.view.bounds.size.width, kControlsToobarHeight)];
        skBrowser = p_skBrowser;
        // In left to right order, to make layout on screen more clear
        NSData* MaxCommonBackButtonData = [NSData dataWithBytesNoCopy:__MaxCommonBackButton_png
                                                      length:__MaxCommonBackButton_png_len
                                                freeWhenDone:NO];
        UIImage *MaxCommonBackButtonImage = [UIImage imageWithData:MaxCommonBackButtonData];
        _MaxCommonBackButton = [[UIBarButtonItem alloc] initWithImage:MaxCommonBackButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
        _MaxCommonBackButton.enabled = NO;
        flexBack = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSData* MaxForwardButtonData = [NSData dataWithBytesNoCopy:__MaxForwardButton_png
                                                         length:__MaxForwardButton_png_len
                                                   freeWhenDone:NO];
        UIImage *MaxForwardButtonImage = [UIImage imageWithData:MaxForwardButtonData];
        _MaxForwardButton = [[UIBarButtonItem alloc] initWithImage:MaxForwardButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(forward:)];
        _MaxForwardButton.enabled = NO;
        flexForward = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIView *placeHolder = [[UIView alloc] initWithFrame:CGRectMake(0,0,kControlsLoadingIndicatorWidthHeight,kControlsLoadingIndicatorWidthHeight)];
        _loadingIndicator = [[UIBarButtonItem alloc] initWithCustomView:placeHolder];  // loadingIndicator will be added here by the browser
        flexLoading = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:(self) action:@selector(refresh:)];
        flexRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        launchSafariButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:(self) action:@selector(launchSafari:)];
        flexLaunch = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        stopButton= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:(self) action:@selector(dismiss:)];
        NSArray *toolbarButtons = @[_MaxCommonBackButton, flexBack, _MaxForwardButton, flexForward, _loadingIndicator, flexLoading, refreshButton, flexRefresh, launchSafariButton, flexLaunch, stopButton];
        [_controlsToolbar setItems:toolbarButtons animated:NO];
        _controlsToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_controlsToolbar];
    }
    return  self;
}

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class SourceKitBrowserControlsView"
                                 userInfo:nil];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-initWithFrame: is not a valid initializer for the class SourceKitBrowserControlsView"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc
{
    flexBack = nil;
    flexForward = nil;
    flexLoading = nil;
    refreshButton = nil;
    flexRefresh = nil;
    flexLaunch = nil;
    launchSafariButton = nil;
    stopButton = nil;
}

#pragma mark -
#pragma mark SourceKitBrowserControlsView actions

- (void)back:(id)sender
{
    [skBrowser back];
}

- (void)dismiss:(id)sender
{
    [skBrowser dismiss];
}

- (void)forward:(id)sender
{
    [skBrowser forward];
}

- (void)launchSafari:(id)sender
{
    [skBrowser launchSafari];
}

- (void)refresh:(id)sender
{
    [skBrowser refresh];
}

@end
