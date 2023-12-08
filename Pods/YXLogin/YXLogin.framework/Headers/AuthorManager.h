//
//  AuthorManager.h
//  YXLogin
//
//  Created by yu chen on 2021/11/3.
//

#import <Foundation/Foundation.h>
#import "AuthorServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kYXLoginSuccessNoti;

extern NSString * const kYXLogoutSuccessNoti;

@interface AuthorManager : NSObject<AuthorServiceProtocol>

@property (nonatomic, assign) BOOL imLoginSuccess;

@property (nonatomic, assign, readonly) BOOL isOnline;

+ (instancetype _Nullable )shareInstance;

- (BOOL)isChinese;

@end

NS_ASSUME_NONNULL_END
