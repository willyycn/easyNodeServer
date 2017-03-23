//
//  GlobalTools.m
//  mNodeClient
//
//  Created by willyy on 2017/2/28.
//  Copyright © 2017年 willyy. All rights reserved.
//

#import "CryptoWrapper.h"
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>
#import "KeychainItemWrapper.h"
#import "JWT/JWT.h"
#import "MF_Base64Additions.h"
#import "GlobalTools.h"
#import "CryptLib.h"

@interface CryptoWrapper()
{
    SecKeyRef defaultPrivateKey;
    SecKeyRef defaultPublicKey;
    KeychainItemWrapper *keychain;
    StringEncryption * cryptor;
}
@property (nonatomic,readwrite,copy)NSString *AESKey;
@property (nonatomic,readwrite,copy)NSString *accessKey;
@property (nonatomic,readwrite,copy)NSString *Userid;
@end

NSString *const keyChainID = @"com.gide.mNodeClient.accessKey";

@implementation CryptoWrapper

+ (instancetype)sharedWrapper {
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
        cryptor = [[StringEncryption alloc]init];
        self.AESKey = [self getRandomKey].copy;
        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:keyChainID accessGroup:nil];
        NSString *ak = [self getAccessKey];
        if (ak!=nil)
        {
            self.accessKey = ak.copy;
        }
        NSString *uk = [self getUserid];
        if (uk!=nil)
        {
            self.Userid = uk.copy;
        }

        NSString *derFilePath = [[NSBundle mainBundle] pathForResource:@"p" ofType:@"der"];
        [self extractPublicKeyFromCertificateFile:derFilePath];
    }
    return self;
}

+ (dispatch_queue_t)instanceQueue
{
    return [[self sharedWrapper] instanceQueue];
}

- (NSString *)getRK{
    self.AESKey = [self getRandomKey].copy;
    return self.AESKey;
}

- (NSString *)getRegainTokenStr{
    NSString *rk = [[CryptoWrapper sharedWrapper] getRK];
    NSDictionary *sendDic = @{@"userid":self.Userid,@"accessKey":self.accessKey,@"rk":rk}.copy;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sendDic options:0 error:nil];
    NSData *enData = [[CryptoWrapper sharedWrapper] encryptWithDefaultPublicKey:jsonData];
    NSString *jsonStr = [enData base64UrlEncodedString];
    return jsonStr;
}

- (NSString *)getRandomKey
{
    //声明并赋值字符串长度变量
    static NSInteger kNumber = 48;
    //随机字符串产生的范围（可自定义）
    NSString *sourceString = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    //可变字符串
    NSMutableString *resultString = [NSMutableString string];
    //使用for循环拼接字符串
    for (NSInteger i = 0; i < kNumber; i++) {
        //36是sourceString的长度，也可以写成sourceString.length
        [resultString appendString:[sourceString substringWithRange:NSMakeRange(arc4random() % 36, 1)]];
    }
    return resultString.copy;
}

