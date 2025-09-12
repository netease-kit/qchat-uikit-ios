
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatUpdateMemberRoleParam {
  public var serverId: UInt64?
  public var channelId: UInt64?
  public var accid: String?
  public var commands: [NEQChatPermissionStatusInfo]?

  public init(serverId: UInt64?, channelId: UInt64?, accid: String?,
              commands: [NEQChatPermissionStatusInfo]?) {
    self.serverId = serverId
    self.channelId = channelId
    self.accid = accid
    self.commands = commands
  }

  public func toIMParam() -> NIMQChatUpdateMemberRoleParam {
    let imParam = NIMQChatUpdateMemberRoleParam()
    imParam.serverId = serverId ?? 0
    imParam.channelId = channelId ?? 0
    imParam.accid = accid ?? ""
    if let cmds = commands {
      var tmp = [NIMQChatPermissionStatusInfo]()
      for c in cmds {
        let im = NIMQChatPermissionStatusInfo()
        im.customType = c.customType ?? 0
        if let status = NIMQChatPermissionStatus(rawValue: c.status.rawValue) {
          im.status = status
        }
        if let type = c.permissionType?.convertQCathPermissionType() {
          im.type = type
        }
        tmp.append(im)
      }
      imParam.commands = tmp
    }
    return imParam
  }
}
