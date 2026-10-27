#import "P8JWT.h"
#import <Security/Security.h>

static void Fail(NSError **error, NSString *message) {
    if (error) *error = [NSError errorWithDomain:@"PushWithP8.JWT" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
}
static NSData *InvalidKey(NSError **error) {
    Fail(error,@"P8 ASN.1 无效，需要包含公钥的 P-256 PKCS#8 私钥");
    return nil;
}
// A bounded DER reader: every length is checked before advancing or slicing.
static BOOL Read(NSData *data, NSUInteger *cursor, uint8_t expectedTag, NSData **value) {
    const uint8_t *bytes = data.bytes;
    NSUInteger end = data.length, pos = *cursor;
    if (pos >= end || bytes[pos++] != expectedTag || pos >= end) return NO;
    NSUInteger length = bytes[pos++];
    if (length & 0x80) {
        NSUInteger count = length & 0x7f;
        if (count == 0 || count > sizeof(NSUInteger) || count > end-pos || bytes[pos] == 0) return NO;
        length = 0;
        for (NSUInteger i=0;i<count;i++) {
            if (length > (NSUIntegerMax >> 8)) return NO;
            length = (length << 8) | bytes[pos++];
        }
        if (length < 128) return NO;
    }
    if (length > end-pos) return NO;
    if (value) *value = [data subdataWithRange:NSMakeRange(pos,length)];
    *cursor = pos+length;
    return YES;
}
static NSString *Base64URL(NSData *data) {
    return [[[[data base64EncodedStringWithOptions:0] stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}
static NSData *KeyData(NSString *pem, NSError **error) {
    NSString *trimmed = [pem stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *begin = @"-----BEGIN PRIVATE KEY-----", *end = @"-----END PRIVATE KEY-----";
    if (![trimmed hasPrefix:begin] || ![trimmed hasSuffix:end] || trimmed.length < begin.length+end.length) {
        Fail(error,@"P8 格式无效，需要 PKCS#8 PRIVATE KEY PEM"); return nil;
    }
    NSString *body = [trimmed substringWithRange:NSMakeRange(begin.length,trimmed.length-begin.length-end.length)];
    body = [[body componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
    NSData *der = [[NSData alloc] initWithBase64EncodedString:body options:0];
    NSUInteger p=0; NSData *outer=nil, *version=nil, *algorithm=nil, *inner=nil;
    if (!der || !Read(der,&p,0x30,&outer) || p != der.length) return InvalidKey(error);
    p=0;
    if (!Read(outer,&p,2,&version) || ![version isEqual:[NSData dataWithBytes:"\0" length:1]] || !Read(outer,&p,0x30,&algorithm) || !Read(outer,&p,4,&inner) || p != outer.length) return InvalidKey(error);
    // id-ecPublicKey + prime256v1; reject other curves and algorithms.
    const uint8_t oidBytes[] = {6,7,0x2a,0x86,0x48,0xce,0x3d,2,1,6,8,0x2a,0x86,0x48,0xce,0x3d,3,1,7};
    if (![algorithm isEqual:[NSData dataWithBytes:oidBytes length:sizeof(oidBytes)]]) return InvalidKey(error);
    p=0; NSData *sequence=nil;
    if (!Read(inner,&p,0x30,&sequence) || p != inner.length) return InvalidKey(error);
    p=0; NSData *scalar=nil;
    if (!Read(sequence,&p,2,&version) || ![version isEqual:[NSData dataWithBytes:"\1" length:1]] || !Read(sequence,&p,4,&scalar) || scalar.length != 32) return InvalidKey(error);
    NSData *publicBits=nil;
    if (p < sequence.length && ((const uint8_t *)sequence.bytes)[p] == 0xa0) {
        NSData *curve=nil; if (!Read(sequence,&p,0xa0,&curve)) return InvalidKey(error);
        const uint8_t curveBytes[] = {6,8,0x2a,0x86,0x48,0xce,0x3d,3,1,7};
        if (![curve isEqual:[NSData dataWithBytes:curveBytes length:sizeof(curveBytes)]]) return InvalidKey(error);
    }
    NSData *publicWrapper=nil;
    if (!Read(sequence,&p,0xa1,&publicWrapper) || p != sequence.length) return InvalidKey(error);
    p=0;
    if (!Read(publicWrapper,&p,3,&publicBits) || p != publicWrapper.length || publicBits.length != 66) return InvalidKey(error);
    const uint8_t *pub=publicBits.bytes;
    if (pub[0] != 0 || pub[1] != 4) return InvalidKey(error);
    NSMutableData *key = [[publicBits subdataWithRange:NSMakeRange(1,65)] mutableCopy];
    [key appendData:scalar]; return key;
}

@implementation P8JWT
+ (NSData *)rawSignatureFromDER:(NSData *)der error:(NSError **)error {
    NSUInteger p=0; NSData *sequence=nil, *r=nil, *s=nil;
    if (!Read(der,&p,0x30,&sequence) || p != der.length) { Fail(error,@"ECDSA 签名格式无效"); return nil; }
    p=0;
    if (!Read(sequence,&p,2,&r) || !Read(sequence,&p,2,&s) || p != sequence.length) { Fail(error,@"ECDSA 签名格式无效"); return nil; }
    NSMutableData *raw = [NSMutableData dataWithLength:64]; NSUInteger offset=0;
    for (NSData *integer in @[r,s]) {
        const uint8_t *bytes = integer.bytes; NSUInteger length=integer.length, start=0;
        if (!length || (bytes[0]&0x80)) { Fail(error,@"ECDSA 整数无效"); return nil; }
        if (length > 1 && bytes[0] == 0) {
            if (!(bytes[1]&0x80)) { Fail(error,@"ECDSA 整数编码无效"); return nil; }
            start=1; length--;
        }
        if (length > 32) { Fail(error,@"ECDSA 整数超过 256 位"); return nil; }
        memcpy((uint8_t *)raw.mutableBytes + offset + 32-length, bytes+start, length);
        offset+=32;
    }
    return raw;
}
+ (NSString *)tokenWithKeyID:(NSString *)keyID teamID:(NSString *)teamID privateKey:(NSString *)pem date:(NSDate *)date error:(NSError **)error {
    if (!keyID.length || !teamID.length || !date) { Fail(error,@"Key ID、Team ID 和签发时间不能为空"); return nil; }
    NSData *keyData=KeyData(pem,error); if (!keyData) return nil;
    CFErrorRef keyError=NULL;
    NSDictionary *attributes=@{(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom,(__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPrivate,(__bridge id)kSecAttrKeySizeInBits:@256};
    SecKeyRef key=SecKeyCreateWithData((__bridge CFDataRef)keyData,(__bridge CFDictionaryRef)attributes,&keyError);
    if (!key) { if (error) *error=CFBridgingRelease(keyError); else if (keyError) CFRelease(keyError); return nil; }
    NSData *header=[NSJSONSerialization dataWithJSONObject:@{@"alg":@"ES256",@"kid":keyID} options:0 error:error];
    NSData *payload=[NSJSONSerialization dataWithJSONObject:@{@"iss":teamID,@"iat":@((long long)floor(date.timeIntervalSince1970))} options:0 error:error];
    if (!header || !payload) { CFRelease(key); return nil; }
    NSString *digest=[NSString stringWithFormat:@"%@.%@",Base64URL(header),Base64URL(payload)];
    SecKeyAlgorithm algorithm=kSecKeyAlgorithmECDSASignatureMessageX962SHA256;
    if (!SecKeyIsAlgorithmSupported(key,kSecKeyOperationTypeSign,algorithm)) { CFRelease(key); Fail(error,@"私钥不支持 ES256 签名"); return nil; }
    NSData *signature=CFBridgingRelease(SecKeyCreateSignature(key,algorithm,(__bridge CFDataRef)[digest dataUsingEncoding:NSUTF8StringEncoding],&keyError));
    CFRelease(key);
    if (!signature) { if (error) *error=CFBridgingRelease(keyError); else if (keyError) CFRelease(keyError); return nil; }
    NSData *raw=[self rawSignatureFromDER:signature error:error];
    return raw ? [NSString stringWithFormat:@"%@.%@",digest,Base64URL(raw)] : nil;
}
@end
