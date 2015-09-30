//
//  UIColor+ZZ.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/7/31.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import <UIKit/UIKit.h>

/**************************************************************/
//  RGB颜色
#define ZZ_UIColorFromRGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define ZZ_UIColorFromHEXWithAlpha(__hex, __alpha) [UIColor colorFromHex:__hex alpha:__alpha]

@interface UIColor (ZZ)

// 根据自己的颜色,返回黑色或者白色
- (instancetype)blackOrWhiteContrastingColor;

// 返回一个十六进制表示的颜色: @"FF0000" or @"#FF0000"
+ (instancetype)colorFromHexString:(NSString *)hexString;

// 返回一个十六进制表示的颜色: 0xFF0000
+ (instancetype)colorFromHex:(NSInteger)hex alpha:(CGFloat)alpha;

// 返回颜色的十六进制string
- (NSString *)hexString;

/**
 Creates an array of 4 NSNumbers representing the float values of r, g, b, a in that order.
 @return    NSArray
 */
- (NSArray *)rgbaArray;

@end