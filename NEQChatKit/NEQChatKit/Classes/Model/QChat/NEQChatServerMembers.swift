
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

extension NIMQChatServerMemberType {
  func convertMeberType() -> NEQChatServerMemberType? {
    switch self {
    case .common:
      return NEQChatServerMemberType.common
    case .owner:
      return NEQChatServerMemberType.owner
    @unknown default:
      return nil
    }
  }
}

public struct NEQChatAddServerRoleMemberParam {
  public var serverId: UInt64?

  public var roleId: UInt64?

  public var accountArray: [String]?

  public init() {}

  func toImParam() -> NIMQChatAddServerRoleMembersParam {
    let param = NIMQChatAddServerRoleMembersParam()
    if let rid = roleId {
      param.roleId = rid
    }
    if let sid = serverId {
      param.serverId = sid
    }
    if let array = accountArray {
      param.accountArray = array
    }
    return param
  }
}

public struct NEQChatServerMemeber: Equatable {
  /**
   * 服务器id
   */
  public var serverId: UInt64?

  /**
   * 应用id
   */
  public var appId: Int?

  /**
   * 用户accid
   */
  public var accid: String?

  /**
   * 昵称
   */
  public var nick: String?

  /**
   * 头像
   */
  public var avatar: String?

  /**
   * 邀请人
   */
  public var inviter: String?

  /**
   * 自定义扩展
   */
  public var custom: String?

  /**
   * 类型：0-普通成员，1-所有者
   */
  public var type: NEQChatServerMemberType?

  /**
   * 加入时间
   */
  public var joinTime: Double?

  /**
   * 有效标志： 0-无效，1-有效
   */
  public var validFlag: Bool?

  /**
   * 创建时间
   */
  public var createTime: Double?

  /**
   * 更新时间
   */
  public var updateTime: Double?

  /**
   * QChat层扩展字段
   */
  public var imName: String = ""

  /**
   * QChat层扩展字段(身份组列表)
   */
  public var roles: [NEQChatServerRole]?

  public init(_ member: NIMQChatServerMember?) {
    print("member : ", member?.description as Any)
    serverId = member?.serverId
    appId = member?.appId
    accid = member?.accid
    nick = member?.nick
    avatar = member?.avatar
    inviter = member?.inviter
    custom = member?.custom
    type = member?.type.convertMeberType()
    joinTime = member?.joinTime
    validFlag = member?.validFlag
    createTime = member?.createTime
    updateTime = member?.updateTime
  }

  public init() {}

  public static func == (lhs: NEQChatServerMemeber, rhs: NEQChatServerMemeber) -> Bool {
    lhs.accid == rhs.accid
  }
}
