//
//  ZZMulticastDelegate.m
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 16/1/12.
//  Copyright © 2016年 ZZ. All rights reserved.
//

#import "ZZMulticastDelegate.h"
#import <libkern/OSAtomic.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * How does this class work?
 *
 * In theory, this class is very straight-forward.
 * It provides a way for multiple delegates to be called, each on its own delegate queue.
 *
 * In other words, any delegate method call to this class
 * will get forwarded (dispatch_async'd) to each added delegate.
 *
 * Important note concerning thread-safety:
 *
 * This class is designed to be used from within a single dispatch queue.
 * In other words, it is NOT thread-safe, and should only be used from within the external dedicated dispatch_queue.
 **/

@interface ZZMulticastDelegateNode : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;

@end


@interface ZZMulticastDelegate ()

@property (nonatomic, strong) NSMutableArray *delegateNodes;
- (NSInvocation *)duplicateInvocation:(NSInvocation *)origInvocation;

@end


@interface ZZMulticastDelegateEnumerator ()

@property (nonatomic, assign) NSUInteger numNodes;
@property (nonatomic, assign) NSUInteger currentNodeIndex;
@property (nonatomic, strong) NSArray *delegateNodes;
- (id)initFromDelegateNodes:(NSMutableArray *)inDelegateNodes;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ZZMulticastDelegate

- (id)init
{
    if ((self = [super init]))
    {
        _delegateNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate == nil) return;
    if (delegateQueue == NULL) return;
    
    ZZMulticastDelegateNode *node = [[ZZMulticastDelegateNode alloc] init];
    node.delegate = delegate;
    node.delegateQueue = delegateQueue;
    
    [_delegateNodes addObject:node];
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate == nil) return;
    
    NSUInteger i;
    for (i = [_delegateNodes count]; i > 0; i--)
    {
        ZZMulticastDelegateNode *node = [_delegateNodes objectAtIndex:(i-1)];
        
        if (delegate == node.delegate)
        {
            if ((delegateQueue == NULL) || (delegateQueue == node.delegateQueue))
            {
                node.delegate = nil;
                node.delegateQueue = NULL;
                
                [_delegateNodes removeObjectAtIndex:(i-1)];
            }
        }
    }
}

- (void)removeDelegate:(id)delegate
{
    [self removeDelegate:delegate delegateQueue:NULL];
}

- (void)removeAllDelegates
{
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        node.delegate = nil;
        node.delegateQueue = NULL;
    }
    
    [_delegateNodes removeAllObjects];
}

- (NSUInteger)count
{
    return [_delegateNodes count];
}

- (NSUInteger)countOfClass:(Class)aClass
{
    NSUInteger count = 0;
    
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        if ([node.delegate isKindOfClass:aClass])
        {
            count++;
        }
    }
    
    return count;
}

- (NSUInteger)countForSelector:(SEL)aSelector
{
    NSUInteger count = 0;
    
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        if ([node.delegate respondsToSelector:aSelector])
        {
            count++;
        }
    }
    
    return count;
}

- (ZZMulticastDelegateEnumerator *)delegateEnumerator
{
    return [[ZZMulticastDelegateEnumerator alloc] initFromDelegateNodes:_delegateNodes];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        NSMethodSignature *result = [node.delegate methodSignatureForSelector:aSelector];
        
        if (result != nil)
        {
            return result;
        }
    }
    
    // This causes a crash...
    // return [super methodSignatureForSelector:aSelector];
    
    // This also causes a crash...
    // return nil;
    
    return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)origInvocation
{
    @autoreleasepool {
        
        SEL selector = [origInvocation selector];
        
        for (ZZMulticastDelegateNode *node in _delegateNodes)
        {
            id delegate = node.delegate;
            
            if ([delegate respondsToSelector:selector])
            {
                // All delegates MUST be invoked ASYNCHRONOUSLY.
                
                NSInvocation *dupInvocation = [self duplicateInvocation:origInvocation];
                
                dispatch_async(node.delegateQueue, ^{ @autoreleasepool {
                    
                    [dupInvocation invokeWithTarget:delegate];
                    
                }});
            }
        }
    }
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    // Prevent NSInvalidArgumentException
}

- (void)doNothing {}

- (void)dealloc
{
    [self removeAllDelegates];
}

