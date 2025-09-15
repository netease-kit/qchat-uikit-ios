//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public let qChatKitVersion = "10.0.1" // qChatKit 版本号, 用于埋点上报

// 圈组撤回消息标识符
public let revokeMessageFlag = "revoke_message_qchat"

// 圈组撤回消息内容
public let revokeMessageContent = "revoke_message_content_qchat"

// 圈组删除消息标识符
public let deleteMessageFlag = "delete_message_qchat"

// 圈组表情评论数量限制
public let emojiCommentLimit = 50

// 圈组表情评论权限 type
public let emojiAuthType = 10001

// Error Code
public let errorCode_TimeOut = 508
public let errorCode_NetWorkError = 408
public let errorCode_NoPermission = 403
public let errorCode_NoExist = 404
public let errorCode_Existed = 417
