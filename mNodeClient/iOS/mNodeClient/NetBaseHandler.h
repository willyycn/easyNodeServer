//
//  NetBaseHandler.h
//  mNodeClient
//
//  Created by willyy on 2017/2/28.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface NetBaseHandler : AFHTTPSessionManager

+ (instancetype _Nonnull)sharedHandler;
- (void)getTokenByUserInfo:(NSDictionary *_Nonnull)userinfo withHandler:(nullable void (^) (NSDictionary *_Nullable res,NSError *_Nullable error))handler;
- (void)baseApi:(NSString *_Nonnull)ApiUrl withInfo:(NSDictionary *_Nullable)param withMethod:(NSString *_Nonnull)method progress:(nullable void (^)(NSProgress *_Nonnull downloadProgress))progress handler:(nullable void (^)(NSDictionary *_Nullable res,NSError *_Nullable error))handler;
@end
