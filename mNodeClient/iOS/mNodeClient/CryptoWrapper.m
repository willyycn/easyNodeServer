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

/**
 * get cipher str which regain token needed
 */
- (NSString *)getRegainTokenStr{
    NSString *rk = [[CryptoWrapper sharedWrapper] getRK];
    NSDictionary *sendDic = @{@"userid":self.Userid,@"accessKey":self.accessKey,@"rk":rk}.copy;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sendDic options:0 error:nil];
    NSData *enData = [[CryptoWrapper sharedWrapper] encryptWithDefaultPublicKey:jsonData];
    NSString *jsonStr = [enData base64UrlEncodedString];
    return jsonStr;
}

/**
 * get RandomString as AESKey
 *
 */
- (NSString *)getRandomKey
{
    static NSInteger kNumber = 48;
    NSString *sourceString = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultString = [NSMutableString string];
    for (NSInteger i = 0; i < kNumber; i++) {
        [resultString appendString:[sourceString substringWithRange:NSMakeRange(arc4random() % sourceString.length, 1)]];
    }
    return resultString.copy;
}

#pragma mark AES public method
/**
 * AES decrypt the cipher from JWT payload, then save accessKey and userid to Keychain
 *
 * @param cipher cipherText
 */
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
/**
 * AES decrypt use AESKey which generate at the begainning;
 *
 * @param cipher AES cipher
 */
-(NSString *)decryptWithAES:(NSString *)cipher{
    NSData * sed = [[NSData alloc] initWithBase64EncodedString:cipher options:0];
    NSData * sd = [cryptor decrypt:sed key:self.AESKey];;
    NSString *sdb = [[NSString alloc]initWithData:sd encoding:NSUTF8StringEncoding];
    return sdb;
    
}

#pragma mark keyChain private method

/**
 * save accessKey to Keychain
 *
 */
- (void)saveKeyToKeychain:(NSString *)accessKey{
    [keychain setObject:accessKey forKey:(__bridge id)(kSecValueData)];
    self.accessKey = accessKey.copy;
}

/**
 * get accessKey from Keychain
 *
 */
- (NSString *)getAccessKey{
    return [keychain objectForKey:(__bridge id)(kSecValueData)];
}

/**
 * save userid to Keychain
 *
 */
- (void)saveUseridToKeychain:(NSString *)userid{
    [keychain setObject:userid forKey:(__bridge id)(kSecAttrAccount)];
    self.Userid = userid.copy;
}

/**
 * get userid from Keychain
 *
 */
- (NSString *)getUserid{
    return [keychain objectForKey:(__bridge id)(kSecAttrAccount)];
}

#pragma mark jwt (with server generated AccessKey)

/**
 *  wrapper of verifyJWTwithPublicKey, then decrypt the payload using AESKey which generated at the beginning.
 *
 */
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

/**
 * wrapper of signatureJwtWithAccessKey
 *
 */
- (NSString *)signatureJWT{
    return [self signatureJwtWithAccessKey];
}

/**
 * signature JWT using accessKey from server. server would decode JWT and verify it using accessKey which server saved in DB
 *
 */
- (NSString *)signatureJwtWithAccessKey{
    JWTClaimsSet *claimSet = [[JWTClaimsSet alloc]init];
    claimSet.issuer = self.Userid;
    claimSet.issuedAt = [NSDate date];
    claimSet.expirationDate = [NSDate dateWithTimeIntervalSinceNow:exKeyLife];
    return [JWTBuilder encodeClaimsSet:claimSet].secret(self.accessKey).algorithmName(@"HS256").encode;
}

/**
 * verify JWT using publicKey, decode the payload. this could make sure the payload decoded is came from Server
 *
 */
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
                    if (status == errSecSuccess && (trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed)) {
                        defaultPublicKey = SecTrustCopyPublicKey(trust);
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


- (NSData *)encryptWithDefaultPublicKey:(NSData *)plainData {
    size_t cipherBufferSize = SecKeyGetBlockSize(defaultPublicKey);
    uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
    double totalLength = [plainData length];
    size_t blockSize = cipherBufferSize - 12;    size_t blockCount = (size_t)ceil(totalLength / blockSize);
    NSMutableData *encryptedData = [NSMutableData data];
    for (int i = 0; i < blockCount; i++) {
        NSUInteger loc = i * blockSize;
        int dataSegmentRealSize = MIN(blockSize, [plainData length] - loc);
        NSData *dataSegment = [plainData subdataWithRange:NSMakeRange(loc, dataSegmentRealSize)];
        OSStatus status = SecKeyEncrypt(defaultPublicKey, kSecPaddingPKCS1, (const uint8_t *)[dataSegment bytes], dataSegmentRealSize, cipherBuffer, &cipherBufferSize);
        if (status == errSecSuccess) {
            NSData *encryptedDataSegment = [[NSData alloc] initWithBytes:(const void *)cipherBuffer length:cipherBufferSize];
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
