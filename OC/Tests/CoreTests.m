#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "../PushWithP8/Utils/P8JWT.h"
#import "../PushWithP8/Utils/APNsClient.h"
static int failures;
#define CHECK(condition, message) do { if (!(condition)) { fprintf(stderr, "FAIL: %s\n", message); failures++; } } while (0)
static NSData *decode(NSString *s) {
    s = [[s stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    while (s.length % 4) s = [s stringByAppendingString:@"="];
    return [[NSData alloc] initWithBase64EncodedString:s options:0];
}
// Independent DER encoder used only to verify the JOSE signature with Security.
static NSData *integer(NSData *raw) {
    const uint8_t *bytes = raw.bytes; NSUInteger start = 0;
    while (start < raw.length - 1 && bytes[start] == 0) start++;
    NSMutableData *v = [NSMutableData data];
    if (bytes[start] & 0x80) { uint8_t zero = 0; [v appendBytes:&zero length:1]; }
    [v appendData:[raw subdataWithRange:NSMakeRange(start, raw.length-start)]];
    uint8_t header[] = {2, (uint8_t)v.length};
    NSMutableData *result = [NSMutableData dataWithBytes:header length:2]; [result appendData:v]; return result;
}
int main(int argc, const char *argv[]) { @autoreleasepool {
    if (!NSClassFromString(@"P8JWT") || !NSClassFromString(@"APNsClient")) { fprintf(stderr, "FAIL: Objective-C core has not been implemented\n"); return 1; }
    CHECK(argc == 3, "PEM and public DER fixtures required"); if (argc != 3) return 1;
    NSString *pem = [NSString stringWithContentsOfFile:@(argv[1]) encoding:NSUTF8StringEncoding error:NULL];
    NSError *error = nil;
    NSString *token = [P8JWT tokenWithKeyID:@"TESTKEY" teamID:@"TESTTEAM" privateKey:pem date:[NSDate dateWithTimeIntervalSince1970:1700000000] error:&error];
    CHECK(token != nil && error == nil, "valid PKCS8 key must sign");
    NSArray *parts = [token componentsSeparatedByString:@"."];
    CHECK(parts.count == 3, "JWT must contain three parts");
    if (parts.count == 3) {
        NSDictionary *header = [NSJSONSerialization JSONObjectWithData:decode(parts[0]) options:0 error:NULL];
        NSDictionary *claims = [NSJSONSerialization JSONObjectWithData:decode(parts[1]) options:0 error:NULL];
        CHECK([header[@"alg"] isEqual:@"ES256"] && [header[@"kid"] isEqual:@"TESTKEY"], "JWT header must identify ES256/key");
        CHECK([claims[@"iss"] isEqual:@"TESTTEAM"] && [claims[@"iat"] longLongValue] == 1700000000, "JWT claims must use team and supplied issue time");
        NSData *raw = decode(parts[2]); CHECK(raw.length == 64, "JOSE signature must be 64 bytes");
        if (raw.length == 64) {
            NSMutableData *body = [NSMutableData dataWithData:integer([raw subdataWithRange:NSMakeRange(0,32)])];
            [body appendData:integer([raw subdataWithRange:NSMakeRange(32,32)])]; uint8_t h[] = {0x30, (uint8_t)body.length};
            NSMutableData *der = [NSMutableData dataWithBytes:h length:2]; [der appendData:body];
            NSData *spki = [NSData dataWithContentsOfFile:@(argv[2])];
            NSData *public = [spki subdataWithRange:NSMakeRange(spki.length-65,65)];
            SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)public, (__bridge CFDictionaryRef)@{(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeECSECPrimeRandom, (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic}, NULL);
            NSData *message = [[NSString stringWithFormat:@"%@.%@",parts[0],parts[1]] dataUsingEncoding:NSUTF8StringEncoding];
            CHECK(key && SecKeyVerifySignature(key,kSecKeyAlgorithmECDSASignatureMessageX962SHA256,(__bridge CFDataRef)message,(__bridge CFDataRef)der,NULL), "JWT signature must verify against independent public key");
            if (key) CFRelease(key);
        }
    }
    for (NSString *bad in @[@"", @"invalid", @"-----BEGIN PRIVATE KEY-----\nMAA=\n-----END PRIVATE KEY-----", @"-----BEGIN PRIVATE KEY-----\nMIGT\n-----END PRIVATE KEY-----"]) {
        error = nil; CHECK([P8JWT tokenWithKeyID:@"K" teamID:@"T" privateKey:bad date:[NSDate date] error:&error] == nil && error != nil, "invalid PEM/DER must return error");
    }
    uint8_t shortSig[] = {0x30,6,2,1,1,2,1,2};
    NSData *raw = [P8JWT rawSignatureFromDER:[NSData dataWithBytes:shortSig length:8] error:NULL];
    CHECK(raw.length == 64 && ((const uint8_t *)raw.bytes)[31] == 1 && ((const uint8_t *)raw.bytes)[63] == 2, "short integers must be left padded");
    uint8_t padded[72] = {0x30,70,2,33,0,0x80}; padded[37]=2; padded[38]=33; padded[39]=0; padded[40]=0x80;
    raw = [P8JWT rawSignatureFromDER:[NSData dataWithBytes:padded length:72] error:NULL];
    CHECK(raw.length == 64 && ((const uint8_t *)raw.bytes)[0] == 0x80 && ((const uint8_t *)raw.bytes)[32] == 0x80, "sign padding must be removed");
    for (NSUInteger n = 0; n < sizeof(shortSig); n++) {
        error=nil; CHECK([P8JWT rawSignatureFromDER:[NSData dataWithBytes:shortSig length:n] error:&error] == nil && error, "truncated signature must return error");
    }
    uint8_t negative[] = {0x30,6,2,1,0x80,2,1,2};
    error=nil; CHECK([P8JWT rawSignatureFromDER:[NSData dataWithBytes:negative length:8] error:&error] == nil && error, "negative ECDSA integer must be rejected");
    NSMutableData *trailing=[[NSData dataWithBytes:shortSig length:8] mutableCopy]; [trailing appendBytes:"x" length:1];
    CHECK([P8JWT rawSignatureFromDER:trailing error:NULL] == nil, "signature trailing bytes must be rejected");
    NSString *base64=[[[[pem componentsSeparatedByString:@"-----BEGIN PRIVATE KEY-----"] lastObject] componentsSeparatedByString:@"-----END PRIVATE KEY-----"] firstObject];
    base64=[[base64 componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
    NSData *validDER=[[NSData alloc] initWithBase64EncodedString:base64 options:0];
    for (NSUInteger n=0; n<validDER.length; n++) {
        NSString *truncated=[NSString stringWithFormat:@"-----BEGIN PRIVATE KEY-----\n%@\n-----END PRIVATE KEY-----",[[validDER subdataWithRange:NSMakeRange(0,n)] base64EncodedStringWithOptions:0]];
        error=nil; CHECK([P8JWT tokenWithKeyID:@"K" teamID:@"T" privateKey:truncated date:[NSDate date] error:&error] == nil && error, "every truncated valid key must return error");
    }
    // Deterministic malformed-input corpus catches bounds and length overflow errors.
    uint32_t seed=123; for (NSUInteger n=0; n<2000; n++) {
        NSMutableData *data=[NSMutableData dataWithLength:n%150]; uint8_t *p=data.mutableBytes;
        for (NSUInteger j=0;j<data.length;j++){seed=seed*1664525+1013904223;p[j]=(uint8_t)(seed>>24);}
        [P8JWT rawSignatureFromDER:data error:NULL];
        NSString *bad=[NSString stringWithFormat:@"-----BEGIN PRIVATE KEY-----\n%@\n-----END PRIVATE KEY-----",[data base64EncodedStringWithOptions:0]];
        [P8JWT tokenWithKeyID:@"K" teamID:@"T" privateKey:bad date:[NSDate date] error:NULL];
    }
    NSString *device = [@"a" stringByPaddingToLength:64 withString:@"a" startingAtIndex:0];
    NSURLRequest *request = [APNsClient requestWithToken:@"jwt" topic:@"com.example.app" deviceToken:device payload:@"{\"aps\":{\"alert\":\"test\"}}" baseURL:@"https://api.sandbox.push.apple.com/3/device/" error:NULL];
    CHECK([request.HTTPMethod isEqual:@"POST"] && [request valueForHTTPHeaderField:@"authorization"] && [[request valueForHTTPHeaderField:@"apns-topic"] isEqual:@"com.example.app"] && [[request valueForHTTPHeaderField:@"apns-push-type"] isEqual:@"alert"] && request.HTTPBody.length, "request must contain APNs headers and payload");
    CHECK([request.URL.path hasSuffix:device], "request must address the supplied device");
    NSURLRequest *variableToken=[APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:@"aabbccdd" payload:@"{\"aps\":{}}" baseURL:@"https://example.com/3/device/" error:NULL];
    CHECK([variableToken.URL.path hasSuffix:@"aabbccdd"], "APNs device tokens must support variable byte lengths");
    CHECK([APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:@"abc" payload:@"{\"aps\":{}}" baseURL:@"https://example.com/" error:NULL] == nil, "incomplete token bytes must be rejected");
    for (NSString *payload in @[@"invalid",@"[]",@"{}",@"{\"aps\":[]}"]) {
        error=nil; CHECK([APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:device payload:payload baseURL:@"https://example.com/" error:&error] == nil && error, "invalid APNs payload must be rejected");
    }
    error=nil; CHECK([APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:@"bad/token" payload:@"{\"aps\":{}}" baseURL:@"https://example.com/" error:&error] == nil && error, "invalid device token must be rejected");
    error=nil; CHECK([APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:device payload:@"{\"aps\":{}}" baseURL:@"file:///tmp/" error:&error] == nil && error, "non HTTPS endpoint must be rejected");
    NSURLRequest *background=[APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:device payload:@"{\"aps\":{\"content-available\":1}}" baseURL:@"https://example.com/3/device" error:NULL];
    CHECK([[background valueForHTTPHeaderField:@"apns-push-type"] isEqual:@"background"] && [[background valueForHTTPHeaderField:@"apns-priority"] isEqual:@"5"], "silent push must use background type and priority 5");
    NSString *large=[NSString stringWithFormat:@"{\"aps\":{\"alert\":\"%@\"}}",[@"a" stringByPaddingToLength:4096 withString:@"a" startingAtIndex:0]];
    CHECK([APNsClient requestWithToken:@"jwt" topic:@"app" deviceToken:device payload:large baseURL:@"https://example.com/" error:NULL] == nil, "oversized payload must be rejected");
    for (NSNumber *status in @[@200,@400,@403,@410,@500]) {
        NSHTTPURLResponse *response=[[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:status.integerValue HTTPVersion:@"HTTP/2" headerFields:@{}];
        NSString *result=[APNsClient resultForResponse:response data:[@"{\"reason\":\"BadDeviceToken\"}" dataUsingEncoding:NSUTF8StringEncoding] error:NULL];
        CHECK(status.integerValue == 200 ? [result isEqual:@"发送成功"] : ([result containsString:status.stringValue] && [result containsString:@"BadDeviceToken"]), "HTTP status and APNs reason must determine result");
    }
    CHECK(![[APNsClient resultForResponse:nil data:nil error:NULL] isEqual:@"发送成功"], "missing response must never succeed");
    NSError *network=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    CHECK([[APNsClient resultForResponse:nil data:nil error:network] isEqual:network.localizedDescription], "transport errors must reach the user");
    fprintf(stderr,"%s (%d failures)\n",failures ? "FAILED" : "PASS", failures); return failures ? 1 : 0;
} }
