//
//  YXRegisterViewController.h
//  YXLogin
//
//  Created by yu chen on 2021/11/8.
//

#import "YXBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^YXRegisterBlock)(NSString * _Nullable email);

@interface YXRegisterViewController : YXBaseViewController

@property (nonatomic, assign) BOOL isResetPW;

@property (nonatomic, strong) NSString *email;//忘记密码的邮箱账号，如果上一页面有输入，携带到找回密码页

@property (nonatomic, strong) YXRegisterBlock block;

@end

NS_ASSUME_NONNULL_END
