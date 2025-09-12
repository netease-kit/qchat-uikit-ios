
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatServerRole {
  public var serverId: UInt64?
  public var roleId: UInt64?
  public var name: String?
  public var type: NEQChatChannelRoleType?
  public var icon: String?

  public var ext: String?
  public var auths: [NEQChatPermissionStatusInfo]?
  public var channelAuths: [NEQChatPermissionStatusInfo]?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
//    public var priority: Int32?
  public var memberCount: Int?

//    public var isMember = false

  public var priority: Int?

  public init(_ role: NIMQChatServerRole?) {
    serverId = role?.serverId
    roleId = role?.roleId
    name = role?.name
    memberCount = role?.memberCount
    type = role?.type == .custom ? .custom : .everyone
    icon = role?.icon
    ext = role?.ext
    priority = role?.priority.intValue
    createTime = role?.createTime
    updateTime = role?.updateTime

    var authList = [NEQChatPermissionStatusInfo]()
    channelAuths = [NEQChatPermissionStatusInfo]()

    role?.auths.forEach { info in
      authList.append(NEQChatPermissionStatusInfo(info: info))
      channelAuths?.append(NEQChatPermissionStatusInfo(info: info))
    }

    if authList.count > 0 {
      auths = authList
    }

//        if let member = role?.isMember {
//            isMember = member
//        }
  }
}
