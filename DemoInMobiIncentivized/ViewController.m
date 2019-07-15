//
//  ViewController.m
//  DemoInMobiIncentivized
//
//  Created by KhiemND on 7/10/19.
//  Copyright © 2019 ZAD. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVPlayerLayer.h>
#import "Masonry.h"

@import InMobiSDK;

#ifndef INMOBI_INTERSTITIAL_PLACEMENT
//#define INMOBI_INTERSTITIAL_PLACEMENT   1503220506087
#define INMOBI_INTERSTITIAL_PLACEMENT   1508518236714
#endif

#ifndef INMOBI_INSTREAM_VIEW_TAG
#define INMOBI_INSTREAM_VIEW_TAG   99999
#endif

typedef enum : NSUInteger {
    INITTED,
    LOADING,
    LOADED,
    SHOWN,
    DISMISSED,
    ERROR
} StatusAd;

@interface TestView : UIView
@property (nonatomic, strong) CALayer *layerPlayer;
@end

@implementation TestView

- (void)layoutSublayersOfLayer:(CALayer *)layer{
    [super layoutSublayersOfLayer:layer];
    @try {
        if (_layerPlayer) {
            _layerPlayer.frame = self.bounds;
        }
    } @catch (NSException *exception) {
        
    }
}

@end

@interface ViewController ()
<IMNativeDelegate>
{
    StatusAd statusAd;
    CGFloat widthVideo;
    
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
}
@property (nonatomic, strong) IMNative *inMobiNativeAd;
@property (nonatomic, weak) IBOutlet UILabel *lbStatus;
@property (nonatomic, weak) IBOutlet UIButton *btnDismiss;
@property (nonatomic) CGFloat heightVideo;

@property (nonatomic, strong) TestView *viewPlayer;
@property (nonatomic, strong) AVPlayer *moviePlayer;

@end

@implementation ViewController
@synthesize heightVideo;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    widthVideo = window.bounds.size.width;
    heightVideo = window.bounds.size.width *9/16;
    if (self.viewPlayer) {
        if (self.moviePlayer) {
            
        }
    }
    
    [self checkOrInitAd];
}

- (TestView *)viewPlayer{
    if (!_viewPlayer) {
        _viewPlayer = [[TestView alloc] init];
        _viewPlayer.backgroundColor = [UIColor blackColor];
        [self.view addSubview:_viewPlayer];
        [_viewPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.btnDismiss.mas_bottom).offset(10);
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.height.equalTo(@(self.heightVideo));
            //            make.top.left.right.and.bottom.equalTo(self.view);
        }];
    }
    return _viewPlayer;
}

- (AVPlayer *)moviePlayer{
    if (!_moviePlayer) {
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"big_buck_bunny.mp4" ofType:nil]];
        AVAsset *assets = [AVURLAsset URLAssetWithURL:url options:nil];
        playerItem = [AVPlayerItem playerItemWithAsset:assets];
        
        _moviePlayer = [AVPlayer playerWithPlayerItem:playerItem];
        
        playerLayer = [AVPlayerLayer playerLayerWithPlayer:_moviePlayer];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.viewPlayer.layer addSublayer:playerLayer];
        self.viewPlayer.layerPlayer = playerLayer;
        playerLayer.needsDisplayOnBoundsChange = YES;
    }
    return _moviePlayer;
}

- (void)playVideo{
    [self.moviePlayer play];
}

- (void)pauseVideo{
    [self.moviePlayer pause];
}

- (void)resumeVideo{
    [self.moviePlayer play];
}

- (void)checkOrInitAd{
    if (!self.inMobiNativeAd) {
        self. inMobiNativeAd = [[IMNative alloc] initWithPlacementId:INMOBI_INTERSTITIAL_PLACEMENT];
        self. inMobiNativeAd.delegate = self;
        [self updateStatus:INITTED];
    }
}

-(void)showAd{
    UIView* AdPrimaryViewOfCorrectWidth = [self.inMobiNativeAd primaryViewOfWidth:widthVideo];
    AdPrimaryViewOfCorrectWidth.tag = INMOBI_INSTREAM_VIEW_TAG;
    [self.viewPlayer addSubview:AdPrimaryViewOfCorrectWidth];
    [AdPrimaryViewOfCorrectWidth mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.equalTo(self.viewPlayer);
    }];
}

- (void)dismissAd{
    UIView *inMobiView = [self.viewPlayer viewWithTag:INMOBI_INSTREAM_VIEW_TAG];
    if (inMobiView) {
        [inMobiView removeFromSuperview];
        [self.inMobiNativeAd recyclePrimaryView];
        self.inMobiNativeAd = nil;
    }
}

- (void)updateStatus:(StatusAd)status{
    [self updateStatus:status error:@""];
}

- (void)updateStatus:(StatusAd)status error:(NSString *)errMessage{
    NSString *strMessage = @"STATUS";
    
    switch (status) {
        case INITTED:
            strMessage = @"INITTED";
            break;
        case LOADING:
            strMessage = @"LOADING";
            break;
        case LOADED:
            strMessage = @"LOADED";
            break;
        case SHOWN:
            strMessage = @"SHOWN";
            break;
        case DISMISSED:
            strMessage = @"DISMISSED";
            break;
        case ERROR:
            strMessage = [NSString stringWithFormat:@"ERROR: %@", errMessage];
            break;
        default:
            break;
    }
    self.lbStatus.text = strMessage;
}

