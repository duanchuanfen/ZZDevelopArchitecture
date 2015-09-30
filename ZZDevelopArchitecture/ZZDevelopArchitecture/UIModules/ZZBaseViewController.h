//
//  ZZBaseViewController.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/8/7.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import "ZZDevelopPreDefine.h"

#pragma mark -  生命周期
/**
 生命周期
 loadView
 1. createFields
 2. createViews
 3. createEvents
 
 viewDidLoad
 1. loadData
 
 dealloc
 1. destroyEvents
 2. destroyViews
 3. destroyFields
 
 didReceiveMemoryWarning
 1. cleanData
 
 
 规则
 1) 在createFields方法中接收从上一个页面传递过来的参数
 2) 在createFields方法中初始化变量
 3) 将要操作的控件, 都在ViewController中作为类级别的变量来声明
 3) 在createViews方法中, 加载xib文件，并通过Tag给控件一次性赋值
 4) 在createEvent方法中, 为控件挂上事件方法，比如按钮的点击
 5) 如果有NotificationCenter, 统一在createEvent方法中addObserver,在destroyEvent方法中removeObserver
 6) 在destroyFields方法中, 释放/销毁所有引用型变量。
 7) 在destroyViews方法中, 释放/销毁所有控件。
 8) 在cleanData方法中释放一些可以释放的数据
 **
 */

#pragma mark -
// 创建/销毁页面级变量, model的地方。
//- (void)createFields;
//- (void)destroyFields;
//
// 创建/销毁页面内控件的地方。
//- (void)createViews;
//- (void)destroyViews;
//
// 创建/销毁页面内控件事件的地方。
//- (void)createEvents;
//- (void)destroyEvents;
//
// 如果页面加载过程需要读取数据, 则写在这个地方。
//- (void)loadData;

#pragma mark -
// 以下方法的消息已经注册过,需要实现的时候,请直接写
// 进入后台时
//- (void)enterBackground;
// 进入前台时
//- (void)enterForeground;
// 已经加载,不在window上的vc,收到内存警告
//- (void)cleanData;

#pragma mark -
typedef UIViewController ZZBaseViewController;

@interface UIViewController (ZZBase)
#pragma mark- as

#pragma mark- model

#pragma mark- view

#pragma mark- api

@end