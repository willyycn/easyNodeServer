//
//  GlobalTools.h
//  mNodeClient
//
//  Created by willyy on 2017/2/28.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CryptoWrapper : NSObject
+ (instancetype)sharedWrapper;
- (NSString *)getRK;
- (NSString *)getRegainTokenStr;
//jwt
- (BOOL)verifyJWT:(NSString *)jwtData;
- (NSString *)signatureJWT;
//rsa with default Key
- (NSData *)encryptWithDefaultPublicKey:(NSData *)plainData;
@end
