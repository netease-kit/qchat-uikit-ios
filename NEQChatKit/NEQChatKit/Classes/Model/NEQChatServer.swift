
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreKit
import NIMQChat

@objcMembers
public class NEQChatServer: NSObject {
  public var serverId: UInt64?
  public var appId: NSInteger?
  public var name: String?
  public var icon: String?
  public var custom: String?
  public var owner: String?
  public var memberNumber: NSInteger?
  public var inviteMode: NEQChatServerInviteMode?
  public var applyMode: NEQChatServerApplyMode?
  public var validFlag: Bool?
  public var createTime: TimeInterval?
  public var updateTime: TimeInterval?
  public var hasUnread = false
  /// 初始化时无值，需要外部根据未读数变更回调赋值
  public var unreadCount: UInt = 0

  /// 是否是游客模式，默认非游客模式，外部根据业务层数据处理
  public var isVisitorMode = false

  public var topic: String?

  public var announce: NEQChatAnnounceModel?

  public init(server: NIMQChatServer?) {
    super.init()
    serverId = server?.serverId
    appId = server?.appId
    name = server?.name
    icon = server?.icon?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    custom = server?.custom
    owner = server?.owner
    memberNumber = server?.memberNumber ?? 0
    switch server?.inviteMode {
    case .autoEnter:
      inviteMode = .autoEnter
    case .needApprove:
      inviteMode = .needApprove
    default:
      inviteMode = .needApprove
    }

    switch server?.applyMode {
    case .autoEnter:
      applyMode = .autoEnter
    case .needApprove:
      applyMode = .needApprove
    default:
      applyMode = .autoEnter
    }

    validFlag = server?.validFlag
    createTime = server?.createTime
    updateTime = server?.updateTime
    parseCustom()
  }

  public func copyFromModel(server: NEQChatServer?) {
    serverId = server?.serverId
    appId = server?.appId
    name = server?.name
    icon = server?.icon?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    custom = server?.custom
    owner = server?.owner
    memberNumber = server?.memberNumber ?? 0
    switch server?.inviteMode {
    case .autoEnter:
      inviteMode = .autoEnter
    case .needApprove:
      inviteMode = .needApprove
    default:
      inviteMode = .needApprove
    }

    switch server?.applyMode {
    case .autoEnter:
      applyMode = .autoEnter
    case .needApprove:
      applyMode = .needApprove
    default:
      applyMode = .autoEnter
    }

    validFlag = server?.validFlag
    createTime = server?.createTime
    updateTime = server?.updateTime
    parseCustom()
  }

  public func convertUpdateServerParam() -> NEQChatUpdateServerParam? {
    var param = NEQChatUpdateServerParam(name: name ?? "", icon: icon)
    param.serverId = serverId
    param.inviteMode = inviteMode
    param.applyMode = applyMode
    param.custom = custom
    return param
  }

  func parseCustom() {
    guard let customString = custom else {
      return
    }
    guard let dic = NECommonUtil.getDictionaryFromJSONString(customString) as? [String: AnyObject] else {
      return
    }
    if let topicStr = dic["topic"] as? String {
      topic = topicStr
    }
    if let announceDic = dic["announce"] as? NSDictionary {
      if let model = NEQChatAnnounceModel.yx_model(withJSON: announceDic) {
        announce = model
      }
    }
  }
}
