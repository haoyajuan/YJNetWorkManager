//
//  NetWorkManager.m
//  BaseFoundation
//
//  Created by haoyajuan on 2018/1/16.
//  Copyright © 2018年 HYJ. All rights reserved.
//

#import "NetWorkManager.h"
#import "NetworkCache.h"
@interface NetWorkManager()
//@property (nonatomic,strong) NSURLSessionTask *task;

@end
@implementation NetWorkManager
+ (NetSessionTask *)GET:(NSString *)URL
               parameters:(id)parameters
                    cache:(BOOL)cache
            responseCache:(HttpRequestCache)responseCache
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    NSString *cacheKey = URL;
    if (parameters) {
        cacheKey = [URL stringByAppendingString:[self convertJsonStringFromDictionaryOrArray:parameters]];
    }
    if (responseCache) {
        responseCache([NetworkCache getResponseCacheForKey:cacheKey]);
    }
    NSLog(@"GET  %@",cacheKey);
    AFHTTPSessionManager *manager = [self manager];
    return [manager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (cache) {
            [NetworkCache saveResponseCache:responseObject forKey:cacheKey];
        }
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
    }];
}

+ (NetSessionTask *)POST:(NSString *)URL
                parameters:(id)parameters
                     cache:(BOOL)cache
             responseCache:(HttpRequestCache)responseCache
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    NSString *cacheKey = URL;
    if (parameters) {
        cacheKey = [URL stringByAppendingString:[self convertJsonStringFromDictionaryOrArray:parameters]];
    }
    if (responseCache) {
        responseCache([NetworkCache getResponseCacheForKey:cacheKey]);
    }
    NSLog(@"POST  %@",cacheKey);
    
    AFHTTPSessionManager *manager = [self manager];
    return [manager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (cache) {
            [NetworkCache saveResponseCache:responseObject forKey:cacheKey];
        }
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - 上传图片文件
+ (NetSessionTask *)uploadWithURL:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                             images:(NSArray<UIImage *> *)images
                               name:(NSString *)name
                           mimeType:(NSString *)mimeType
                           progress:(HttpProgress)progress
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure {
    AFHTTPSessionManager *manager = [self manager];
    return [manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            long index = idx;
            NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
            long long totalMilliseconds = interval * 1000 ;
            NSString *fileName = [NSString stringWithFormat:@"%lld.png", totalMilliseconds];
            NSString *name1 = [NSString stringWithFormat:@"%@%ld", name, index];
            [formData appendPartWithFileData:imageData name:name1 fileName:fileName mimeType:[NSString stringWithFormat:@"image/%@",mimeType?mimeType:@"jpeg"]];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
    }];
}

#pragma mark - 下载文件
+ (NetSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(HttpProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(HttpRequestFailed)failure {
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress ? progress(downloadProgress) : nil;
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
        failure && error ? failure(error) : nil;
    }];
    [downloadTask resume];
    return downloadTask;
}
+ (void)timeoutInterval:(NSTimeInterval)timeInterval {
    AFHTTPSessionManager *manager = [self manager];
    manager.requestSerializer.timeoutInterval = timeInterval;
}

+ (NSString *)convertJsonStringFromDictionaryOrArray:(id)parameter {
    NSData *data = [NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

+ (void)cancelAllOperations {
    [[self manager].operationQueue cancelAllOperations];
}

+ (AFHTTPSessionManager *)manager {
    static AFHTTPSessionManager *manager = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [NSURL URLWithString:@"https://api.228.cn/products/getPromotionLink"];
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:sessionConfiguration];
//        manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        manager.completionQueue = dispatch_get_main_queue();
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.requestSerializer.timeoutInterval = 20.0f;
        manager.requestSerializer.cachePolicy = NSURLCacheStorageNotAllowed;
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain", nil];
    });
    return manager;
}

@end
