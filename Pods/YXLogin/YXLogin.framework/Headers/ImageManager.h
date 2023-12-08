//
//  ImageManager.h
//  YXLogin
//
//  Created by yu chen on 2021/12/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageManager : NSObject

+ (instancetype _Nullable )shareInstance;

- (UIImage *)loadImageFromName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
