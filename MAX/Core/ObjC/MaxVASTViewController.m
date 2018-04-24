//
//  MaxVASTViewController.m
//  VAST
//
//  Created by Thomas Poland on 9/30/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "MaxVASTViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MaxVASTSettings.h"
#import "MaxCommonLogger.h"
#import "MaxVAST2Parser.h"
#import "MaxVASTModel.h"
#import "MaxVASTEventProcessor.h"
#import "MaxVASTUrlWithId.h"
#import "MaxVASTMediaFile.h"
#import "MaxVASTControls.h"
#import "MaxVASTMediaFilePicker.h"
#import "MaxReachability.h"
#import "MaxVASTError.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static const NSString* kPlaybackFinishedUserInfoErrorKey=@"error";

typedef enum {
    VASTFirstQuartile,
    VASTSecondQuartile,
    VASTThirdQuartile,
    VASTFourtQuartile,
} CurrentVASTQuartile;

@interface MaxVASTViewController() <UIGestureRecognizerDelegate>

@property(nonatomic, strong) NSURL *mediaFileURL;
@property(nonatomic, strong) NSArray *clickTracking;
@property(nonatomic, strong) NSArray *vastErrors;
@property(nonatomic, strong) NSArray *impressions;
@property(nonatomic, strong) NSTimer *playbackTimer;
@property(nonatomic, strong) NSTimer *initialDelayTimer;
@property(nonatomic, strong) NSTimer *videoLoadTimeoutTimer;
@property(nonatomic, assign) NSTimeInterval movieDuration;
@property(nonatomic, assign) NSTimeInterval playedSeconds;

@property(nonatomic, strong) MaxVASTControls *controls;

@property(nonatomic, assign) float currentPlayedPercentage;
@property(nonatomic, assign) BOOL isPlaying;
@property(nonatomic, assign) BOOL isViewOnScreen;
@property(nonatomic, assign) BOOL hasPlayerStarted;
@property(nonatomic, assign) BOOL isLoadCalled;
@property(nonatomic, assign) BOOL vastReady;
@property(nonatomic, assign) BOOL statusBarHidden;
@property(nonatomic, assign) CurrentVASTQuartile currentQuartile;

@property(nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property(nonatomic, strong) MaxReachability *reachabilityForVAST;
@property(nonatomic, assign) NetworkReachable networkReachableBlock;
@property(nonatomic, assign) NetworkUnreachable networkUnreachableBlock;

@property(nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property(nonatomic, strong) UITapGestureRecognizer *touchGestureRecognizer;
@property(nonatomic, strong) MaxVASTEventProcessor *eventProcessor;
@property(nonatomic, strong) NSMutableArray *videoHangTest;
@property(nonatomic, assign) BOOL networkCurrentlyReachable;

@end

@implementation MaxVASTViewController

#pragma mark - Init & dealloc

- (id)init
{
    return [self initWithDelegate:nil withViewController:nil];
}

// designated initializer
- (id)initWithDelegate:(id<MaxVASTViewControllerDelegate>)delegate withViewController:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        self.presenterViewController = viewController;
        self.currentQuartile=VASTFirstQuartile;
        self.videoHangTest=[NSMutableArray arrayWithCapacity:20];
        [self setupReachability];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationDidBecomeActive:)
													 name: UIApplicationDidBecomeActiveNotification
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieDuration:)
                                                     name:MPMovieDurationAvailableNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayBackDidFinish:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChangeNotification:)
                                                     name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerLoadStateChanged:)
                                                     name:MPMoviePlayerLoadStateDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieSourceType:)
                                                     name:MPMovieSourceTypeAvailableNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.reachabilityForVAST stopNotifier];
    [self removeObservers];
}

#pragma mark - Load methods

- (void)loadVideoWithURL:(NSURL *)url
{
    [self loadVideoUsingSource:url];
}

- (void)loadVideoWithData:(NSData *)xmlContent
{
    [self loadVideoUsingSource:xmlContent];
}

