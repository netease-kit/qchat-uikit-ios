//
//  YXBaseViewController.h
//  YXLogin
//
//  Created by yu chen on 2021/11/4.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>
#import <YYModel/YYModel.h>
#import <Toast/Toast.h>
#import "YXService.h"
#import "YXUserInfo.h"
#import "AuthorManager.h"
#import "ImageManager.h"
#import "LanguageManager.h"


NS_ASSUME_NONNULL_BEGIN

#define HEXCOLORA(rgbValue, alphaValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:alphaValue]

#define YXLocalizedString(key) \
[[LanguageManager shareInstance] localizableWithKey:(key)]

#define HEXCOLOR(rgbValue) HEXCOLORA(rgbValue, 1.0)

#define THEME_COLOR HEXCOLOR(0x337EFF)
#define THEME_COLOR_ALPHA HEXCOLORA(0x337EFF, 0.5)
#define NORMAL_MARGIN 30.0
#define COMMON_FONT [UIFont systemFontOfSize:15.0]
#define COMMON_CORNER 2.0

// 隐私政策URL
static NSString *kYXPrivatePolicyURL = @"https://reg.163.com/agreement_mobile_ysbh_wap.shtml?v=20171127";
// 用户协议URL
static NSString *kYXUserAgreementURL = @"http://yunxin.163.com/clauses";


@interface YXBaseViewController : UIViewController{
    @protected CGFloat space;
    @protected CGFloat factor;
    @protected CGFloat inputHeight;
}

@property (nonatomic, strong) UIButton *backBtn;

@property (nonatomic, strong) UILabel *timerLabel;

@property (nonatomic, strong) UIButton *codeBtn;

@property (nonatomic, strong) UITextView *textview;

- (void)showBack;

- (CGFloat)topHeight;

- (UITextField *)getCommonInput;

- (void)addLineAfterView:(UIView *)view withSpace:(CGFloat)space;

- (void)setSendStyle:(UILabel *)label;

- (void)setSendingStyle:(UILabel *)label;

- (void)startFigureoutTime;

- (void)showToast:(NSString *)conent;

- (void)showToastInWindow:(NSString *)content;

- (BOOL)isValidateEmail:(NSString *)email;

- (void)endFigureoutTime;

- (void)goBack;

@end

NS_ASSUME_NONNULL_END
