#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface P8JWT : NSObject
+ (nullable NSString *)tokenWithKeyID:(NSString *)keyID
                             teamID:(NSString *)teamID
                         privateKey:(NSString *)pem
                               date:(NSDate *)date
                              error:(NSError * _Nullable * _Nullable)error;
+ (nullable NSData *)rawSignatureFromDER:(NSData *)der error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
