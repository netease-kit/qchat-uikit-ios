// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef NECallEngineConsts_h
#define NECallEngineConsts_h

@class NERtcCallKitPushConfig;
@class NERtcCallKitContext;

typedef NS_OPTIONS(NSUInteger, NECallType) {
  NECallTypeAudio = 1,  /// 音频
  NECallTypeVideo = 2,  /// 视频
};

typedef NS_ENUM(NSUInteger, NECallSwitchState) {
  NECallSwitchStateInvite = 1,  /// 邀请
  NECallSwitchStateAgree = 2,   /// 接受
  NECallSwitchStateReject = 3,  /// 拒绝
};

typedef NS_ENUM(NSUInteger, NECallEngineStatus) {
  NECallStatusIdle = 0,  /// 闲置
  NECallStatusCalling,   /// 呼叫中
  NECallStatusCalled,    /// 正在被呼叫
  NECallStatusInCall,    /// 通话中
};

typedef NS_ENUM(NSUInteger, NERtcCallStatus) {
  NERtcCallStatusIdle = 0,  /// 闲置
  NERtcCallStatusCalling,   /// 呼叫中
  NERtcCallStatusCalled,    /// 正在被呼叫
  NERtcCallStatusInCall,    /// 通话中
};

typedef NS_ENUM(NSInteger, NERtcCallTerminalCode) {
  TerminalCodeNormal = 0,            /// 正常流程
  TerminalCodeTokenError,            /// token 请求失败
  TerminalCodeTimeOut,               /// 超时
  TerminalCodeBusy,                  /// 用户占线
  TerminalCodeRtcInitError,          /// rtc 初始化失败
  TerminalCodeJoinRtcError,          /// 加入rtc失败
  TerminalCodeCancelErrorParam,      /// cancel 取消参数错误
  TerminalCodeCallFailed,            /// 发起呼叫失败
  TerminalCodeKicked,                /// 账号被踢
  TerminalCodeEmptyUid,              ///  uid 为空
  TerminalRtcDisconnected = 10,      ///  Rtc 断连
  TerminalCallerCancel = 11,         /// 取消呼叫
  TerminalCalleeCancel = 12,         /// 呼叫被取消
  TerminalCalleeReject = 13,         /// 拒绝呼叫
  TerminalCallerRejcted = 14,        /// 呼叫被拒绝
  TerminalHuangUp = 15,              /// 挂断呼叫
  TerminalBeHuangUp = 16,            /// 呼叫被挂断
  TerminalOtherRejected = 17,        /// 多端登录被其他端拒绝
  TerminalOtherAccepted = 18,        /// 多端登录被其他端接听
  TerminalUserRtcDisconnected = 19,  /// Rtc房间断开链接
  TerminalUserRtcLeave = 20,         /// 离开Rtc房间
  TerminalAcceptFail = 21,           /// 接听失败
};

typedef NS_OPTIONS(NSUInteger, NERtcCallType) {
  NERtcCallTypeAudio = 1,  /// 音频
  NERtcCallTypeVideo = 2,  /// 视频
};

typedef NS_ENUM(NSUInteger, NERtcSwitchState) {
  NERtcSwitchStateInvite = 1,  /// 邀请
  NERtcSwitchStateAgree = 2,   /// 接受
  NERtcSwitchStateReject = 3,  /// 拒绝
};

typedef NS_ENUM(NSUInteger, NECallInitRtcMode) {
  GlobalInitRtc = 1,  // 全局初始化一次
  InitRtcInNeed,  // 主叫呼叫以及被叫接收到呼叫邀请时候初始化，结束通话后销毁Rtc
  InitRtcInNeedDelayToAccept,  // 被叫初始化Rtc延迟到 accept 执行
};

typedef NS_ENUM(NSInteger, NECallEngineErrorCode) {
  CurrentStatusNotSupport = 20026  // 当前状态不支持
};

typedef void (^NERtcCallKitTokenHandler)(uint64_t uid, NSString *channelName,
                                         void (^complete)(NSString *token, NSError *error));

typedef void (^NERtcCallKitPushConfigHandler)(NERtcCallKitPushConfig *config,
                                              NERtcCallKitContext *context);

#define kNERtcCallKitBusyCode @"601"

static const NSUInteger kNERtcCallKitMaxTimeOut = 2 * 60;

#endif /* NECallEngineConsts_h */
