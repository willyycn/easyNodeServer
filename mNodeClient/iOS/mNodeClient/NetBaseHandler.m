//
//  NetBaseHandler.m
//  mNodeClient
//
//  Created by willyy on 2017/2/28.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "NetBaseHandler.h"
#import "CryptoWrapper.h"
#import "GlobalTools.h"
#import "MF_Base64Additions.h"

@interface NetBaseHandler ()

@end

@implementation NetBaseHandler

+ (instancetype)sharedHandler {
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

-(id)init
{
    self=[super init];
    if (self) {
        //init
        self = [self initWithBaseURL:[NSURL URLWithString:ServerUrl]];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer.timeoutInterval = 20.f;
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"application/x-www-form-urlencoded; charset=UTF-8", nil];
    }
    return self;
}

+ (dispatch_queue_t)instanceQueue
{
    return [[self sharedHandler] instanceQueue];
}

//获取token 获取
- (void)getTokenByUserInfo:(NSDictionary *)userinfo withHandler:(void (^) (NSDictionary *response, NSError *error))handler{
    NSString *username = userinfo[@"username"] !=nil ? userinfo[@"username"]:@"";
    NSString *password = userinfo[@"password"] !=nil ? userinfo[@"password"]:@"";
    NSString *authcode = userinfo[@"authcode"] !=nil ? userinfo[@"authcode"]:@"";
    
    NSString *rk = [[CryptoWrapper sharedWrapper] getRK];
    NSDictionary *sendDic = @{@"username":username,@"password":password,@"authcode":authcode,@"rk":rk}.copy;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sendDic options:0 error:nil];
    NSData *enData = [[CryptoWrapper sharedWrapper] encryptWithDefaultPublicKey:jsonData];
    
    NSString *jsonStr = [enData base64UrlEncodedString];
    
    [[[self class] sharedHandler] POST:@"api/getToken" parameters:@{@"info":jsonStr} progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSMutableDictionary *resultDic = [(NSDictionary *)responseObject mutableCopy];
            if ((NSString *)resultDic[@"status"]==nil) {
                NSString *tokenInfo = (NSString *)resultDic[@"token"];
                BOOL verify = [[CryptoWrapper sharedWrapper]verifyJWT:tokenInfo];
                if (verify) {
                    handler(@{@"status":@(1)},nil);
                }
                else{
                    handler(@{@"status":@(0)},nil);
                }
            }
            else{
                handler(resultDic,nil);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(nil,error);
        }
    }];
}

- (void)regainTokenWithHandler:(void (^) (NSDictionary *response, NSError *error))handler{
    NSString * jsonStr = [[CryptoWrapper sharedWrapper]getRegainTokenStr];
    [[[self class] sharedHandler] POST:@"api/regainToken" parameters:@{@"info":jsonStr} progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            NSMutableDictionary *resultDic = [(NSDictionary *)responseObject mutableCopy];
            NSString *tokenInfo = (NSString *)resultDic[@"token"];
            BOOL verify = [[CryptoWrapper sharedWrapper]verifyJWT:tokenInfo];
            if (verify) {
                handler(@{@"status":@(1)},nil);
            }
            else{
                handler(@{@"status":@(0)},nil);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(nil,error);
        }
    }];
}

//使用token base Api
- (void)baseApi:(NSString *)ApiUrl withInfo:(NSDictionary *)param withMethod:(NSString *)method progress:(void (^)(NSProgress *_Nonnull downloadProgress))progress handler:(void (^)(NSDictionary *res,NSError *error))handler{
    NSString *jwt = [[CryptoWrapper sharedWrapper]signatureJWT];
    [[[[self class] sharedHandler] requestSerializer] setValue:jwt forHTTPHeaderField:@"JWT"];
    
    if ([method isEqualToString:@"GET"]) {
        [[[self class] sharedHandler]GET:ApiUrl parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
            progress(downloadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject[@"status"] integerValue] == 4000) {
                //regain token and call again
                [self regainTokenWithHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
                    if (!error && [response[@"status"]integerValue] == 1) {
                        NSLog(@"toke regained!!");
                        [self baseApi:ApiUrl withInfo:param withMethod:method progress:^(NSProgress * _Nonnull downloadProgress) {
                            progress(downloadProgress);
                        } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
                            handler(res,nil);
                        }];
                    }
                    else{
                        handler(@{@"status":@(4000)},nil);
                    }
                }];
            }
            else{
                handler(responseObject,nil);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            handler(nil,error);
        }];
    }
    else if ([method isEqualToString:@"POST"]){
        [[[self class] sharedHandler]POST:ApiUrl parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
            progress(downloadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject[@"status"] integerValue] == 4000) {
                [self regainTokenWithHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
                    if (!error && [response[@"status"]integerValue] == 1) {
                        NSLog(@"toke regained!!");
                        [self baseApi:ApiUrl withInfo:param withMethod:method progress:^(NSProgress * _Nonnull downloadProgress) {
                            progress(downloadProgress);
                        } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
                            handler(res,nil);
                        }];
                    }
                    else{
                        handler(@{@"status":@(4000)},nil);
                    }
                }];
            }
            else{
                handler(responseObject,nil);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            handler(nil,error);
        }];
    }
    else if ([method isEqualToString:@"PUT"]){
        [[[self class] sharedHandler]PUT:ApiUrl parameters:param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject[@"status"] integerValue] == 4000) {
                [self regainTokenWithHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
                    if (!error && [response[@"status"]integerValue] == 1) {
                        NSLog(@"toke regained!!");
                        [self baseApi:ApiUrl withInfo:param withMethod:method progress:^(NSProgress * _Nonnull downloadProgress) {
                            progress(downloadProgress);
                        } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
                            handler(res,nil);
                        }];
                    }
                    else{
                        handler(@{@"status":@(4000)},nil);
                    }
                }];
            }
            else{
                handler(responseObject,nil);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            handler(nil,error);
        }];
    }
    else if ([method isEqualToString:@"DELETE"]){
        [[[self class] sharedHandler]DELETE:ApiUrl parameters:param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject[@"status"] integerValue] == 4000) {
                [self regainTokenWithHandler:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
                    if (!error && [response[@"status"]integerValue] == 1) {
                        NSLog(@"toke regained!!");
                        [self baseApi:ApiUrl withInfo:param withMethod:method progress:^(NSProgress * _Nonnull downloadProgress) {
                            progress(downloadProgress);
                        } handler:^(NSDictionary * _Nullable res, NSError * _Nullable error) {
                            handler(res,nil);
                        }];
                    }
                    else{
                        handler(@{@"status":@(4000)},nil);
                    }
                }];
            }
            else{
                handler(responseObject,nil);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            handler(nil,error);
        }];
    }
}


@end