- (void)loadVideoUsingSource:(id)source
{
    if ([source isKindOfClass:[NSURL class]])
    {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Starting loadVideoWithURL"];
    } else {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Starting loadVideoWithData"];
    }
    
    if (self.isLoadCalled) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Ignoring loadVideo because a load is in progress."];
        return;
    }
    self.isLoadCalled = YES;

    __weak __typeof(self)weakSelf = self;
    void (^parserCompletionBlock)(MaxVASTModel *vastModel, MaxVASTError vastError) = ^(MaxVASTModel *vastModel, MaxVASTError vastError) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"back from block in loadVideoFromData"];
        
        if (!vastModel) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"parser error"];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {  // The VAST document was not readable, so no Error urls exist, thus none are sent.
                [self.delegate vastError:self error:vastError];
            }
            return;
        }
        
        strongSelf.eventProcessor = [[MaxVASTEventProcessor alloc] initWithTrackingEvents:[vastModel trackingEvents] withDelegate:strongSelf.delegate];
        strongSelf.impressions = [vastModel impressions];
        strongSelf.vastErrors = [vastModel errors];
        strongSelf.clickThrough = [[vastModel clickThrough] url];
        strongSelf.clickTracking = [vastModel clickTracking];
        strongSelf.mediaFileURL = [MaxVASTMediaFilePicker pick:[vastModel mediaFiles]].url;
        
        if(!strongSelf.mediaFileURL) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"Error - VASTMediaFilePicker did not find a compatible mediaFile - VASTViewcontroller will not be presented"];
            if ([strongSelf.delegate respondsToSelector:@selector(vastError:error:)]) {
                [strongSelf.delegate vastError:self error:VASTErrorNoCompatibleMediaFile];
            }
            if (strongSelf.vastErrors) {
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [strongSelf.eventProcessor sendVASTUrlsWithId:strongSelf.vastErrors];
            }
            return;
        }
        
        // VAST document parsing OK, player ready to attempt play, so send vastReady
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending vastReady: callback"];
        strongSelf.vastReady = YES;
        [strongSelf.delegate vastReady:self];
    };
    
    MaxVAST2Parser *parser = [[MaxVAST2Parser alloc] init];
    if ([source isKindOfClass:[NSURL class]]) {
        if (!self.networkCurrentlyReachable) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"No network available - VASTViewcontroller will not be presented"]];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoInternetConnection];  // There is network so no requests can be sent, we don't queue errors, so no external Error event is sent.
            }
            return;
        }
        [parser parseWithUrl:(NSURL *)source completion:parserCompletionBlock];     // Load the and parse the VAST document at the supplied URL
    } else {
        [parser parseWithData:(NSData *)source completion:parserCompletionBlock];   // Parse a VAST document in supplied data
    }
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isViewOnScreen=YES;
    if (!self.hasPlayerStarted) {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") ) {
            self.loadingIndicator.frame = CGRectMake( (self.view.frame.size.width/2)-25.0, (self.view.frame.size.height/2)-25.0,50,50);
        }
        else {
            self.loadingIndicator.frame = CGRectMake( (self.view.frame.size.height/2)-25.0, (self.view.frame.size.width/2)-25.0,50,50);
        }
        [self.loadingIndicator startAnimating];
        [self.view addSubview:self.loadingIndicator];
    } else {
        // resuming from background or phone call, so resume if was playing, stay paused if manually paused
        [self handleResumeState];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarHidden withAnimation:UIStatusBarAnimationNone];
    }
}

#pragma mark - App lifecycle

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"applicationDidBecomeActive"];
    [self handleResumeState];
}

#pragma mark - MPMoviePlayerController notifications

