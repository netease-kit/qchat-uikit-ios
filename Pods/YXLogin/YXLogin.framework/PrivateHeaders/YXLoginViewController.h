//
//  LoginViewController.h
//  YXLogin
//
//  Created by yu chen on 2021/11/2.
//

#import <UIKit/UIKit.h>
#import "YXBaseViewController.h"
#import "YXConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXLoginViewController : YXBaseViewController

@property(nonatomic, assign) BOOL isShowBackBtn;

@property(nonatomic, assign) YXLoginType type;

@end

NS_ASSUME_NONNULL_END
