//
//  ZZRequestHelper.m
//  ZZDevelopArchitecture
//
//  Created by Zhouzheng on 15/8/26.
//  Copyright (c) 2015年 ZZ. All rights reserved.
//

/*
 MKNetworkEngine是一个假单例的类，负责管理你的app的网络队列。因此，简单的请求时，你应该直接使用MKNetworkEngine的方法。在更为复杂的定制中，你应该集成并子类化它。每一个MKNetworkEngine的子类都有他自己的Reachability对象来通知服务器的连通情况。你应该考虑为你的每一个特别的REST服务器请求子类化MKNetworkEngine。因为是假单例模式，每一个单独的子类的请求，都会通过仅有的队列发送。
 
 
 重写 MKNetworkEngin的一些方法时,需要调用 - (void)registerOperationSubclass:(Class) aClass;
 
 改变提交的数据类型需要设置postDataEncoding
 */

#import "ZZRequestHelper.h"
#import "ZZDevelopPreDefine.h"
#import "ZZJsonHelper.h"
#import "ZZCommon.h"
//#import "XYQuick.h"

@interface RequestHelper()

@end

@implementation RequestHelper

+ (id)defaultSettings
{
    // 参考
    RequestHelper *eg = [[RequestHelper alloc] initWithHostName:@"www.webxml.com.cn" customHeaderFields:@{@"x-client-identifier" : @"iOS"}];
    
    eg.freezable = YES;
    eg.forceReload = YES;
    return eg;
}

// [super initWithHostName:@"www.apple.com" customHeaderFields:@{@"x-client-identifier" : @"iOS"}]
- (id)init
{
    if (self = [super init])
    {
        _freezable = YES;
        _forceReload = YES;
    }
    return self;
}

- (void)dealloc
{
}


- (HttpRequest *)get:(NSString *)path
{
    return [self get:path params:nil];
}
- (HttpRequest *)get:(NSString *)path
              params:(id)anObject
{
    return [self request:path params:anObject method:requestHelper_get];
}

- (HttpRequest *)post:(NSString *)path
               params:(id)anObject
{
    return [self request:path params:anObject method:requestHelper_post];
}

- (HttpRequest *)request:(NSString *)path
                  params:(id)anObject
                  method:(HTTPMethod)httpMethod
{
    NSString *strHttpMethod = nil;
    
    if (httpMethod == requestHelper_get)
    {
        strHttpMethod = @"GET";
    }
    else if (httpMethod == requestHelper_post)
    {
        strHttpMethod = @"POST";
    }
    else if (httpMethod == requestHelper_put)
    {
        strHttpMethod = @"PUT";
    }
    else if (httpMethod == requestHelper_del)
    {
        strHttpMethod = @"DELETE";
    }
    
    if (strHttpMethod == nil)
        return nil;
    
    NSDictionary *dic = nil;
    if (anObject)
    {
        if ([anObject isKindOfClass:[NSDictionary class]])
        {
            dic = anObject;
        }
        else
        {
            dic = [anObject jsonDictionary];
        }
    }
    
    HttpRequest *tempOp = [self operationWithPath:path params:dic httpMethod:strHttpMethod];
    
    return tempOp;
}

- (void)cancelRequestWithString:(NSString*)string
{
    [RequestHelper cancelOperationsContainingURLString:string];
}


#pragma mark- Image
+ (id)webImageEngine
{
    static dispatch_once_t once;
    static MKNetworkEngine * __singleton__;
    dispatch_once( &once, ^{ __singleton__ = [[self alloc] init]; } );
    
    return __singleton__;
}

+ (NSString *)generateAccessTokenWithObject:(id)anObject
{
    NSDictionary *dic = anObject;
    NSString *link = [dic objectForKey:@"link"];
    NSString *uuid = [ZZCommon UUID];
    NSString *str1 = [NSString stringWithFormat:@"%@+%@", link, uuid];
    // const char *str2 = [str1 cStringUsingEncoding:NSUTF8StringEncoding];
    return str1;
}

- (id)submit:(HttpRequest *)op
{
    if (op != nil)
    {
        if ([op.HTTPMethod isEqualToString:@"GET"])
        {
            [self enqueueOperation:op forceReload:self.forceReload];
        }
        else
        {
            [self enqueueOperation:op forceReload:NO];
        }
    }
    
    return self;
}

@end

#pragma mark -  MKNetworkOperation (XY)
@implementation MKNetworkOperation (XY)