- (void)playbackStateChangeNotification:(NSNotification *)notification
{
    @synchronized (self) {
        MPMoviePlaybackState state = [self.moviePlayer playbackState];
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"playback state change to %li", (long)state]];
        
        switch (state) {
            case MPMoviePlaybackStateStopped:  // 0
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video stopped"];
                break;
            case MPMoviePlaybackStatePlaying:  // 1
                self.isPlaying=YES;
                if (self.loadingIndicator) {
                    [self stopVideoLoadTimeoutTimer];
                    [self.loadingIndicator stopAnimating];
                    [self.loadingIndicator removeFromSuperview];
                    self.loadingIndicator = nil;
                }
                if (self.isViewOnScreen) {
                    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video is playing"];
                    [self startPlaybackTimer];
                }
                break;
            case MPMoviePlaybackStatePaused:  // 2
                [self stopPlaybackTimer];
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video paused"];
                self.isPlaying=NO;
                break;
            case MPMoviePlaybackStateInterrupted:  // 3
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video interrupt"];
                break;
            case MPMoviePlaybackStateSeekingForward:  // 4
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video seeking forward"];
                break;
            case MPMoviePlaybackStateSeekingBackward:  // 5
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"video seeking backward"];
                break;
            default:
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"undefined state change"];
                break;
        }
    }
}

- (void)moviePlayerLoadStateChanged:(NSNotification *)notification
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"movie player load state is %li", (long)self.moviePlayer.loadState]];
    
    if ((self.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK) == MPMovieLoadStatePlaythroughOK )
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [self showAndPlayVideo];
    }
}

- (void)moviePlayBackDidFinish:(NSNotification *)notification
{
    @synchronized(self) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"playback did finish"];
        
        NSDictionary* userInfo=[notification userInfo];
        NSString* error= userInfo[kPlaybackFinishedUserInfoErrorKey];
        
        if (error) {
            [self stopVideoLoadTimeoutTimer];  // don't time out if there was a playback error
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"playback error:  %@", error]];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlaybackError];
            }
            if (self.vastErrors) {
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [self.eventProcessor sendVASTUrlsWithId:self.vastErrors];
            }
            [self close];
        } else {
            // no error, clean finish, so send track complete
            [self.eventProcessor trackEvent:VASTEventTrackComplete];
            [self updatePlayedSeconds];
            [self showControls];
            [self.controls toggleToPlayButton:YES];
        }
    }
}

- (void)movieDuration:(NSNotification *)notification
{
    @try {
        self.movieDuration = self.moviePlayer.duration;
    }
    @catch (NSException *e) {
        [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - movieDuration: %@", e]];
        // The movie too short error will fire if movieDuration is < 0.5 or is a NaN value, so no need for further action here.
    }
    
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"playback duration is %f", self.movieDuration]];
    
    if (self.movieDuration < 0.5 || isnan(self.movieDuration)) {
        // movie too short - ignore it
        [self stopVideoLoadTimeoutTimer];  // don't time out in this case
        [MaxCommonLogger warning:@"VAST - View Controller" withMessage:@"Movie too short - will dismiss player"];
        if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
            [self.delegate vastError:self error:VASTErrorMovieTooShort];
        }
        if (self.vastErrors) {
            [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
            [self.eventProcessor sendVASTUrlsWithId:self.vastErrors];
        }
        [self close];
    }
}

- (void)movieSourceType:(NSNotification *)notification
{
    MPMovieSourceType sourceType;
    @try {
        sourceType = self.moviePlayer.movieSourceType;
    }
    @catch (NSException *e) {
        [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - movieSourceType: %@", e]];
        // sourceType is used for info only - any player related error will be handled otherwise, ultimately by videoTimeout, so no other action needed here.
    }
    
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"movie source type is %li", (long)sourceType]];
}

#pragma mark - Orientation handling

