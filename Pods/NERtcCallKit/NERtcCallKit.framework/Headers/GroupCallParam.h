// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupPushParam : NSObject

/**
  推送模式{@link GroupHeader => GroupPushMode },默认开启
 */
@property(nonatomic, assign) NSInteger pushMode;

// 推送文案，最长 500 个字符。
@property(nonatomic, strong) NSString *pushContent;

// 推送对应的 payload，必须是 JSON 格式且不能超过 2000 字符。
@property(nonatomic, strong) NSString *payload;

// 客户端本地的声音文件名，长度不要超过 30 个字符。
@property(nonatomic, strong) NSString *sound;

@end

@interface GroupCallParam : NSObject

/// 多人通话唯一识别id
@property(nonatomic, strong) NSString *callId;

/// 被邀请的群成员列表
@property(nonatomic, strong) NSArray<NSString *> *calleeList;

@property(nonatomic, strong) NSString *groupId;

/**
  群类型{@link GroupHeader => GroupType }
 */
@property(nonatomic, assign) NSInteger groupType;

/**
  邀请模式{@link GroupHeader => GroupInviteMode }
 */
@property(nonatomic, assign) NSInteger inviteMode;

/**
  加入模式{@link GroupHeader => GroupJoinMode }
 */
@property(nonatomic, assign) NSInteger joinMode;

@property(nonatomic, strong) NSString *extraInfo;

@property(nonatomic, strong) GroupPushParam *pushParam;

@end

@interface GroupHangupParam : NSObject

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, assign) NSInteger reason;

@end

@interface GroupAcceptParam : NSObject

@property(nonatomic, strong) NSString *callId;

@end

@interface GroupInviteParam : NSObject

@property(nonatomic, strong) NSString *callId;

@property(nonatomic, strong) NSArray<NSString *> *calleeList;

@end

@interface GroupJoinParam : NSObject

@property(nonatomic, strong) NSString *callId;

@end

@interface GroupQueryCallInfoParam : NSObject

@property(nonatomic, strong) NSString *callId;

@end

@interface GroupQueryMembersParam : NSObject

@property(nonatomic, strong) NSString *callId;

@end

@interface GroupConfigParam : NSObject

@property(nonatomic, strong) NSString *host;

/// 是否开启安全模式，默认NO 不开启
@property(nonatomic, assign) BOOL rtcSafeMode;

/// appkey 或  appid
@property(nonatomic, strong) NSString *appid;

@end

NS_ASSUME_NONNULL_END
