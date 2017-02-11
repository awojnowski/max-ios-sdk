//
//  SKBrowserControlsView.m
//  Nexage
//
//  Created by Tom Poland on 6/23/14.
//  Copyright (c) 2014 Nexage Inc. All rights reserved.
//

#import "SKBrowserControlsView.h"
#import "SKBrowser.h"

unsigned char __BackButton_png[] = {
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x1e,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x3b, 0x30, 0xae, 0xa2, 0x00, 0x00, 0x01,
    0x3a, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0x60, 0x18, 0x05, 0xa3,
    0x60, 0x28, 0x82, 0xff, 0xff, 0xff, 0x33, 0xd2, 0xd5, 0xc2, 0xb4, 0xff,
    0xff, 0xb9, 0xfc, 0xe6, 0xff, 0x6f, 0xf0, 0x68, 0xbb, 0xf9, 0x7f, 0xf3,
    0x9b, 0x0b, 0xd2, 0x34, 0xb7, 0x30, 0xee, 0xcd, 0x7f, 0x69, 0xaf, 0x49,
    0xbf, 0x36, 0x83, 0x2c, 0x84, 0xe1, 0xe5, 0xf7, 0xef, 0x2b, 0xd0, 0xcc,
    0xc2, 0xc8, 0xfd, 0xff, 0x6d, 0x5c, 0x3b, 0x1e, 0xbc, 0x47, 0xb6, 0x10,
    0x82, 0xaf, 0xfe, 0xbf, 0xf4, 0xff, 0x92, 0x20, 0x55, 0x2d, 0xab, 0xff,
    0xff, 0x9f, 0xc5, 0x7f, 0xd9, 0xff, 0x2c, 0x77, 0x0c, 0xcb, 0x6e, 0xfe,
    0xf7, 0xe9, 0xba, 0x72, 0xbf, 0xfa, 0xe4, 0x7f, 0x13, 0xaa, 0x5a, 0x98,
    0xf9, 0xff, 0xbf, 0xa0, 0xf7, 0xf4, 0xff, 0x33, 0x3d, 0xb0, 0x58, 0x18,
    0x32, 0xf5, 0xee, 0xb2, 0x55, 0xff, 0xff, 0x8b, 0x52, 0xd5, 0xc2, 0xd0,
    0x33, 0xff, 0x75, 0xdd, 0x7b, 0xdf, 0x5c, 0xc0, 0x16, 0x9c, 0x49, 0xcb,
    0x3e, 0x67, 0x01, 0x53, 0x30, 0x0b, 0x35, 0xf3, 0x03, 0x63, 0xd8, 0xe6,
    0xff, 0xbe, 0x2e, 0xf4, 0x0a, 0x4e, 0x10, 0x70, 0x03, 0xc6, 0x1f, 0xb2,
    0xaf, 0x68, 0x1a, 0x9c, 0xc8, 0xc0, 0xae, 0xeb, 0xc5, 0x7d, 0x64, 0x1f,
    0x7a, 0x77, 0xec, 0x7d, 0xff, 0xff, 0x3f, 0x03, 0x13, 0xcd, 0xf3, 0xa4,
    0x0d, 0x9a, 0xc5, 0x20, 0xec, 0xd7, 0x7b, 0xfd, 0x02, 0x4d, 0x82, 0x97,
    0x94, 0xfc, 0x49, 0xfd, 0x04, 0x85, 0xa3, 0x44, 0xf2, 0x9c, 0xf4, 0x6d,
    0x33, 0xf6, 0x2c, 0xf4, 0x68, 0xd9, 0x74, 0xa0, 0x3c, 0x4d, 0x1d, 0x90,
    0xfb, 0xff, 0x3f, 0x3b, 0xae, 0x42, 0xc3, 0xbb, 0xe3, 0xe2, 0xfb, 0x82,
    0xdd, 0xff, 0x5d, 0x80, 0xe9, 0x80, 0x91, 0xe6, 0xd1, 0xe0, 0x8e, 0x25,
    0x1d, 0x80, 0x70, 0xcc, 0xfc, 0x97, 0x0d, 0x67, 0x80, 0x15, 0x05, 0xad,
    0x43, 0x41, 0xd4, 0x7b, 0xea, 0xff, 0x65, 0xd8, 0x1c, 0x10, 0x34, 0xe1,
    0xfa, 0xc1, 0xff, 0xff, 0x6f, 0xb3, 0xd3, 0xd4, 0x01, 0xb8, 0xca, 0xee,
    0x59, 0xd7, 0x4f, 0xaa, 0xd1, 0xad, 0x3e, 0x46, 0x8e, 0x06, 0xba, 0x5a,
    0x8c, 0x9c, 0x1b, 0x6e, 0x03, 0x13, 0xe4, 0x68, 0x5b, 0x6c, 0x14, 0x8c,
    0x0c, 0x00, 0x00, 0x9e, 0x76, 0x5b, 0x88, 0x98, 0x6d, 0x8e, 0xfe, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int __BackButton_png_len = 371;

unsigned char __ForwardButton_png[] = {
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x1e,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x3b, 0x30, 0xae, 0xa2, 0x00, 0x00, 0x01,
    0x50, 0x49, 0x44, 0x41, 0x54, 0x78, 0xda, 0x63, 0x60, 0x18, 0x05, 0xa3,
    0x80, 0xee, 0xe0, 0xff, 0x7f, 0xc6, 0x01, 0xb1, 0xd7, 0xae, 0xf7, 0xc3,
    0x05, 0x9f, 0xae, 0x2b, 0xf7, 0xab, 0x4f, 0xfe, 0x37, 0xa1, 0xab, 0xc5,
    0x0e, 0x40, 0x8b, 0x3d, 0xda, 0x6e, 0xfe, 0x87, 0xe0, 0x4b, 0xff, 0x33,
    0xd6, 0xff, 0x09, 0xfb, 0xff, 0xff, 0x3f, 0x13, 0xed, 0x2d, 0x9e, 0xfa,
    0x7f, 0x19, 0xc2, 0x62, 0x04, 0x8e, 0x9e, 0xfb, 0xb4, 0xe7, 0xc8, 0xff,
    0xff, 0xbc, 0x34, 0xb5, 0xbc, 0x0c, 0x68, 0x81, 0xcf, 0xdc, 0xff, 0x3d,
    0xd8, 0x1c, 0x10, 0x34, 0xe1, 0xf6, 0xc1, 0xb6, 0xeb, 0xff, 0xd5, 0x68,
    0xea, 0x80, 0x7a, 0x60, 0x10, 0x07, 0xaf, 0xff, 0x1f, 0xe6, 0x86, 0xc5,
    0x01, 0xde, 0x1d, 0x57, 0xdf, 0x67, 0x6d, 0xfe, 0xea, 0xfb, 0xff, 0x3f,
    0x03, 0x6d, 0x13, 0x63, 0xf4, 0x99, 0xff, 0xba, 0xee, 0xbd, 0x6f, 0x2e,
    0x60, 0x0b, 0x85, 0x84, 0xc5, 0x6f, 0x4b, 0x6f, 0xff, 0xff, 0xcf, 0x4e,
    0x53, 0x07, 0x64, 0xfe, 0xff, 0x2f, 0xe8, 0x3d, 0xfd, 0xff, 0x4c, 0xac,
    0xd1, 0x30, 0xe9, 0xd6, 0xe6, 0xe9, 0x6f, 0xfe, 0x4b, 0xd3, 0x3a, 0x1a,
    0x58, 0x82, 0x56, 0xfd, 0x4f, 0x70, 0x83, 0x07, 0xfd, 0xdd, 0xf7, 0x88,
    0x68, 0x38, 0xfb, 0xfe, 0xc6, 0xff, 0xd7, 0xbc, 0x34, 0xcf, 0x09, 0x81,
    0xfb, 0xff, 0xdb, 0xa0, 0xfb, 0x7e, 0xd6, 0xf5, 0x93, 0xb4, 0x4b, 0x80,
    0x69, 0xff, 0xff, 0x73, 0xf9, 0x2d, 0xfe, 0x5f, 0xea, 0xde, 0xf1, 0xe0,
    0x3d, 0xba, 0xc5, 0x9b, 0xdf, 0x5c, 0xa0, 0x7e, 0x90, 0x27, 0xdc, 0xff,
    0xaf, 0xe0, 0x3e, 0xe1, 0xd3, 0x41, 0xcc, 0x78, 0xbe, 0x4a, 0xfd, 0x84,
    0x06, 0xca, 0x5a, 0x61, 0x9b, 0xff, 0xfb, 0xba, 0x60, 0xcd, 0x5a, 0x17,
    0xdf, 0x17, 0xec, 0xfe, 0xef, 0x42, 0xc7, 0x54, 0x7c, 0x9f, 0xfa, 0xa9,
    0x38, 0x02, 0x58, 0x49, 0xb8, 0xa3, 0x94, 0xdb, 0x08, 0x1c, 0x33, 0xff,
    0x65, 0xc3, 0x19, 0x60, 0xfc, 0x52, 0xd5, 0x42, 0x2f, 0x60, 0x49, 0xe5,
    0x8e, 0x23, 0x38, 0x69, 0x5a, 0x52, 0xd9, 0x75, 0xbd, 0xb8, 0x8f, 0x6c,
    0x61, 0xe0, 0x84, 0xeb, 0x07, 0xfb, 0x81, 0x89, 0x89, 0xe6, 0x79, 0xd2,
    0x16, 0x9a, 0x35, 0xe2, 0x68, 0x11, 0x9c, 0xf8, 0x40, 0x2a, 0xb0, 0xe6,
    0x01, 0x06, 0x27, 0x13, 0xc3, 0x28, 0x18, 0x05, 0xa3, 0x80, 0x48, 0x00,
    0x00, 0x89, 0xe9, 0x5a, 0x7c, 0x70, 0xc3, 0x49, 0x39, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
};
unsigned int __ForwardButton_png_len = 393;


static const float kControlsToobarHeight = 44.0;
static const float kControlsLoadingIndicatorWidthHeight = 30.0;

@interface SKBrowserControlsView ()
{
    // backButton is a property
    UIBarButtonItem *flexBack;
    // forwardButton is a property
    UIBarButtonItem *flexForward;
    // loadingIndicator is a property
    UIBarButtonItem *flexLoading;
    UIBarButtonItem *refreshButton;
    UIBarButtonItem *flexRefresh;
    UIBarButtonItem *launchSafariButton;
    UIBarButtonItem *flexLaunch;
    UIBarButtonItem *stopButton;
    __unsafe_unretained SKBrowser *skBrowser;
}

@end

@implementation SKBrowserControlsView

- (id)initWithSourceKitBrowser:(SKBrowser *)p_skBrowser
{
    self = [super initWithFrame:CGRectMake(0, 0, p_skBrowser.view.bounds.size.width, kControlsToobarHeight)];
    
    if (self) {
        _controlsToolbar = [[ UIToolbar alloc] initWithFrame:CGRectMake(0, 0, p_skBrowser.view.bounds.size.width, kControlsToobarHeight)];
        skBrowser = p_skBrowser;
        // In left to right order, to make layout on screen more clear
        NSData* backButtonData = [NSData dataWithBytesNoCopy:__BackButton_png
                                                      length:__BackButton_png_len
                                                freeWhenDone:NO];
        UIImage *backButtonImage = [UIImage imageWithData:backButtonData];
        _backButton = [[UIBarButtonItem alloc] initWithImage:backButtonImage style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];
        _backButton.enabled = NO;
        flexBack = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSData* forwardButtonData = [NSData dataWithBytesNoCopy:__ForwardButton_png
                                                         length:__ForwardButton_png_len
                                                   freeWhenDone:NO];
        UIImage *forwardButtonImage = [UIImage imageWithData:forwardButtonData];
        _forwardButton = [[UIBarButtonItem alloc] initWithImage:forwardButtonImage style:UIBarButtonItemStyleBordered target:self action:@selector(forward:)];
        _forwardButton.enabled = NO;
        flexForward = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIView *placeHolder = [[UIView alloc] initWithFrame:CGRectMake(0,0,kControlsLoadingIndicatorWidthHeight,kControlsLoadingIndicatorWidthHeight)];
        _loadingIndicator = [[UIBarButtonItem alloc] initWithCustomView:placeHolder];  // loadingIndicator will be added here by the browser
        flexLoading = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:(self) action:@selector(refresh:)];
        flexRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        launchSafariButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:(self) action:@selector(launchSafari:)];
        flexLaunch = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        stopButton= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:(self) action:@selector(dismiss:)];
        NSArray *toolbarButtons = @[_backButton, flexBack, _forwardButton, flexForward, _loadingIndicator, flexLoading, refreshButton, flexRefresh, launchSafariButton, flexLaunch, stopButton];
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