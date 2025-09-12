
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public enum NEQChatChannelRoleType {
  case everyone
  case custom
}

public struct NEQChatChannelRole {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var parentRoleId: UInt64?
  public var channelId: UInt64?
  public var name: String?
  public var type: NEQChatChannelRoleType?
  public var icon: String?

  public var ext: String?
  public var auths: [NEQChatPermissionStatusInfo]?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
  public init() {}

  init(role: NIMQChatChannelRole?) {
    serverId = role?.serverId
    roleId = role?.roleId
    parentRoleId = role?.parentRoleId
    channelId = role?.channelId
    name = role?.name

    type = role?.type == .custom ? .custom : .everyone
    icon = role?.icon
    ext = role?.ext

    createTime = role?.createTime
    updateTime = role?.updateTime
    guard let authl = role?.auths else {
      return
    }
    var authList: [NEQChatPermissionStatusInfo] = []
    for auth in authl {
      authList.append(NEQChatPermissionStatusInfo(info: auth))
      auths = authList
    }
  }
}
