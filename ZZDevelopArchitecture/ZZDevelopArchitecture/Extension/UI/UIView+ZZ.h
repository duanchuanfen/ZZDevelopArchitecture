//
//  UIView+ZZ.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/7/31.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import <UIKit/UIKit.h>

#define UIView_shadeTag 26601
#define UIView_activityIndicatorViewTag 26602

#define UIView_animation_instant 0.15

typedef void(^UIViewCategoryNormalBlock)(UIView *view);
typedef void(^UIViewCategoryAnimationBlock)(void);
@interface UIView (ZZ)

// 增加手势 taget action 形式
- (void)addTapGestureWithTarget:(id)target action:(SEL)action;
// 增加手势 block 形式
- (void)addTapGestureWithBlock:(UIViewCategoryNormalBlock)aBlock;
// 移除手势
- (void)removeTapGesture;
// 增加长按手势 block 形式
- (void)addLongPressGestureWithBlock:(UIViewCategoryNormalBlock)aBlock;
// 移除长按手势
- (void)removeLongPressGesture;

// 增加背景阴影 和点击方法 taget action
- (void)addShadeWithTarget:(id)target action:(SEL)action color:(UIColor *)aColor alpha:(float)aAlpha;
// 增加背景阴影 和点击方法 block
- (void)addShadeWithBlock:(UIViewCategoryNormalBlock)aBlock color:(UIColor *)aColor alpha:(float)aAlpha;
// 增加毛玻璃背景
- (void)addBlurWithTarget:(id)target action:(SEL)action;
- (void)addBlurWithTarget:(id)target action:(SEL)action level:(int)lv;
- (void)addBlurWithBlock:(UIViewCategoryNormalBlock)aBlock;
- (void)addBlurWithBlock:(UIViewCategoryNormalBlock)aBlock level:(int)lv;
// 移除背景阴影View
- (void)removeShade;
// 获取背景阴影View
- (UIView *)shadeView;

// 设置背景
- (instancetype)bg:(NSString *)str;

// 旋转 angle为1.0表示:顺时针旋转180度
- (instancetype)rotate:(CGFloat)angle;
// 把当前View变成圆形
- (instancetype)rounded;
// 把当前View变成圆角矩形, corners:一个矩形的四个角。
- (instancetype)roundedRectWith:(CGFloat)radius;
- (instancetype)roundedRectWith:(CGFloat)radius byRoundingCorners:(UIRectCorner)corners;

// 边框大小,颜色
- (instancetype)borderWidth:(CGFloat)width color:(UIColor *)color;

// 显示活动指示器
- (UIActivityIndicatorView *)activityIndicatorViewShow;
// 移除活动指示器 
- (void)activityIndicatorViewHidden;

// 截屏
- (UIImage *)snapshot;

// 淡出,然后移除
- (void)removeFromSuperviewWithCrossfade;
// 移除所有子视图，但是并没有移除自己
- (void)removeAllSubviews;
// 移除标记为tag的子视图
- (void)removeSubviewWithTag:(NSInteger)tag;
// 移除标记为tag的子视图
- (void)removeSubviewExceptTag:(NSInteger)tag;

// 当前View是否显示在屏幕上
- (BOOL)isDisplayedInScreen;

// 返回所在的ViewController
- (UIViewController *)currentViewController;

#pragma mark -todo attribute
- (void)showDataWithDic:(NSDictionary *)dic;

// 子类需要重新此方法
//+ (void)setupDataBind:(NSMutableDictionary *)dic;

#pragma mark - animation
// 淡入淡出
- (void)animationCrossfadeWithDuration:(NSTimeInterval)duration;
- (void)animationCrossfadeWithDuration:(NSTimeInterval)duration completion:(UIViewCategoryAnimationBlock)completion;

/** 立方体翻转
 *kCATransitionFromRight, kCATransitionFromLeft, kCATransitionFromTop, kCATransitionFromBottom
 */
- (void)animationCubeWithDuration:(NSTimeInterval)duration direction:(NSString *)direction;
- (void)animationCubeWithDuration:(NSTimeInterval)duration direction:(NSString *)direction completion:(UIViewCategoryAnimationBlock)completion;

/** 翻转
 *kCATransitionFromRight, kCATransitionFromLeft, kCATransitionFromTop, kCATransitionFromBottom
 */
- (void)animationOglFlipWithDuration:(NSTimeInterval)duration direction:(NSString *)direction;
- (void)animationOglFlipWithDuration:(NSTimeInterval)duration direction:(NSString *)direction completion:(UIViewCategoryAnimationBlock)completion;

/** 覆盖
 *kCATransitionFromRight, kCATransitionFromLeft, kCATransitionFromTop, kCATransitionFromBottom
 */
- (void)animationMoveInWithDuration:(NSTimeInterval)duration direction:(NSString *)direction;
- (void)animationMoveInWithDuration:(NSTimeInterval)duration direction:(NSString *)direction completion:(UIViewCategoryAnimationBlock)completion;

// 抖动
- (void)animationShake;



@end

