#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface APNsClient : NSObject
+ (nullable NSURLRequest *)requestWithToken:(NSString *)token topic:(NSString *)topic deviceToken:(NSString *)device payload:(NSString *)payload baseURL:(NSString *)base error:(NSError * _Nullable * _Nullable)error;
+ (NSString *)resultForResponse:(nullable NSURLResponse *)response data:(nullable NSData *)data error:(nullable NSError *)error;
@end
NS_ASSUME_NONNULL_END
