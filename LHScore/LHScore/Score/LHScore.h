//
//  LHScoreScore.h
//  LHScoreTeachEDU
//
//  Created by LHScoreteach on 16/5/31.
//  Copyright © 2016年 LHScoreteach.com. All rights reserved.
//

#import <StoreKit/StoreKit.h>


@interface LHScore : NSObject 

@property(nonatomic, strong) UIAlertView *ratingAlert;

+ (void)appLaunched;
+ (void)appLaunched:(BOOL)canPromptForRating;

+ (void)setAppId:(NSString *)appId;
+ (void)setDebug:(BOOL)debug;
+ (void)setUsesUntilPrompt:(NSInteger)value;
+ (void)setCountBeforeReminding:(double)value;


- (void)showRatingAlert:(BOOL)displayRateLaterButton;
@end
