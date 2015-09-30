//
//  ZZDebugToy.m
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/7/8.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import "ZZDebugToy.h"
#import "ZZRuntime.h"
#import <execinfo.h>
#import <objc/runtime.h>

#undef	ZZDebug_key_hookDealloc
#define ZZDebug_key_hookDealloc	"ZZDebug.hookDealloc"

#pragma mark - ZZDebugToy
@interface ZZWatcher : NSObject
@property (nonatomic ,copy) NSString *stringDealloc;
@end

@implementation ZZWatcher
- (void)dealloc
{
    NSLog(@"%@", _stringDealloc);
}
@end

@implementation ZZDebugToy

+ (void)hookObject:(id)anObject whenDeallocLogString:(NSString *)string
{
    ZZWatcher *watcher = [[ZZWatcher alloc] init];
    watcher.stringDealloc = string;
    objc_setAssociatedObject(anObject, ZZDebug_key_hookDealloc, watcher, OBJC_ASSOCIATION_RETAIN);
}

// Recursively travel down the view tree, increasing the indentation level for children
+ (void)dumpView:(UIView *)aView atIndent:(int)indent into:(NSMutableString *)outstring
{
    for (int i = 0; i < indent; i++) [outstring appendString:@"--"];
    
    [outstring appendFormat:@"[%2d] %@\n tag:%ld frame:%@\n", indent, [[aView class] description], (long)aView.tag, NSStringFromCGRect(aView.frame)];
    
    for (UIView *view in [aView subviews]) [self dumpView:view atIndent:indent + 1 into:outstring];
}
// Start the tree recursion at level 0 with the root view
+ (NSString *)displayViews:(UIView *)aView
{
    NSMutableString *outstring = [[NSMutableString alloc] init];
    [self dumpView:aView atIndent:0 into:outstring];
    return outstring;
}
@end



#pragma mark - ZZDebug

#define ZZ_KB	(1024)
#define ZZ_MB	(ZZ_KB * 1024)
#define ZZ_GB	(ZZ_MB * 1024)
#define ZZDebug_memory_step 20

#undef	MAX_CALLSTACK_DEPTH
#define MAX_CALLSTACK_DEPTH	(64)

@interface ZZDebug()

@property (nonatomic, readonly) int64_t manualBytes;
@property (nonatomic, strong) NSMutableArray * manualBlocks;
@end

@implementation ZZDebug __DEF_SINGLETON

+ (void)printCallstack:(NSUInteger)depth
{
    NSArray * callstack = [self callstack:depth];
    if ( callstack && callstack.count )
    {
        NSLog(@"%@", callstack);
    }
}

+ (NSArray *)callstack:(NSUInteger)depth
{
    NSMutableArray * array = [[NSMutableArray alloc] init];
    
    void * stacks[MAX_CALLSTACK_DEPTH] = { 0 };
    
    depth = backtrace( stacks, (int)((depth > MAX_CALLSTACK_DEPTH) ? MAX_CALLSTACK_DEPTH : depth) );
    if ( depth )
    {
        char ** symbols = backtrace_symbols( stacks, (int)depth );
        if ( symbols )
        {
            for ( int i = 0; i < depth; ++i )
            {
                NSString * symbol = [NSString stringWithUTF8String:(const char *)symbols[i]];
                if ( 0 == [symbol length] )
                    continue;
                
                NSRange range1 = [symbol rangeOfString:@"["];
                NSRange range2 = [symbol rangeOfString:@"]"];
                
                if ( range1.length > 0 && range2.length > 0 )
                {
                    NSRange range3;
                    range3.location = range1.location;
                    range3.length = range2.location + range2.length - range1.location;
                    [array addObject:[symbol substringWithRange:range3]];
                }
                else
                {
                    [array addObject:symbol];
                }
            }
            
            free( symbols );
        }
    }
    
    return array;
}

