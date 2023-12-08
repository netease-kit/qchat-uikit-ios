//
//  AuthorServiceProtocol.h
//  Pods
//
//  Created by yu chen on 2021/11/3.
//

#import "YXConfig.h"
#import "YXUserInfo.h"

typedef void (^YXLoginTaskResultBlock)(YXUserInfo *_Nullable userinfo, NSError * _Nullable error);

@protocol AuthorServiceProtocol <NSObject>

- (void)initAuthorWithConfig:(YXConfig *_Nullable)config;

- (YXUserInfo *_Nullable)getUserInfo;

//业务层登录成功
- (BOOL)isLogin;

// 包括IM登录成功失败判断
- (BOOL)isLoginWithIM;

- (BOOL)canAutologin;

// 先展示logo页面再由用户点击进入登录注册页面
- (void)startEntranceWithCompletion:(YXLoginTaskResultBlock _Nonnull)block;

- (void)startLoginWithCompletion:(YXLoginTaskResultBlock _Nonnull)block;

- (void)autoLoginWithCompletion:(YXLoginTaskResultBlock _Nonnull )block;

- (void)logoutWithCompletion:(YXLoginTaskResultBlock _Nonnull )block;

- (void)logoutWithConfirm:(NSString *_Nullable )confifirText withCompletion:(YXLoginTaskResultBlock _Nonnull)block;

@end