// if forceReload == YES, 先读缓存,然后发请求,blockS响应2次, 只支持GET
- (id)submitInQueue:(RequestHelper *)requests
{
    // 非下载请求
    [requests enqueueOperation:self forceReload:NO];
    
    return self;
}

- (id)uploadFiles:(NSDictionary *)name_path
{
    if (name_path)
    {
        [name_path enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [self addFile:obj forKey:key];
        }];
    }
    
    return self;
}

// 请重载此方法实现自己的通用解析方法
- (id)succeed:(RequestHelper_normalRequestSucceedBlock)blockS
       failed:(RequestHelper_normalRequestFailedBlock)blockF
{
    [self addCompletionHandler:blockS errorHandler:blockF];
    
    return self;
}
@end


#pragma mark -  Downloader
@interface Downloader()
@property (nonatomic,  strong) NSString *tempFilePath;
@property (nonatomic, assign) DownloadHelper *downloadHelper;
@end

@interface DownloadHelper()
@property (nonatomic, strong) NSMutableArray *downloadArray;

@end

@implementation Downloader
/*
 - (void)setDownloadHelper:(DownloadHelper *)downloadHelper{
 _downloadHelper = downloadHelper;
 }
 */
- (id)submitInQueue:(DownloadHelper *)requests
{
    NSString *str = self.toFile;
    if (str && [requests isKindOfClass:[DownloadHelper class]])
    {
        // 下载请求
        [requests enqueueOperation:self];
        [((DownloadHelper *)requests).downloadArray addObject:self];
    }
    else if (str == nil)
    {
        // 非下载队列
        NSLog(@"%@ is not DownloadHelper", requests);
    }
    
    return self;
}
- (id) progress:(RequestHelper_downloadRequestProgressBlock)blockP
{
    if (blockP)
    {
        [self onDownloadProgressChanged:blockP];
    }
    
    return self;
}
- (id)succeed:(RequestHelper_downloadRequestSucceedBlock)blockS
       failed:(RequestHelper_downloadRequestFailedBlock)blockF
{
    [self addCompletionHandler:^(HttpRequest *operation) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        
        NSString *filePath = ((Downloader*)operation).toFile;
        
        // 下载完成以后 先删除之前的文件 然后move新的文件
        if ([fileManager fileExistsAtPath:filePath])
        {
            [fileManager removeItemAtPath:filePath error:&error];
            if (error)
            {
                NSLog(@"remove %@ file failed!\nError:%@", filePath, error);
                return;
            }
        }
        
        NSString *path = [filePath stringByDeletingLastPathComponent];
        if ( NO == [[NSFileManager defaultManager] fileExistsAtPath:path] )
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:path
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error)
            {
                NSLog(@"Error:%@", error);
                return;
            }
        }
        
        [fileManager moveItemAtPath:((Downloader*)operation).tempFilePath toPath:filePath error:&error];
        if (error)
        {
            NSLog(@"move %@ file to %@ file is failed!\nError:%@", ((Downloader*)operation).tempFilePath, filePath, error);
            return;
        }
        
        [((Downloader*)operation).downloadHelper.downloadArray removeObject:((Downloader*)operation)];
        
        if (blockS)
            blockS(operation);
    }
                  errorHandler:^(HttpRequest *errorOp, NSError *err) {
                      [((Downloader*)errorOp).downloadHelper.downloadArray removeObject:((Downloader*)errorOp)];
                      
                      if (blockF)
                          blockF(errorOp, err);
                  }];
    
    return self;
}
- (void)dealloc
{
    [self.downloadHelper.downloadArray removeObject:self];
}

@end

#pragma mark - DownloadHelper
@implementation DownloadHelper
+ (id)defaultSettings
{
    // 参考
    DownloadHelper *eg = [[DownloadHelper alloc] initWithHostName:nil];
    [eg setup];
    
    return eg;
}

- (void)setup
{
    [self registerOperationSubclass:[Downloader class]];
    if (self.downloadArray == nil)
    {
        self.downloadArray = [NSMutableArray arrayWithCapacity:8];
    }
}

- (void)dealloc
{
    
}

