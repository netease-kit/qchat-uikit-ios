//
//  NIMQChatEnterServerAsVisitorResult.h
//  NIMLib
//
//  Created by NetEase on 2022/3/22.
//  Copyright © 2022 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * 以游客身份加入服务器的结果
 */
@interface NIMQChatEnterServerAsVisitorResult : NSObject <NSCopying>
/**
 * 加入失败的服务器的ID列表
 */
@property (nonatomic, nullable, readonly, copy) NSArray<NSNumber *>* failedServerIds;
@end

NS_ASSUME_NONNULL_END
