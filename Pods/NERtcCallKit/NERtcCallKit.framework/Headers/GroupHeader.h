// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef GroupHeader_h
#define GroupHeader_h

typedef NS_ENUM(NSUInteger, GroupInviteMode) {
  AnyoneInviteMode = 0,  // 任何人可以邀请
  OwnerInviteMode = 1    // 发起者才能邀请
};

typedef NS_ENUM(NSUInteger, GroupJoinMode) {
  JoinModeAnyone = 0,  // 任何人都可以加入群聊通话
  JoinModeInvited = 1  // 只能被邀请
};

typedef NS_ENUM(NSUInteger, GroupType) {
  GroupTypeDiscussion = 1,  // 讨论组
  GroupTypeSenior = 2,      // 高级群
  GroupTypeChatroom = 3     // 聊天室
};

typedef NS_ENUM(NSInteger, GroupMemberState) {
  GroupMemberStateWaitting = 1,   // 等待接听
  GroupMemberStateInChannel = 2,  // 已经在房间中
  GroupMemberStateHangup = 3,     // 用户已经挂断
  GroupMemberStateAccept = 4,     // 已接收邀请但未在rtc通道中
};

typedef NS_ENUM(NSInteger, GroupPushMode) {
  GroupPushModeClose = 0,  // 关闭
  GroupPushModeOpen = 1,   // 开启
  GroupPushModeForce = 2,  // 强制推送
};

#pragma mark - 用户行为
// 用户接受邀请
static NSString *kActionAccept = @"accept";
// 用户拒绝邀请
static NSString *kActionReject = @"reject";
// 用户离开
static NSString *kActionLeave = @"leave";
// 用户加入
static NSString *kActionJoin = @"join";

#pragma mark - 挂断原因
// 超时
static NSString *kReasonTimeout = @"timeout";
// 忙线
static NSString *kReasonBusy = @"busy";
// 其他端接听
static NSString *kReasonPeerAccept = @"peerAccept";
// 其他端拒绝
static NSString *kReasonPeerReject = @"peerReject";

#endif /* GroupHeader_h */
