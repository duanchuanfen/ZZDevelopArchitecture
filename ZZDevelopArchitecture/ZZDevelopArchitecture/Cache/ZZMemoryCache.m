//
//  ZZMemoryCache.m
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/7/31.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

#import "ZZMemoryCache.h"
#import "NSObject+ZZ.h"
#import "NSString+ZZ.h"

#undef	DEFAULT_MAX_COUNT
#define DEFAULT_MAX_COUNT	(48)

@implementation ZZMemoryCache __DEF_SINGLETON


- (id)init
{
    self = [super init];
    if ( self )
    {
        _clearWhenMemoryLow = YES;
        _maxCacheCount = DEFAULT_MAX_COUNT;
        _cachedCount = 0;
        
        _cacheKeys = [[NSMutableArray alloc] init];
        _cacheObjs = [[NSMutableDictionary alloc] init];
        
#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryCacheNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        // todo
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryCacheNotification:) name:UIApplicationWillTerminateNotification object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryCacheNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif	// #if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setClearWhenMemoryLow:(BOOL)clearWhenMemoryLow
{
    if (_clearWhenMemoryLow != clearWhenMemoryLow)
        return;
    
    if (clearWhenMemoryLow == YES)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryCacheNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    _clearWhenMemoryLow = clearWhenMemoryLow;
}

- (void)setMaxCacheCount:(NSUInteger)maxCacheCount
{
    while ( _cachedCount > maxCacheCount )
    {
        NSString * tempKey = [_cacheKeys objectAtIndex:0];
        
        [_cacheObjs removeObjectForKey:tempKey];
        [_cacheKeys removeObjectAtIndex:0];
        
        _cachedCount -= 1;
    }
    
    _maxCacheCount = maxCacheCount;
}

#pragma mark - ZZCacheProtocol

- (BOOL)hasObjectForKey:(id)key
{
    return [_cacheObjs objectForKey:key] ? YES : NO;
}

- (id)objectForKey:(id)key
{
    return [_cacheObjs objectForKey:key];
}

- (void)setObject:(id)object forKey:(id)key
{
    if ( nil == key )
        return;
    
    if ( nil == object )
        return;
    
    _cachedCount += 1;
    
    while ( _cachedCount >= _maxCacheCount )
    {
        NSString * tempKey = [_cacheKeys objectAtIndex:0];
        
        [_cacheObjs removeObjectForKey:tempKey];
        [_cacheKeys removeObjectAtIndex:0];
        
        _cachedCount -= 1;
    }
    
    [_cacheKeys addObject:key];
    [_cacheObjs setObject:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    if ( [_cacheObjs objectForKey:key] )
    {
        [_cacheKeys removeObjectIdenticalTo:key];
        [_cacheObjs removeObjectForKey:key];
        
        _cachedCount -= 1;
    }
}

- (void)removeAllObjects
{
    [_cacheKeys removeAllObjects];
    [_cacheObjs removeAllObjects];
    
    _cachedCount = 0;
}

#pragma mark -

- (void)handleMemoryCacheNotification:(NSNotification *)notification
{
#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
    if ([notification.name isEqualToString:UIApplicationDidReceiveMemoryWarningNotification])
    {
        if ( _clearWhenMemoryLow )
        {
            [self removeAllObjects];
        }
    }
#endif	// #if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
}

@end

