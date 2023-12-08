//
//  V2NIMStorageServiceProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2023 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "V2NIMBase.h"

@class V2NIMStorageScene;

NS_ASSUME_NONNULL_BEGIN

/// 登录协议
@protocol V2NIMStorageService <NSObject>
/**
 *  添加自定义存储场景
 *
 *  @param sceneName 场景名
 *  @param expireTime 过期时间， 单位秒
 */
- (void)addCustomStorageScene:(NSString *)sceneName expireTime:(NSUInteger)expireTime;

@end
/// 文件存储场景
@interface V2NIMStorageScene : NSObject
/// 场景名
@property (nullable,nonatomic,strong) NSString *sceneName;
/// 过期时间， 单位秒
/// 0表示永远不过期,否则以该时间为过期时间
@property (nonatomic,assign) NSUInteger expireTime;

@end

/// 文件存储场景
@interface V2NIMStorageSceneConfig : NSObject

/// 默认头像类型等场景, 默认不过期
+ (V2NIMStorageScene *)DEFAULT_PROFILE;
/// 默认文件类型等场景, 默认不过期
+ (V2NIMStorageScene *)DEFAULT_IM;
/// 默认日志类型等场景, 默认不过期
+ (V2NIMStorageScene *)DEFAULT_SYSTEM;
/// 安全链接，每次大家需要密钥才能查看,默认不过期
+ (V2NIMStorageScene *)SECURITY_LINK;
@end

NS_ASSUME_NONNULL_END
