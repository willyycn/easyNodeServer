//
//  NetworkHandler.h
//  mNodeClient
//
//  Created by willyy on 2017/3/6.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "NetBaseHandler.h"

@interface NetworkHandler : NetBaseHandler

- (void)Login:(NSDictionary *)loginInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler;
- (void)sayHello:(NSDictionary *)helloInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler;
- (void)postHello:(NSDictionary *)helloInfo withHandler:(void (^)(NSDictionary *res,NSError *error))handler;
- (void)apiHelloWithHandler:(void (^)(NSDictionary *res,NSError *error))handler;
@end
