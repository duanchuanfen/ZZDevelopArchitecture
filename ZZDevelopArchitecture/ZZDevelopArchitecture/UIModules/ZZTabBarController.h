//
//  ZZTabBarController.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/8/7.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//
#pragma mark -todo 待优化
#import "ZZTabBar.h"

#pragma mark-
#pragma mark- ZZTabBarController

@protocol ZZTabBarControllerDelegate;

@interface ZZTabBarController : UIViewController<ZZTabBarDelegate>

#pragma mark- model
// 定义model
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, weak, readonly) UIViewController *selectedViewController;
@property (nonatomic, strong, readonly) NSArray *viewControllers;

@property (nonatomic, assign) CGRect tabBarFrame;   // the default height is 49 at bottom.
@property (nonatomic, assign) CGRect contentFrame;  // the default frame is self.view.bounds without tabBarFrame


#pragma mark- view
// 定义view
@property (nonatomic, strong, readonly) ZZTabBar *tabBar;
@property (nonatomic, strong, readonly) UIView *contentView; // 子视图控制器显示的view

@property (nonatomic, weak) id<ZZTabBarControllerDelegate> delegate;


// item: @{@"normal" :img1, @"highlighted" :img2, @"selected" :img3, @"disabled":img4, @"text": text}
- (id)initWithViewControllers:(NSArray *)vcs items:(NSArray *)items;

// 可以重载这个方法, 自定义item的位置和图片文字尺寸
- (void)setupItem:(UIButton *)item index:(NSInteger)index;
// 重载这个方式, 自定义animatedView的位置
- (void)resetAnimatedView:(UIImageView *)animatedView index:(NSInteger)index;
// 重载这个方法设置TabBar透明前和透明后的content尺寸
//- (void)setTabBarTransparent:(BOOL)b;

@end

#pragma mark-
#pragma mark- ZZTabBarControllerProtocol
@protocol ZZTabBarControllerProtocol <NSObject>
@optional
- (BOOL)tabBarController:(ZZTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
- (void)tabBarController:(ZZTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;
@end

#pragma mark-
#pragma mark- ZZTabBarController()
@interface UIViewController (ZZTabBarController)
@property(nonatomic, weak, readonly) ZZTabBarController *ZZTabBarController;
@end

