

//
//  NIMQChatEnterServerAsVisitorParam.h
//  NIMSDK
//
//  Created by Netease.
//  Copyright © 2022 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  设置以游客身份加入服务器的参数
 */
@interface NIMQChatEnterServerAsVisitorParam : NSObject <NSCopying>

/**
 * 圈组服务器ID列表
 */
@property (nonatomic, copy, nonnull) NSArray<NSNumber *> *serverIds;
@end


NS_ASSUME_NONNULL_END


