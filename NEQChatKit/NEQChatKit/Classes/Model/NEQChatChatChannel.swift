
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatChatChannel {
  public var channelId: UInt64?
  public var serverId: UInt64?
  public var appId: Int?
  public var name: String?
  public var topic: String?
  public var visibleType: NEQChatChannelVisibleType?
  public var custom: String?
  public var type: NEQChatChannelType?
  public var validflag: Bool?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
  public init() {}

  init(channel: NIMQChatChannel?) {
    channelId = channel?.channelId
    serverId = channel?.serverId
    appId = channel?.appId
    name = channel?.name
    topic = channel?.topic
    custom = channel?.custom
    type = .messageType
    switch channel?.type {
    case .msg:
      type = .messageType
    case .custom:
      type = .customType
    default:
      type = .messageType
    }
    switch channel?.viewMode {
    case .public:
      visibleType = .isPublic
    case .private:
      visibleType = .isPrivate
    default:
      visibleType = .isPublic
    }

    validflag = channel?.validflag
    createTime = channel?.createTime
    updateTime = channel?.updateTime
  }
}
