//
//  NetworkHandler.m
//  mNodeClient
//
//  Created by willyy on 2017/3/6.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "NetworkHandler.h"

@implementation NetworkHandler

+ (instancetype)sharedHandler {
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [super sharedHandler];
    });
    return _sharedInstance;
}

+ (dispatch_queue_t)instanceQueue
{
    return [[self sharedHandler] instanceQueue];
}

- (void)Login:(NSDictionary *)loginInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler{
    [super getTokenByUserInfo:loginInfo withHandler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

- (void)sayHello:(NSDictionary *)helloInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler{
    [super baseApi:@"api/sayHello" withInfo:helloInfo withMethod:@"GET" progress:^(NSProgress * _Nonnull downloadProgress) {
    } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

- (void)postHello:(NSDictionary *)helloInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler{
    [super baseApi:@"api/sayHello" withInfo:helloInfo withMethod:@"POST" progress:^(NSProgress * _Nonnull downloadProgress) {
    } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

- (void)apiHelloWithHandler:(void (^)(NSDictionary *res,NSError *error))handler{
    [super baseApi:@"api" withInfo:nil withMethod:@"GET" progress:^(NSProgress * _Nonnull downloadProgress) {
    } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
        handler(res,error);
    }];
}

@end