+ (void)breakPoint
{
#if defined(__ppc__)
    asm("trap");
#elif defined(__i386__) ||  defined(__amd64__)
    asm("int3");
#endif
}

- (void)allocAllMemory
{
    NSProcessInfo *progress  = [NSProcessInfo processInfo];
    unsigned long long total = [progress physicalMemory];
    //	NSUInteger			total = NSRealMemoryAvailable();
    
    for ( ;; )
    {
        if ( _manualBytes + ZZDebug_memory_step * ZZ_MB >= total )
            break;
        
        void *block = malloc(ZZDebug_memory_step * ZZ_MB);
        
        if ( block )
        {
            _manualBytes += ZZDebug_memory_step * ZZ_MB;
            [self.manualBlocks addObject:[NSNumber numberWithUnsignedLongLong:(unsigned long long)block]];
        }
        else
        {
            break;
        }
    }
}

- (void)freeAllMemory
{
    for ( NSNumber *block in self.manualBlocks )
    {
        void *ptr = (void *)[block unsignedLongLongValue];
        free(ptr);
    }
    
    [self.manualBlocks removeAllObjects];
}

- (void)allocMemory:(NSInteger)MB
{
    void *block = malloc(MB * ZZ_MB);
    if ( block )
    {
        _manualBytes += MB * ZZ_MB;
        [self.manualBlocks addObject:[NSNumber numberWithUnsignedLongLong:(unsigned long long)block]];
    }
}

- (void)freeLastMemory
{
    NSNumber *block = [self.manualBlocks lastObject];
    if ( block )
    {
        void *ptr = (void *)[block unsignedLongLongValue];
        free(ptr);
        
        [self.manualBlocks removeLastObject];
    }
}

#pragma mark - get set
- (NSMutableArray *)manualBlocks
{
    return _manualBlocks ?: (_manualBlocks = [@[] mutableCopy], _manualBlocks);
}

@end

#pragma mark - BorderView
#if (1 == __ZZ_DEBUG_SHOWBORDER__)
@interface UIWindow(ZZDebugPrivate)
- (void)mySendEvent:(UIEvent *)event;
@end

@implementation UIWindow(ZZDebug)

+ (void)load
{
    [ZZRuntime swizzleInstanceMethodWithClass:[UIWindow class] originalSel:@selector(sendEvent:) replacementSel:@selector(mySendEvent:)];
}

- (void)mySendEvent:(UIEvent *)event
{
    UIWindow * keyWindow = [UIApplication sharedApplication].keyWindow;
    if ( self == keyWindow && UIEventTypeTouches == event.type)
    {
        NSSet * allTouches = [event allTouches];
        if ( 1 == [allTouches count] )
        {
            UITouch * touch = [[allTouches allObjects] objectAtIndex:0];
            if ( 1 == [touch tapCount]  && UITouchPhaseBegan == touch.phase )
            {
                // NSLog(@"view '%@', touch began\n%@", [[touch.view class] description], [touch.view description]);
                BorderView * border = [[BorderView alloc] initWithFrame:touch.view.bounds];
                [touch.view addSubview:border];
                [border startAnimation];
            }
        }
    }
    [self mySendEvent:event];
}

@end


@implementation BorderView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
    {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.layer.borderWidth = 2.0f;
        self.layer.borderColor = [UIColor redColor].CGColor;
        //		self.textColor = [UIColor redColor];
        //		self.textAlignment = UITextAlignmentCenter;
        //		self.font = [UIFont boldSystemFontOfSize:12.0f];
    }
    return self;
}

- (void)didMoveToSuperview
{
    self.layer.cornerRadius = self.superview.layer.cornerRadius;
}

- (void)startAnimation
{
    self.alpha = 1.0f;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:.75f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(didAppearingAnimationStopped)];
    
    self.alpha = 0.0f;
    
    [UIView commitAnimations];
}

- (void)didAppearingAnimationStopped
{
    [self removeFromSuperview];
}

- (void)dealloc
{
}
@end

#endif