- (Downloader *)download:(NSString *)remoteURL
                      to:(NSString*)filePath
                  params:(id)anObject
        breakpointResume:(BOOL)isResume
{
    if (self.downloadArray == nil)
    {
        NSLog(@"please run [downloader setup] once.");
        return nil;
    }
    
    // 如果当前存在同样的下载任务(下载路径是一样的),直接返回nil
    for (Downloader *tempOP in self.downloadArray)
    {
        if ([tempOP.toFile isEqualToString:filePath])
        {
            // 下载任务已经存在
            NSLog(@"%@\n%@\n download task exist", remoteURL, filePath);
            return nil;
        }
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSLog(@"%@ exist", filePath);
    }
    else
    {
        
    }
    
    // 获得临时文件的路径
    /*
     NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
     NSRange lastCharRange = [filePath rangeOfCharacterFromSet:charSet options:NSBackwardsSearch];
     tempFilePath = [NSString stringWithFormat:@"%@/%@.temp", tempFilePath, [filePath substringFromIndex:lastCharRange.location + 1]];
     */
    
    NSString *tempFileName = [NSString stringWithFormat:@"%@.temp", [filePath lastPathComponent]];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
    
    // 获得临时文件的路径
    NSMutableDictionary *newHeadersDict = [[NSMutableDictionary alloc] init];
    // 如果是重新下载，就要删除之前下载过的文件
    if (!isResume && [fileManager fileExistsAtPath:tempFilePath])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:tempFilePath error:&error];
        if (error)
        {
            NSLog(@"%@ file remove failed!\nError:%@", tempFilePath, error);
        }
    }
    else if(!isResume && [fileManager fileExistsAtPath:filePath])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
        if (error)
            NSLog(@"%@ file remove failed!\nError:%@", filePath, error);
    }
    
    NSString *userAgentString = [NSString stringWithFormat:@"%@/%@",
                                 [[[NSBundle mainBundle] infoDictionary]
                                  objectForKey:(NSString *)kCFBundleNameKey],
                                 [[[NSBundle mainBundle] infoDictionary]
                                  objectForKey:(NSString *)kCFBundleVersionKey]];
    [newHeadersDict setObject:userAgentString forKey:@"User-Agent"];
    
    // 判断之前是否下载过 如果有下载重新构造Header
    if (isResume && [fileManager fileExistsAtPath:tempFilePath])
    {
        NSError *error = nil;
        unsigned long long fileSize = [[fileManager attributesOfItemAtPath:tempFilePath
                                                                     error:&error] fileSize];
        if (error)
            NSLog(@"get %@ fileSize failed!\nError:%@", tempFilePath, error);
        
        NSString *headerRange = [NSString stringWithFormat:@"bytes=%llu-", fileSize];
        [newHeadersDict setObject:headerRange forKey:@"Range"];
        
    }
    
    NSDictionary *dic = nil;
    if (anObject)
    {
        if ([anObject isKindOfClass:[NSDictionary class]])
        {
            dic = anObject;
        }
        else
        {
            dic = [anObject jsonDictionary];
        }
    }
    
    Downloader *op = (Downloader *)[self operationWithURLString:remoteURL params:dic];
    op.downloadHelper = self;
    [op addDownloadStream:[NSOutputStream outputStreamToFileAtPath:tempFilePath append:YES]];
    [op addHeaders:newHeadersDict];
    
    op.toFile = filePath;
    op.tempFilePath = tempFilePath;
    
    return op;
}


- (void)cancelDownloadWithString:(NSString *)string
{
    Downloader *op = [self getADownloadWithString:string];
    if (op)
    {
        [op cancel];
        [self.downloadArray removeObject:op];
    }
}

- (void)cancelAllDownloads
{
    for (HttpRequest *tempOP in self.downloadArray)
    {
        [tempOP cancel];
    }
    [self.downloadArray removeAllObjects];
}

- (void)emptyTempFile
{
    NSString *tempDoucment = NSTemporaryDirectory();
    NSString *tempFilePath = [tempDoucment stringByAppendingPathComponent:@"tempdownload"];
    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
}

- (NSArray *)allDownloads
{
    return self.downloadArray;
}

- (Downloader *)getADownloadWithString:(NSString *)string
{
    Downloader *op = nil;
    for (Downloader *tempOP in self.downloadArray)
    {
        if ([tempOP.url isEqualToString:string])
        {
            op = tempOP;
            break;
        }
    }
    
    return op;
}

- (id)submit:(Downloader *)op
{
    NSString *str = op.toFile;
    if (str)
    {
        // 下载请求
        [self enqueueOperation:op];
        [self.downloadArray addObject:op];
    }
    
    return self;
}

#pragma mark -
#pragma mark KVO for network Queue

@end
