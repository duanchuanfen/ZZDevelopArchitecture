//
//  UIControl+ZZ.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/8/4.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 typedef NS_OPTIONS(NSUInteger, UIControlEvents) {
 UIControlEventTouchDown           = 1 <<  0,      // on all touch downs
 UIControlEventTouchDownRepeat     = 1 <<  1,      // on multiple touchdowns (tap count > 1)
 UIControlEventTouchDragInside     = 1 <<  2,
 UIControlEventTouchDragOutside    = 1 <<  3,
 UIControlEventTouchDragEnter      = 1 <<  4,
 UIControlEventTouchDragExit       = 1 <<  5,
 UIControlEventTouchUpInside       = 1 <<  6,
 UIControlEventTouchUpOutside      = 1 <<  7,
 UIControlEventTouchCancel         = 1 <<  8,
 
 UIControlEventValueChanged        = 1 << 12,     // sliders, etc.
 
 UIControlEventEditingDidBegin     = 1 << 16,     // UITextField
 UIControlEventEditingChanged      = 1 << 17,
 UIControlEventEditingDidEnd       = 1 << 18,
 UIControlEventEditingDidEndOnExit = 1 << 19,     // 'return key' ending editing
 
 UIControlEventAllTouchEvents      = 0x00000FFF,  // for touch events
 UIControlEventAllEditingEvents    = 0x000F0000,  // for UITextField
 UIControlEventApplicationReserved = 0x0F000000,  // range available for application use
 UIControlEventSystemReserved      = 0xF0000000,  // range reserved for internal framework use
 UIControlEventAllEvents           = 0xFFFFFFFF
 };
 */

@interface UIControl (ZZ)

//
- (void)handleControlEvent:(UIControlEvents)event withBlock:(void(^)(id sender))block;
- (void)removeHandlerForEvent:(UIControlEvents)event;

@end
