//
//  YXConfig.h
//  YXLogin
//
//  Created by yu chen on 2021/11/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YXLoginType){
    YXLoginALL,
    YXLoginPhone,
    YXLoginEmail,
};

@interface YXConfig : NSObject

@property(nonatomic, strong) NSString *appKey;
@property(nonatomic, strong) NSNumber *parentScope; //行业线
@property(nonatomic, strong) NSNumber *scope;       //行业线内的具体demo
@property(nonatomic, assign) BOOL isOnline;
@property(nonatomic, assign) YXLoginType type;
@property(nonatomic, assign) BOOL supportInternationalize; //支持根据系统语言自动切换邮箱手机号登录，中文: 手机号  非中文: 邮箱，默认 YES 开启
@end

NS_ASSUME_NONNULL_END