// force to always play in Landscape
- (BOOL)shouldAutorotate
{
    NSArray *supportedOrientationsInPlist = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    BOOL isLandscapeLeftSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationLandscapeLeft"];
    BOOL isLandscapeRightSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationLandscapeRight"];
    return isLandscapeLeftSupported && isLandscapeRightSupported;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(currentInterfaceOrientation) ? currentInterfaceOrientation : UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

#pragma mark - Timers

// playbackTimer - keeps track of currentPlayedPercentage
- (void)startPlaybackTimer
{
    @synchronized (self) {
        [self stopPlaybackTimer];
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"start playback timer"];
        self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:kPlayTimeCounterInterval
                                                         target:self
                                                       selector:@selector(updatePlayedSeconds)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)stopPlaybackTimer
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"stop playback timer"];
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
}

- (void)updatePlayedSeconds
{
    @try {
        self.playedSeconds = self.moviePlayer.currentPlaybackTime;
    }
    @catch (NSException *e) {
        [MaxCommonLogger warning:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - updatePlayedSeconds: %@", e]];
        // The hang test below will fire if playedSeconds doesn't update (including a NaN value), so no need for further action here.
    }

    [self.videoHangTest addObject:@((int) (self.playedSeconds * 10.0))];     // add new number to end of hang test buffer
    
    if ([self.videoHangTest count]>20) {  // only check for hang if we have at least 20 elements or about 5 seconds of played video, to prevent false positives
        if ([[self.videoHangTest firstObject] integerValue]==[[self.videoHangTest lastObject] integerValue]) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Video error - video player hung at playedSeconds: %f", self.playedSeconds]];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlayerHung];
            }
            if (self.vastErrors) {
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [self.eventProcessor sendVASTUrlsWithId:self.vastErrors];
            }
            [self close];
        }
        [self.videoHangTest removeObjectAtIndex:0];   // remove oldest number from start of hang test buffer
    }
    
   	self.currentPlayedPercentage = (float)100.0*(self.playedSeconds/self.movieDuration);
    [self.controls updateProgressBar: self.currentPlayedPercentage/100.0 withPlayedSeconds:self.playedSeconds withTotalDuration:self.movieDuration];
    
    switch (self.currentQuartile) {
            
        case VASTFirstQuartile:
            if (self.currentPlayedPercentage>25.0) {
                [self.eventProcessor trackEvent:VASTEventTrackFirstQuartile];
                self.currentQuartile=VASTSecondQuartile;
            }
            break;
            
        case VASTSecondQuartile:
            if (self.currentPlayedPercentage>50.0) {
                [self.eventProcessor trackEvent:VASTEventTrackMidpoint];
                self.currentQuartile=VASTThirdQuartile;
            }
            break;
            
        case VASTThirdQuartile:
            if (self.currentPlayedPercentage>75.0) {
                [self.eventProcessor trackEvent:VASTEventTrackThirdQuartile];
                self.currentQuartile=VASTFourtQuartile;
            }
            break;
            
        default:
            break;
    }
}

// Reports error if vast video document times out while loading
- (void)startVideoLoadTimeoutTimer
{
    [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"Start Video Load Timer"];
    self.videoLoadTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:[MaxVASTSettings vastVideoLoadTimeout]
                                                             target:self
                                                           selector:@selector(videoLoadTimerFired)
                                                           userInfo:nil
                                                            repeats:NO];
}

- (void)stopVideoLoadTimeoutTimer
{
    [self.videoLoadTimeoutTimer invalidate];
    self.videoLoadTimeoutTimer = nil;
    [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"Stop Video Load Timer"];
}

- (void)videoLoadTimerFired
{
    [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"Video Load Timeout"];
    [self close];
    
    if (self.vastErrors) {
       [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
        [self.eventProcessor sendVASTUrlsWithId:self.vastErrors];
    }
    if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
        [self.delegate vastError:self error:VASTErrorLoadTimeout];
    }
}

- (void)killTimers
{
    [self stopPlaybackTimer];
    [self stopVideoLoadTimeoutTimer];
}

#pragma mark - Methods needed to support toolbar buttons