- (NSInvocation *)duplicateInvocation:(NSInvocation *)origInvocation
{
    NSMethodSignature *methodSignature = [origInvocation methodSignature];
    
    NSInvocation *dupInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [dupInvocation setSelector:[origInvocation selector]];
    
    NSUInteger i, count = [methodSignature numberOfArguments];
    for (i = 2; i < count; i++)
    {
        const char *type = [methodSignature getArgumentTypeAtIndex:i];
        
        if (*type == *@encode(BOOL))
        {
            BOOL value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(char) || *type == *@encode(unsigned char))
        {
            char value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(short) || *type == *@encode(unsigned short))
        {
            short value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(int) || *type == *@encode(unsigned int))
        {
            int value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(long) || *type == *@encode(unsigned long))
        {
            long value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(long long) || *type == *@encode(unsigned long long))
        {
            long long value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(double))
        {
            double value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == *@encode(float))
        {
            float value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else if (*type == '@')
        {
            void *value;
            [origInvocation getArgument:&value atIndex:i];
            [dupInvocation setArgument:&value atIndex:i];
        }
        else
        {
            NSString *selectorStr = NSStringFromSelector([origInvocation selector]);
            
            NSString *format = @"Argument %lu to method %@ - Type(%c) not supported";
            NSString *reason = [NSString stringWithFormat:format, (unsigned long)(i - 2), selectorStr, *type];
            
            [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
        }
    }
    
    [dupInvocation retainArguments];
    
    return dupInvocation;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ZZMulticastDelegateNode

@synthesize delegate;
@synthesize delegateQueue;

- (void)setDelegateQueue:(dispatch_queue_t)dq
{
    if (delegateQueue != dq)
    {
        delegateQueue = dq;
    }
}

- (void)dealloc
{
    
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ZZMulticastDelegateEnumerator

- (id)initFromDelegateNodes:(NSMutableArray *)inDelegateNodes
{
    if ((self = [super init]))
    {
        _delegateNodes = [inDelegateNodes copy];
        
        _numNodes = [_delegateNodes count];
        _currentNodeIndex = 0;
    }
    return self;
}

- (NSUInteger)count
{
    return _numNodes;
}

- (NSUInteger)countOfClass:(Class)aClass
{
    NSUInteger count = 0;
    
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        if ([node.delegate isKindOfClass:aClass])
        {
            count++;
        }
    }
    
    return count;
}

- (NSUInteger)countForSelector:(SEL)aSelector
{
    NSUInteger count = 0;
    
    for (ZZMulticastDelegateNode *node in _delegateNodes)
    {
        if ([node.delegate respondsToSelector:aSelector])
        {
            count++;
        }
    }
    
    return count;
}

- (BOOL)getNextDelegate:(id *)delPtr delegateQueue:(dispatch_queue_t *)dqPtr
{
    while (_currentNodeIndex < _numNodes)
    {
        ZZMulticastDelegateNode *node = [_delegateNodes objectAtIndex:_currentNodeIndex];
        _currentNodeIndex++;
        
        if (node.delegate)
        {
            if (delPtr) *delPtr = node.delegate;
            if (dqPtr)  *dqPtr  = node.delegateQueue;
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)getNextDelegate:(id *)delPtr delegateQueue:(dispatch_queue_t *)dqPtr ofClass:(Class)aClass
{
    while (_currentNodeIndex < _numNodes)
    {
        ZZMulticastDelegateNode *node = [_delegateNodes objectAtIndex:_currentNodeIndex];
        _currentNodeIndex++;
        
        if ([node.delegate isKindOfClass:aClass])
        {
            if (delPtr) *delPtr = node.delegate;
            if (dqPtr)  *dqPtr  = node.delegateQueue;
            
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)getNextDelegate:(id *)delPtr delegateQueue:(dispatch_queue_t *)dqPtr forSelector:(SEL)aSelector
{
    while (_currentNodeIndex < _numNodes)
    {
        ZZMulticastDelegateNode *node = [_delegateNodes objectAtIndex:_currentNodeIndex];
        _currentNodeIndex++;
        
        if ([node.delegate respondsToSelector:aSelector])
        {
            if (delPtr) *delPtr = node.delegate;
            if (dqPtr)  *dqPtr  = node.delegateQueue;
            
            return YES;
        }
    }
    
    return NO;
}


@end

