
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatUpdateServerParam {
  public var serverId: UInt64?
  // 名称，必填
  public var name: String?

  public var icon: String?

  public var custom: String?
  // 邀请模式
  public var inviteMode: NEQChatServerInviteMode?
  // 申请模式
  public var applyMode: NEQChatServerApplyMode?

  public init(name: String?, icon: String?) {
    self.name = name
    self.icon = icon
  }

  public func toImParam() -> NIMQChatUpdateServerParam {
    let imParam = NIMQChatUpdateServerParam()
    if let n = name {
      imParam.name = n
    }
    if let i = icon {
      imParam.icon = i
    }
    if let sid = serverId {
      imParam.serverId = sid
    }
    if let c = custom {
      imParam.custom = c
    }
    switch inviteMode {
    case .autoEnter:
      imParam.inviteMode = 1
    default:
      imParam.inviteMode = 0
    }

    switch applyMode {
    case .needApprove:
      imParam.applyMode = 1
    default:
      imParam.applyMode = 0
    }
    return imParam
  }
}
