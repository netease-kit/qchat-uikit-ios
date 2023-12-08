//
//  LanguageManager.h
//  YXLogin
//
//  Created by yu chen on 2021/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LanguageManager : NSObject

+ (instancetype _Nullable )shareInstance;

- (NSString *)localizableWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
