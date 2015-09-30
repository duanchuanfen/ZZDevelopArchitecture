//
//  ZZCommonDefine.h
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/8/7.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif

// 宏定义字符串 转NSString, __TEXT( __x )
#undef __TEXT
#undef __TEXT_intermediary
#define __TEXT( __x ) __TEXT_intermediary( __x )
#define __TEXT_intermediary(x) @#x

/**************************************************************/
// delegate 委托
// arm64下失效,具体看https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaTouch64BitGuide/ConvertingYourAppto64-Bit/ConvertingYourAppto64-Bit.html

#define DelegateSelf( __sel ) Delegate( __sel, self)

// delegate被注册KVO时,isa会变, 判断delegate被释放?
// arm64下面 objc_msgSend不能用__VA_ARGS__了
#define Delegate( __sel, ...) \
if (_delegate && [_delegate respondsToSelector:__sel]) \
{ \
__actionXY_return_void = (void (*)(id, SEL, ...)) objc_msgSend; \
__actionXY_return_void(_delegate, __sel, ## __VA_ARGS__); \
}

/**************************************************************/
// NSUserDefaults
#define USER_DEFAULT [NSUserDefaults standardUserDefaults]

/**************************************************************/
// block 安全self
#if __has_feature(objc_arc)
// arc
#define DEF_WEAKSELF                        __weak __typeof(self) weakSelf = self;
//#define DEF_WEAKSELF_( __CLASSNAME__ )      __weak typeof( __CLASSNAME__ *) weakSelf = self;
#define DEF_STRONGSELF                      __strong __typeof(weakSelf) self = weakSelf;
//#define DEF_STRONGSELF_( __CLASSNAME__ )    __strong __typeof( __CLASSNAME__ *) strongSelf = weakSelf;
#else
// mrc
#define DEF_WEAKSELF     __block typeof(id) weakSelf = self;
#define DEF_WEAKSELF_( __CLASSNAME__ )     __block typeof( __CLASSNAME__ *) weakSelf = self;
#endif

/**************************************************************/
static __inline__ CGRect CGRectFromCGSize( CGSize size ) {
    return CGRectMake( 0, 0, size.width, size.height );
};

static __inline__ CGRect CGRectMakeWithCenterAndSize( CGPoint center, CGSize size ) {
    return CGRectMake( center.x - size.width * 0.5, center.y - size.height * 0.5, size.width, size.height );
};

static __inline__ CGRect CGRectMakeWithOriginAndSize( CGPoint origin, CGSize size ) {
    return CGRectMake( origin.x, origin.y, size.width, size.height );
};

static __inline__ CGPoint CGRectCenter( CGRect rect ) {
    return CGPointMake( CGRectGetMidX( rect ), CGRectGetMidY( rect ) );
};
/**************************************************************/
// arc mrc 兼容
#if __has_feature(objc_arc)
#define XY_AUTORELEASE(exp) exp
#define XY_RELEASE(exp) exp
#define XY_RETAIN(exp) exp
#else
#define XY_AUTORELEASE(exp) [exp autorelease]
#define XY_RELEASE(exp) [exp release]
#define XY_RETAIN(exp) [exp retain]
#endif

/**************************************************************/
// property


/**************************************************************/
// No-ops for non-retaining objects.
//static const void *__XYRetainNoOp(CFAllocatorRef allocator, const void *value) { return value; }
//static void __XYReleaseNoOp(CFAllocatorRef allocator, const void *value) { }

/**************************************************************/
// 方法定义
//void (*__actionXY)(id, SEL, ...) = (void (*)(id, SEL, ...))objc_msgSend;
//void (*__actionXY_return_void)(id, SEL, ...);
//id (*__actionXY_return_id)(id, SEL, ...);

/**************************************************************/
// 国际化
#undef __T
#define __T(key) NSLocalizedString((key),@"")

/*! Use NSLocalizedString representing a format string */
#undef __Tf
#define __Tf(key,...) [NSString stringWithFormat:_T(key),__VA_ARGS__]
/**************************************************************/
// 主线程下同步会造成死锁
#undef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}

#undef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
/**************************************************************/
// 循环跳出
#define XY_LOOP_LIMIT_( __maxCount )    \
{ NSUInteger __xy_count; if (__xy_count++ > __maxCount) { break; } }

/**************************************************************/
#pragma mark -end
/*
 #define NavigationBar_HEIGHT 44
 
 #define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
 #define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
 #define SAFE_RELEASE(x) [x release];x=nil
 #define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
 #define CurrentSystemVersion ([[UIDevice currentDevice] systemVersion])
 #define CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])
 
 #define BACKGROUND_COLOR [UIColor colorWithRed:242.0/255.0 green:236.0/255.0 blue:231.0/255.0 alpha:1.0]
 
 
 //use dlog to print while in debug model
 #ifdef DEBUG
 #   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
 #else
 #   define DLog(...)
 #endif
 
 
 #define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
 #define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
 #define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
 
 
 #if TARGET_OS_IPHONE
 //iPhone Device
 #endif
 
 #if TARGET_IPHONE_SIMULATOR
 //iPhone Simulator
 #endif
 
 
 //ARC
 #if __has_feature(objc_arc)
 //compiling with ARC
 #else
 // compiling without ARC
 #endif
 
 
 #pragma mark - common functions
 #define RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }
 
 
 #pragma mark - degrees/radian functions
 #define degreesToRadian(x) (M_PI * (x) / 180.0)
 #define radianToDegrees(radian) (radian*180.0)/(M_PI)
 
 #pragma mark - color functions
 #define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
 #define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
 #define ITTDEBUG
 #define ITTLOGLEVEL_INFO     10
 #define ITTLOGLEVEL_WARNING  3
 #define ITTLOGLEVEL_ERROR    1
 
 #ifndef ITTMAXLOGLEVEL
 
 #ifdef DEBUG
 #define ITTMAXLOGLEVEL ITTLOGLEVEL_INFO
 #else
 #define ITTMAXLOGLEVEL ITTLOGLEVEL_ERROR
 #endif
 
 #endif
 
 // The general purpose logger. This ignores logging levels.
 #ifdef ITTDEBUG
 #define ITTDPRINT(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
 #else
 #define ITTDPRINT(xx, ...)  ((void)0)
 #endif
 
 // Prints the current method's name.
 #define ITTDPRINTMETHODNAME() ITTDPRINT(@"%s", __PRETTY_FUNCTION__)
 
 // Log-level based logging macros.
 #if ITTLOGLEVEL_ERROR <= ITTMAXLOGLEVEL
 #define ITTDERROR(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
 #else
 #define ITTDERROR(xx, ...)  ((void)0)
 #endif
 
 #if ITTLOGLEVEL_WARNING <= ITTMAXLOGLEVEL
 #define ITTDWARNING(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
 #else
 #define ITTDWARNING(xx, ...)  ((void)0)
 #endif
 
 #if ITTLOGLEVEL_INFO <= ITTMAXLOGLEVEL
 #define ITTDINFO(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
 #else
 #define ITTDINFO(xx, ...)  ((void)0)
 #endif
 
 #ifdef ITTDEBUG
 #define ITTDCONDITIONLOG(condition, xx, ...) { if ((condition)) { \
 ITTDPRINT(xx, ##__VA_ARGS__); \
 } \
 } ((void)0)
 #else
 #define ITTDCONDITIONLOG(condition, xx, ...) ((void)0)
 #endif
 
 #define ITTAssert(condition, ...)                                       \
 do {                                                                      \
 if (!(condition)) {                                                     \
 [[NSAssertionHandler currentHandler]                                  \
 handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
 file:[NSString stringWithUTF8String:__FILE__]  \
 lineNumber:__LINE__                                  \
 description:__VA_ARGS__];                             \
 }                                                                       \
 } while(0)
 
 #define LOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]
 #define   WIDTH   [[UIScreen mainScreen] bounds].size.width
 #define  HEIGHT  [[UIScreen mainScreen] bounds].size.height
 
 #define VIEWWITHTAG(_OBJECT, _TAG)    [_OBJECT viewWithTag : _TAG]
 #define MyLocal(x, ...) NSLocalizedString(x, nil)
 
 
 #define LOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]
 
 */