- (void)play
{
    @synchronized (self) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"playVideo"];
        
        if (!self.vastReady) {
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlayerNotReady];                  // This is not a VAST player error, so no external Error event is sent.
                [MaxCommonLogger warning:@"VAST - View Controller" withMessage:@"Ignoring call to playVideo before the player has sent vastReady."];
                return;
            }
        }
        
        if (self.isViewOnScreen) {
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlaybackAlreadyInProgress];       // This is not a VAST player error, so no external Error event is sent.
                [MaxCommonLogger warning:@"VAST - View Controller" withMessage:@"Ignoring call to playVideo while playback is already in progress"];
                return;
            }
        }
        
        if (!self.networkCurrentlyReachable) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:@"No network available - VASTViewcontroller will not be presented"];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorNoInternetConnection];   // There is network so no requests can be sent, we don't queue errors, so no external Error event is sent.
            }
            return;
        }
        
        // Now we are ready to launch the player and start buffering the content
        // It will throw error if the url is invalid for any reason. In this case, we don't even need to open ViewController.
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"initializing player"];
        
        @try {
            self.playedSeconds = 0.0;
            self.currentPlayedPercentage = 0.0;
            
            // Create and prepare the player to confirm the video is playable (or not) as early as possible
            [self startVideoLoadTimeoutTimer];
            self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL: self.mediaFileURL];
            self.moviePlayer.shouldAutoplay = NO; // YES by default - But we don't want to autoplay
            self.moviePlayer.controlStyle=MPMovieControlStyleNone;  // To use custom control toolbar
            [self.moviePlayer prepareToPlay];
            [self presentPlayer];
        }
        @catch (NSException *e) {
            [MaxCommonLogger error:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Exception - moviePlayer.prepareToPlay: %@", e]];
            if ([self.delegate respondsToSelector:@selector(vastError:error:)]) {
                [self.delegate vastError:self error:VASTErrorPlaybackError];
            }
            if (self.vastErrors) {
                [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Error requests"];
                [self.eventProcessor sendVASTUrlsWithId:self.vastErrors];
            }
            return;
        }
    }
}

- (void)pause
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"pause"];
    [self handlePauseState];
}

- (void)resume
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"resume"];
    [self handleResumeState];
}

- (void)info
{
    if (self.clickTracking) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending clickTracking requests"];
        [self.eventProcessor sendVASTUrlsWithId:self.clickTracking];
    }
    if ([self.delegate respondsToSelector:@selector(vastOpenBrowseWithUrl:vastVC:)]) {
        [self.delegate vastOpenBrowseWithUrl:self.clickThrough vastVC:self];
    }
}

- (void)close
{
    @synchronized (self) {
        [self removeObservers];
        [self killTimers];
        [self.moviePlayer stop];
        
        self.moviePlayer=nil;
        
        if (self.isViewOnScreen) {
            // send close any time the player has been dismissed
            [self.eventProcessor trackEvent:VASTEventTrackClose];
            [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Dismissing VASTViewController"];
            [self dismissViewControllerAnimated:NO completion:nil];
            
            if ([self.delegate respondsToSelector:@selector(vastDidDismissFullScreen:)]) {
                [self.delegate vastDidDismissFullScreen:self];
            }
        }
    }
}

//
// Handle touches
//
#pragma mark - Gesture setup & delegate

- (void)setUpTapGestureRecognizer
{
    self.touchGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouches)];
    self.touchGestureRecognizer.delegate = self;
    [self.touchGestureRecognizer setNumberOfTouchesRequired:1];
    self.touchGestureRecognizer.cancelsTouchesInView=NO;  // required to enable controlToolbar buttons to receive touches
    [self.view addGestureRecognizer:self.touchGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)handleTouches{
    if (!self.initialDelayTimer) {
        [self showControls];
    }
}

- (void)showControls
{
    self.initialDelayTimer = nil;
    [self.controls showControls];
}

#pragma mark - Reachability

