//
//  V2NIMTeamServiceProtocol.h
//  NIMLib
//
//  Created by Netease.
//  Copyright (c) 2023 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "V2NIMBase.h"

NS_ASSUME_NONNULL_BEGIN

@protocol V2NIMTeamListener;

/// 群协议
@protocol V2NIMTeamService <NSObject>

/**
 *  添加群监听
 *
 *  @param listener
 */
- (void)addTeamListener:(id<V2NIMTeamListener>)listener;

/**
 *  移除群监听
 *
 *  @param listener
 */
- (void)removeTeamListener:(id<V2NIMTeamListener>)listener;

@end

/// 群回调协议
@protocol V2NIMTeamListener <NSObject>

@optional

@end

NS_ASSUME_NONNULL_END