//AES (random key)
#pragma mark AES public method
-(NSDictionary *)decrypt:(NSString *)cipher{
    NSString *deToken = [self decryptWithAES:cipher];
    if (deToken == nil) {
        NSLog(@"aes decrypt Failed");
        return @{@"status":@(5001)};
    }
    NSData *tokenInfoData = [deToken dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary * tokenJson = [NSJSONSerialization JSONObjectWithData:tokenInfoData options:0 error:nil];
    [[CryptoWrapper sharedWrapper]saveKeyToKeychain:tokenJson[@"accessKey"]];
    [[CryptoWrapper sharedWrapper]saveUseridToKeychain:tokenJson[@"userid"]];
    return tokenJson;
}
#pragma mark AES private method
-(NSString *)decryptWithAES:(NSString *)cipher{
    NSData * sed = [[NSData alloc] initWithBase64EncodedString:cipher options:0];
    
    NSData * sd = [cryptor decrypt:sed key:self.AESKey];;
    NSString *sdb = [[NSString alloc]initWithData:sd encoding:NSUTF8StringEncoding];
    return sdb;
    
}

#pragma mark keyChain private method
- (void)saveKeyToKeychain:(NSString *)accessKey{
    [keychain setObject:accessKey forKey:(__bridge id)(kSecValueData)];
    self.accessKey = accessKey.copy;
}

- (NSString *)getAccessKey{
    return [keychain objectForKey:(__bridge id)(kSecValueData)];
}

- (void)saveUseridToKeychain:(NSString *)userid{
    [keychain setObject:userid forKey:(__bridge id)(kSecAttrAccount)];
    self.Userid = userid.copy;
}

- (NSString *)getUserid{
    return [keychain objectForKey:(__bridge id)(kSecAttrAccount)];
}

#pragma mark jwt (with server generated AccessKey)
- (BOOL)verifyJWT:(NSString *)jwtData{
    BOOL retVal = NO;
    NSDictionary *dic = [self verifyJWTwithPublicKey:jwtData];
    if (dic==nil) {
        return NO;
    }
    NSString *enToken = dic[@"payload"][@"token"];
    NSDictionary *tokenInfoData = [self decrypt:enToken];
    if (tokenInfoData!=nil && tokenInfoData[@"status"]==nil) {
        retVal = YES;
    }
    return retVal;
}

- (NSString *)signatureJWT{
    return [self signatureJwtWithAccessKey];
}

- (NSString *)signatureJwtWithAccessKey{
    JWTClaimsSet *claimSet = [[JWTClaimsSet alloc]init];
    claimSet.issuer = self.Userid;
    claimSet.issuedAt = [NSDate date];
    claimSet.expirationDate = [NSDate dateWithTimeIntervalSinceNow:exKeyLife];
    return [JWTBuilder encodeClaimsSet:claimSet].secret(self.accessKey).algorithmName(@"HS256").encode;
}

- (NSDictionary *)verifyJWTwithPublicKey:(NSString *)jwtData{
    NSString *algorithmName = @"RS256";
    NSString *derFilePath = [[NSBundle mainBundle] pathForResource:@"p" ofType:@"der"];
    NSData *derData = [NSData dataWithContentsOfFile:derFilePath];
    JWTBuilder *decodeBuilder = [JWTBuilder decodeMessage:jwtData].secretData(derData).algorithmName(algorithmName);
    NSDictionary *envelopedPayload = decodeBuilder.decode;
    return envelopedPayload;
}

#pragma mark RSA method

//extract public key
- (OSStatus)extractPublicKeyFromCertificateFile:(NSString *)certPath {
    OSStatus status = -1;
    if (defaultPublicKey == nil) {
        SecTrustRef trust;
        SecTrustResultType trustResult;
        NSData *derData = [NSData dataWithContentsOfFile:certPath];
        if (derData) {
            SecCertificateRef cert = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)derData);
            SecPolicyRef policy = SecPolicyCreateBasicX509();
            status = SecTrustCreateWithCertificates(cert, policy, &trust);
            if (status == errSecSuccess && trust) {
                NSArray *certs = [NSArray arrayWithObject:(__bridge id)cert];
                status = SecTrustSetAnchorCertificates(trust, (CFArrayRef)certs);
                if (status == errSecSuccess) {
                    status = SecTrustEvaluate(trust, &trustResult);
                    // 自签名证书可信
                    if (status == errSecSuccess && (trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed)) {
                        defaultPublicKey = SecTrustCopyPublicKey(trust);
                        /*
                        if (defaultPublicKey) {
                            NSLog(@"Get public key successfully~ %@", defaultPublicKey);
                        }
                         */
                        if (cert) {
                            CFRelease(cert);
                        }
                        if (policy) {
                            CFRelease(policy);
                        }
                        if (trust) {
                            CFRelease(trust);
                        }
                    }
                }
            }
        }
    }
    return status;
}

//公钥加密，因为每次的加密长度有限，所以用到了分段加密，苹果官方文档中提到了分段加密思想。
- (NSData *)encryptWithDefaultPublicKey:(NSData *)plainData {
    // 分配内存块，用于存放加密后的数据段
    size_t cipherBufferSize = SecKeyGetBlockSize(defaultPublicKey);
    uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
    /*
     为什么这里要减12而不是减11?
     苹果官方文档给出的说明是，加密时，如果sec padding使用的是kSecPaddingPKCS1，
     那么支持的最长加密长度为SecKeyGetBlockSize()-11，
     这里说的最长加密长度，我估计是包含了字符串最后的空字符'\0'，
     因为在实际应用中我们是不考虑'\0'的，所以，支持的真正最长加密长度应为SecKeyGetBlockSize()-12
     */
    double totalLength = [plainData length];
    size_t blockSize = cipherBufferSize - 12;// 使用cipherBufferSize - 11是错误的!
    size_t blockCount = (size_t)ceil(totalLength / blockSize);
    NSMutableData *encryptedData = [NSMutableData data];
    // 分段加密
    for (int i = 0; i < blockCount; i++) {
        NSUInteger loc = i * blockSize;
        // 数据段的实际大小。最后一段可能比blockSize小。
        int dataSegmentRealSize = MIN(blockSize, [plainData length] - loc);
        // 截取需要加密的数据段
        NSData *dataSegment = [plainData subdataWithRange:NSMakeRange(loc, dataSegmentRealSize)];
        OSStatus status = SecKeyEncrypt(defaultPublicKey, kSecPaddingPKCS1, (const uint8_t *)[dataSegment bytes], dataSegmentRealSize, cipherBuffer, &cipherBufferSize);
        if (status == errSecSuccess) {
            NSData *encryptedDataSegment = [[NSData alloc] initWithBytes:(const void *)cipherBuffer length:cipherBufferSize];
            // 追加加密后的数据段
            [encryptedData appendData:encryptedDataSegment];

        } else {
            if (cipherBuffer) {
                free(cipherBuffer);
            }
            return nil;
        }
    }
    if (cipherBuffer) {
        free(cipherBuffer);
    }
    return encryptedData;
}

@end