- (void)setupReachability
{
    self.reachabilityForVAST = [MaxReachability reachabilityForInternetConnection];
    self.reachabilityForVAST.reachableOnWWAN = YES;            // Do allow 3G/WWAN for reachablity
    
    __weak __typeof(self)weakSelf = self;
    self.networkReachableBlock  = ^(MaxReachability*reachabilityForVAST){
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Network reachable"];
        strongSelf.networkCurrentlyReachable = YES;
    };
    
    self.networkUnreachableBlock = ^(MaxReachability*reachabilityForVAST){
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Network not reachable"];
        strongSelf.networkCurrentlyReachable = NO;
    };
    
    self.reachabilityForVAST.reachableBlock = self.networkReachableBlock;
    self.reachabilityForVAST.unreachableBlock = self.networkUnreachableBlock;
    
    [self.reachabilityForVAST startNotifier];
    self.networkCurrentlyReachable = [self.reachabilityForVAST isReachable];
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"Network is reachable %d", self.networkCurrentlyReachable]];
}

#pragma mark - Other methods

- (BOOL)isPlaying
{
    return self.isPlaying;
}

- (void)showAndPlayVideo
{
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"adding player to on screen view and starting play sequence"];
    
    self.moviePlayer.view.frame=self.view.bounds;
    [self.view addSubview:self.moviePlayer.view];
    
    // N.B. The player has to be ready to play before controls may be added to the player's view
    [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"initializing player controls"];
    self.controls = [[MaxVASTControls alloc] initWithVASTPlayer:self];
    [self.moviePlayer.view addSubview: self.controls];
    
    if (kFirstShowControlsDelay > 0) {
        [self.controls hideControls];
        self.initialDelayTimer = [NSTimer scheduledTimerWithTimeInterval:kFirstShowControlsDelay
                                                             target:self
                                                           selector:@selector(showControls)
                                                           userInfo:nil
                                                            repeats:NO];
    } else {
        [self showControls];
    }
    
    [self.moviePlayer play];
    self.hasPlayerStarted=YES;
    
    if (self.impressions) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"Sending Impressions requests"];
        [self.eventProcessor sendVASTUrlsWithId:self.impressions];
    }
    [self.eventProcessor trackEvent:VASTEventTrackStart];
    [self setUpTapGestureRecognizer];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieSourceTypeAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)handlePauseState
{
    @synchronized (self) {
    if (self.isPlaying) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"handle pausing player"];
        [self.moviePlayer pause];
        self.isPlaying = NO;
        [self.eventProcessor trackEvent:VASTEventTrackPause];
    }
    [self stopPlaybackTimer];
    }
}

- (void)handleResumeState
{
    @synchronized (self) {
    if (self.hasPlayerStarted) {
        if (![self.controls controlsPaused]) {
        // resuming from background or phone call, so resume if was playing, stay paused if manually paused by inspecting controls state
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:@"handleResumeState, resuming player"];
        [self.moviePlayer play];
        self.isPlaying = YES;
        [self.eventProcessor trackEvent:VASTEventTrackResume];
        [self startPlaybackTimer];
        }
    } else if (self.moviePlayer) {
        [self showAndPlayVideo];   // Edge case: loadState is playable but not playThroughOK and had resignedActive, so play immediately on resume
    }
    }
}

- (void)presentPlayer
{
    if ([self.delegate respondsToSelector:@selector(vastWillPresentFullScreen:)]) {
        [self.delegate vastWillPresentFullScreen:self];
    }
    
    if (self.presenterViewController == nil) {
        [MaxCommonLogger debug:@"VAST - View Controller" withMessage:[NSString stringWithFormat:@"ERROR: Attempting to present VAST player on %@", self.presenterViewController]];
        return;
    }
    
    if ([self.presenterViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // used if running >= iOS 6
        [self.presenterViewController presentViewController:self animated:NO completion:nil];
    } else {
        // Turn off the warning about using a deprecated method.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.presenterViewController presentModalViewController:self animated:NO];
#pragma clang diagnostic pop
    }
}

@end
