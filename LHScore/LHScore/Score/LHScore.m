//
//  LHScore.m
//  LHTeachEDU
//
//  Created by LHteach on 16/5/31.
//  Copyright © 2016年 LHteach.com. All rights reserved.
//

#import "LHScore.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#define LHSCORE_MESSAGE_TITLE @"赏一个好评吧"
#define LHSCORE_MESSAGE @"亲, 觉得用起来如何, 给我们评价一下吧!"
#define LHSCORE_CANCEL_BUTTON @"真不错, 朕去打赏一个"
#define LHSCORE_RATE_BUTTON @"退下吧, 朕不想再见你"
#define LHSCORE_RATE_LATER @"朕累了, 以后再说吧"

NSString *const kLHScoreCurrentVersion			= @"kLHScoreCurrentVersion";
NSString *const kLHScoreUseCount				= @"kLHScoreUseCount";
NSString *const kLHScoreRatedCurrentVersion		= @"kLHScoreRatedCurrentVersion";
NSString *const kLHScoreDeclinedToRate			= @"kLHScoreDeclinedToRate";
NSString *const kLHScoreAfterToRate             = @"kLHScoreAfterToRate";
NSString *const kLHScoreReminderRequestDate		= @"kLHScoreReminderRequestDate";

NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";
NSString *templateReviewURLiOS7 = @"itms-apps://itunes.apple.com/app/idAPP_ID";
NSString *templateReviewURLiOS8 = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=APP_ID&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software";

static NSString *_appId;
static NSInteger _usesUntilPrompt = 2;       // 用户使用次数
static NSInteger _countBeforeReminding = 10; // 多少次之后
static BOOL _debug = NO;

@interface LHScore() <UIAlertViewDelegate, SKStoreProductViewControllerDelegate> {
    UIAlertView *ratingAlert;
}

@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic, copy) NSString *alertCancelTitle;
@property (nonatomic, copy) NSString *alertRateTitle;
@property (nonatomic, copy) NSString *alertRateLaterTitle;

@end

@implementation LHScore

@synthesize ratingAlert;

+ (LHScore *)sharedInstance {
    static LHScore *appirater = nil;
    if (appirater == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            appirater = [[LHScore alloc] init];
        });
    }
    
    return appirater;
}

#pragma mark - 类方法
#pragma mark - set
+ (void)setAppId:(NSString *)appId {
    _appId = appId;
}
+ (void)setDebug:(BOOL)debug {
    _debug = debug;
}
+ (void)setUsesUntilPrompt:(NSInteger)value {
    _usesUntilPrompt = value;
}
+ (void)setCountBeforeReminding:(double)value {
    _countBeforeReminding = value;
}

+ (void)appLaunched {
    [LHScore appLaunched:YES];
}

+ (void)appLaunched:(BOOL)canPromptForRating {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        LHScore *a = [LHScore sharedInstance];
        if (_debug) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [a showRatingAlert];
            });
        } else {
            [a incrementAndRate:canPromptForRating];
        }
    });
}

#pragma mark -
#pragma mark - 对象方法
- (void)showRatingAlert {
    [self showRatingAlert:true];
}

- (void)showRatingAlert:(BOOL)displayRateLaterButton {
    UIAlertView *alertView = nil;
    if (displayRateLaterButton) {
        alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle
                                               message:self.alertMessage
                                              delegate:self
                                     cancelButtonTitle:self.alertCancelTitle
                                     otherButtonTitles:self.alertRateLaterTitle, self.alertRateTitle, nil];
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle
                                               message:self.alertMessage
                                              delegate:self
                                     cancelButtonTitle:self.alertCancelTitle
                                     otherButtonTitles:self.alertRateLaterTitle, nil];
    }
    self.ratingAlert = alertView;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    switch (buttonIndex) {
        case 0: {
            BOOL isOpen = NO;
            NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                reviewURL = [templateReviewURLiOS7 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
            } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                reviewURL = [templateReviewURLiOS8 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
            }
            isOpen = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
            if (isOpen) [userDefaults setBool:YES forKey:kLHScoreRatedCurrentVersion];
        } break;
        case 1: {
            [userDefaults setBool:YES forKey:kLHScoreAfterToRate];
        } break;
        case 2: {
            [userDefaults setBool:YES forKey:kLHScoreDeclinedToRate];
        } break;
        default: {
        } break;
    }
}


- (void)incrementAndRate:(BOOL)canPromptForRating {
    [self incrementUseCount];
    
    if (canPromptForRating &&
        [self ratingConditionsHaveBeenMet] &&
        [self ratingAlertIsAppropriate]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showRatingAlert];
        });
    }
}

- (void)incrementUseCount {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:kLHScoreCurrentVersion];
    if (trackingVersion == nil) {
        trackingVersion = version;
        [userDefaults setObject:version forKey:kLHScoreCurrentVersion];
    }
    
    if (_debug) NSLog(@"LHScore Tracking version: %@", trackingVersion);
    
    if ([trackingVersion isEqualToString:version]) {
        NSInteger useCount = [userDefaults integerForKey:kLHScoreUseCount];
        useCount++;
        [userDefaults setInteger:useCount forKey:kLHScoreUseCount];
        if (_debug) NSLog(@"LHScore Use count: %@", @(useCount));
    } else {
        [userDefaults setObject:version forKey:kLHScoreCurrentVersion];
        [userDefaults setInteger:1 forKey:kLHScoreUseCount];
        [userDefaults setBool:NO forKey:kLHScoreRatedCurrentVersion];
        [userDefaults setBool:NO forKey:kLHScoreDeclinedToRate];
        [userDefaults setBool:NO forKey:kLHScoreAfterToRate];
    }
    
    [userDefaults synchronize];
}

- (BOOL)ratingConditionsHaveBeenMet {
    if (_debug) return YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // 使用次数
    NSInteger useCount = [userDefaults integerForKey:kLHScoreUseCount];
    if (useCount < _usesUntilPrompt)
        return NO;
    
    // 二次使用的次数
    if ([userDefaults boolForKey:kLHScoreAfterToRate]) {
        if ((useCount - _usesUntilPrompt) % _countBeforeReminding) return NO;
    }
    
    return YES;
}

- (BOOL)ratingAlertIsAppropriate {
    return ([self connectedToNetwork]
            && ![self userHasDeclinedToRate]
            && !self.ratingAlert.visible
            && ![self userHasRatedCurrentVersion]);
}


/**
 *  能否连接网络
 */
- (BOOL)connectedToNetwork {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
     
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    Boolean didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags) {
        NSLog(@"Error: 无法恢复网络");
        return NO;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
    
    NSURL *testURL = [NSURL URLWithString:@"http://www.baidu.com/"];
    NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
    
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
    
}

- (BOOL)userHasDeclinedToRate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLHScoreDeclinedToRate];
}

- (BOOL)userHasRatedCurrentVersion {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLHScoreRatedCurrentVersion];
}


#pragma mark - get

- (NSString *)alertTitle {
    return _alertTitle ? _alertTitle : LHSCORE_MESSAGE_TITLE;
}

- (NSString *)alertMessage {
    return _alertMessage ? _alertMessage : LHSCORE_MESSAGE;
}

- (NSString *)alertCancelTitle {
    return _alertCancelTitle ? _alertCancelTitle : LHSCORE_CANCEL_BUTTON;
}

- (NSString *)alertRateTitle {
    return _alertRateTitle ? _alertRateTitle : LHSCORE_RATE_BUTTON;
}

- (NSString *)alertRateLaterTitle {
    return _alertRateLaterTitle ? _alertRateLaterTitle : LHSCORE_RATE_LATER;
}


@end
