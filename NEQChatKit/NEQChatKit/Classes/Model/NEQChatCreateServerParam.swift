
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

// 邀请模式
public enum NEQChatServerInviteMode {
  case needApprove // 需要同意
  case autoEnter // 不需要同意
}

// 申请模式
public enum NEQChatServerApplyMode {
  case autoEnter // 不需要同意
  case needApprove // 需要同意
}

public struct NEQChatCreateServerParam {
  // 名称，必填
  public var name: String?

  public var icon: String?

  public var custom: String?
  // 邀请模式
  public var inviteMode: NEQChatServerInviteMode = .autoEnter
  // 申请模式
  public var applyMode: NEQChatServerApplyMode?

  public init(name: String, icon: String) {
    self.name = name
    self.icon = icon
  }

  public func toIMParam() -> NIMQChatCreateServerParam {
    let imParam = NIMQChatCreateServerParam()
    imParam.name = name
    imParam.icon = icon
    imParam.custom = custom
    switch inviteMode {
    case .autoEnter:
      imParam.inviteMode = NIMQChatServerInviteMode.autoEnter
    case .needApprove:
      imParam.inviteMode = NIMQChatServerInviteMode.needApprove
    }

    switch applyMode {
    case .needApprove:
      imParam.applyMode = NIMQChatServerApplyMode.needApprove
    case .autoEnter:
      imParam.applyMode = NIMQChatServerApplyMode.autoEnter
    default:
      break
    }
    return imParam
  }

  public func toIMUpdateParam() -> NIMQChatUpdateServerParam {
    let imParam = NIMQChatUpdateServerParam()
    imParam.name = name
    imParam.icon = icon
    imParam.custom = custom
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
