#import "APNsClient.h"
static NSURLRequest *Invalid(NSError **error, NSString *message) {
    if (error) *error=[NSError errorWithDomain:@"PushWithP8.APNs" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
    return nil;
}
@implementation APNsClient
+ (NSURLRequest *)requestWithToken:(NSString *)token topic:(NSString *)topic deviceToken:(NSString *)device payload:(NSString *)payload baseURL:(NSString *)base error:(NSError **)error {
    if (!token.length || !topic.length) return Invalid(error,@"JWT 和 Bundle ID 不能为空");
    NSCharacterSet *nonHex=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] invertedSet];
    if ((!device.length || device.length % 2 != 0) || [device rangeOfCharacterFromSet:nonHex].location != NSNotFound) return Invalid(error,@"DeviceToken 需要完整的十六进制字节串");
    NSData *body=[payload dataUsingEncoding:NSUTF8StringEncoding];
    id json=body ? [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL] : nil;
    if (![json isKindOfClass:NSDictionary.class] || ![json[@"aps"] isKindOfClass:NSDictionary.class]) return Invalid(error,@"Payload 需要包含 aps 对象的 JSON");
    NSDictionary *aps=json[@"aps"];
    BOOL background=![aps objectForKey:@"alert"] && ![aps objectForKey:@"sound"] && ![aps objectForKey:@"badge"] && [aps[@"content-available"] isEqual:@1];
    if (body.length > 4096) return Invalid(error,@"Payload 不能超过 4096 字节");
    NSURLComponents *components=[NSURLComponents componentsWithString:base];
    if (![components.scheme.lowercaseString isEqual:@"https"] || !components.host.length || components.user || components.password || components.query || components.fragment) return Invalid(error,@"推送地址需要有效的 HTTPS URL，且不含账号、查询参数或片段");
    components.path=[components.path stringByAppendingFormat:@"%@%@",[components.path hasSuffix:@"/"] ? @"" : @"/",device];
    NSURL *url=components.URL; if (!url) return Invalid(error,@"推送地址无效");
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod=@"POST"; request.HTTPBody=body; request.timeoutInterval=30;
    [request setValue:[@"bearer " stringByAppendingString:token] forHTTPHeaderField:@"authorization"];
    [request setValue:topic forHTTPHeaderField:@"apns-topic"];
    [request setValue:background ? @"background" : @"alert" forHTTPHeaderField:@"apns-push-type"];
    [request setValue:background ? @"5" : @"10" forHTTPHeaderField:@"apns-priority"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    return request;
}
+ (NSString *)resultForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
    if (error) return error.localizedDescription;
    if (![response isKindOfClass:NSHTTPURLResponse.class]) return @"未知错误：未收到 HTTP 响应";
    NSInteger status=((NSHTTPURLResponse *)response).statusCode;
    if (status == 200) return @"发送成功";
    id json=data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
    NSString *reason=[json isKindOfClass:NSDictionary.class] && [json[@"reason"] isKindOfClass:NSString.class] ? json[@"reason"] : nil;
    return [NSString stringWithFormat:@"发送失败（HTTP %ld）%@%@",(long)status,reason.length ? @"：" : @"",reason ?: @""];
}
@end