- (IBAction)onLoadAd:(id)sender{
    [self checkOrInitAd];
    [self.inMobiNativeAd load];
    [self updateStatus:LOADING];
}

- (IBAction)onShowAd:(id)sender{
//    if ([self.interstitial isReady]) {
//        [self.interstitial showFromViewController:self];
//        [self updateStatus:SHOWN];
//    }
    if (!self.inMobiNativeAd) {
        
    } else {
        //can show ad preroll
        if ([self.inMobiNativeAd isReady]) {
            [self showAd];
        }
        //case ad load fail, just show media content
        else {
            [self playVideo];
        }
        [self updateStatus:SHOWN];
    }
}

- (IBAction)onDismissAd:(id)sender{
//    self.interstitial = nil;
//    self.interstitial = NULL;
    [self dismissAd];
    [self pauseVideo];
    [self.moviePlayer seekToTime:kCMTimeZero];
    [self updateStatus:DISMISSED];
}

#pragma mark - Orientation handling
- (void)videoMinimize:(NSTimeInterval)duration{
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            //Update UI
            if (self.viewPlayer.superview &&
                self.viewPlayer.superview != self.view) {
                [self.viewPlayer removeFromSuperview];
                [self.view addSubview:self.viewPlayer];
                [self.viewPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(self.btnDismiss.mas_bottom).offset(10);
                    make.left.equalTo(self.view);
                    make.right.equalTo(self.view);
                    make.height.equalTo(@(self.heightVideo));
                    //            make.top.left.right.and.bottom.equalTo(self.view);
                }];
                [self.viewPlayer layoutIfNeeded]; // Ensures that all pending layout operations have been completed
                [UIView animateWithDuration:duration animations:^{
                    // Make all constraint changes here
                    [self.viewPlayer layoutIfNeeded]; // Forces the layout of the subtree animation block and then captures all of the frame changes
                }];
            }
        });
    } @catch (NSException *exception) {
        
    }
}

- (void)videoFullscreen:(NSTimeInterval)duration{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Update UI
        UIWindow *window = [[UIApplication sharedApplication].delegate window];
        if (window &&
            self.viewPlayer.superview &&
            self.viewPlayer.superview != window) {
            [self.viewPlayer removeFromSuperview];
            [window addSubview:self.viewPlayer];
            [self.viewPlayer mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.and.bottom.equalTo(window);
            }];
            
            [self.viewPlayer layoutIfNeeded]; // Ensures that all pending layout operations have been completed
            [UIView animateWithDuration:duration animations:^{
                // Make all constraint changes here
                [self.viewPlayer layoutIfNeeded]; // Forces the layout of the subtree animation block and then captures all of the frame changes
            }];
        }
    });
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            NSLog(@"device portrait");
            [self videoMinimize:duration];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"device landscape");
            [self videoFullscreen:duration];
            break;
        default:
            break;
    }
}

#pragma mark - Inmobi Delegates
#pragma mark - native ad call back

/*The native ad notifies its delegate that it is ready. Fetching publisher-specific ad asset content from native.adContent. The publisher will specify the format. If the publisher does not provide a format, no ad will be loaded.*/
-(void)nativeDidFinishLoading:(IMNative*)native{
    [self updateStatus:LOADED];
}
/*The native ad notifies its delegate that an error has been encountered while trying to load the ad.Check IMRequestStatus.h for all possible errors.Try loading the ad again, later.*/
-(void)native:(IMNative*)native didFailToLoadWithError:(IMRequestStatus*)error{
    [self updateStatus:ERROR
                 error:[NSString stringWithFormat:@"my dictionary is %@", error.userInfo]];
}
/* Indicates that the native ad is going to present a screen. */ -(void)nativeWillPresentScreen:(IMNative*)native{
    NSLog(@"Native Ad will present screen");
}
/* Indicates that the native ad has presented a screen. */
-(void)nativeDidPresentScreen:(IMNative*)native{
    NSLog(@"Native Ad did present screen");
}
/* Indicates that the native ad is going to dismiss the presented screen. */
-(void)nativeWillDismissScreen:(IMNative*)native{
    NSLog(@"Native Ad will dismiss screen");
}
/* Indicates that the native ad has dismissed the presented screen. */
-(void)nativeDidDismissScreen:(IMNative*)native{
    NSLog(@"Native Ad did dismiss screen");
}
/* Indicates that the user will leave the app. */
-(void)userWillLeaveApplicationFromNative:(IMNative*)native{
    NSLog(@"User leave");
}

-(void)native:(IMNative *)native didInteractWithParams:(NSDictionary *)params{
    NSLog(@"User leave");
}

-(void)nativeAdImpressed:(IMNative *)native{
    NSLog(@"User leave");
}

-(void)native:(IMNative *)native rewardActionCompletedWithRewards:(NSDictionary *)rewards{
    NSLog(@"User leave");
}

-(void)nativeDidFinishPlayingMedia:(IMNative *)native{
    //should dismiss ad
    [self dismissAd];
    [self playVideo];
}
@end
