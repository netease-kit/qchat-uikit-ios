
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import Foundation
import NECoreIM2Kit
import NIMQChat
import NIMSDK

public protocol QChatServerProviderDelegate: NSObjectProtocol {
  func callBack()
}

@objcMembers
public class QChatServerProvider: NSObject, NIMQChatServerManagerDelegate {
  public static let shared = QChatServerProvider()
  private let mutiDelegate = MultiDelegate<QChatServerProviderDelegate>(strongReferences: false)

  override init() {
    super.init()
    NIMSDK.shared().qchatServerManager.add(self)
  }

  /// 创建社区
  public func createServer(param: NEQChatCreateServerParam,
                           _ completion: @escaping (NSError?, NEQChatCreateServerResult?) -> Void) {
    NIMSDK.shared().qchatServerManager.createServer(param.toIMParam()) { error, serverResult in
      completion(error as NSError?, NEQChatCreateServerResult(serverResult: serverResult))
    }
  }

  /// 查询社区信息
  public func getServers(param: NEQChatGetServersParam,
                         _ completion: @escaping (NSError?, NEQChatGetServersResult?) -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServers(param.toIMParam()) { error, getServersResult in
        completion(error as NSError?, NEQChatGetServersResult(serversResult: getServersResult))
      }
  }

  /// 查询社区列表
  public func getServerCount(param: NEQChatGetServersByPageParam,
                             _ completion: @escaping (NSError?, NEQChatGetServersByPageResult?)
                               -> Void) {
    print("getServers param timeTag:\(param.timeTag) \n limit:\(param.limit)")
    NIMSDK.shared().qchatServerManager.getServersByPage(param.toIMParam()) { error, result in
      print("getServers error:\(error) \n result:\(result)")
      completion(error as NSError?, NEQChatGetServersByPageResult(serversResult: result))
    }
  }

  /// 申请加入社区
  public func applyServerJoin(param: NEQChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatServerManager.applyServerJoin(param.toIMParam()) { error, result in
      completion(error as NSError?)
    }
  }

  /// 查询社区内成员信息
  public func getServerMembers(param: NEQChatGetServerMembersParam,
                               _ completion: @escaping (NSError?, NEQChatGetServerMembersResult?)
                                 -> Void) {
    NIMSDK.shared().qchatServerManager.getServerMembers(param.toIMParam()) { error, result in
      completion(error as NSError?, NEQChatGetServerMembersResult(memberData: result))
    }
  }

  /// 分页查询社区成员信息
  public func getServerMembersByPage(param: NEQChatGetServerMembersByPageParam,
                                     _ completion: @escaping (NSError?,
                                                              NEQChatGetServerMembersResult?)
                                       -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServerMembers(byPage: param.toIMParam()) { error, result in
        completion(error as NSError?, NEQChatGetServerMembersResult(membersResult: result))
      }
  }

  /// 邀请社区成员
  public func inviteMembersToServer(param: NEQChatInviteServerMembersParam,
                                    _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatServerManager
      .inviteServerMembers(param.toImParam()) { error, inviteResult in
        completion(error as NSError?)
      }
  }

  /// 邀请社区成员(携带成功失败列表)
  public func inviteMembersToServerWithResult(param: NEQChatInviteServerMembersParam,
                                              _ completion: @escaping (NSError?, [String]?, [String]?) -> Void) {
    NIMSDK.shared().qchatServerManager
      .inviteServerMembers(param.toImParam()) { error, inviteResult in
        completion(error as NSError?, inviteResult?.ultralimitFailedArray, inviteResult?.banedFailedArray)
      }
  }

  /// 修改社区信息
  public func updateServer(_ param: NEQChatUpdateServerParam, _ completion: @escaping (Error?, NIMQChatUpdateServerResult?) -> Void) {
    let imParam = param.toImParam()
    NIMSDK.shared().qchatServerManager.updateServer(param.toImParam()) { error, reuslt in
      completion(error, reuslt)
    }
  }

  /// 删除社区
  public func deleteServer(_ serverid: UInt64, _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatDeleteServerParam()
    param.serverId = serverid
    NIMSDK.shared().qchatServerManager.deleteServer(param) { error in
      completion(error)
    }
  }

  /// 主动离开社区
  public func leaveServer(_ serverId: UInt64?, _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatLeaveServerParam()
    if let sid = serverId {
      param.serverId = sid
    }
    NIMSDK.shared().qchatServerManager.leaveServer(param) { error in
      completion(error)
    }
  }

  /// 分页查询社区成员信息
  public func getServerMembers(_ param: NEQChatGetServerMembersByPageParam,
                               _ completion: @escaping (Error?, [NEQChatServerMemeber]) -> Void) {
    NIMSDK.shared().qchatServerManager
      .getServerMembers(byPage: param.toIMParam()) { error, result in
        var members = [NEQChatServerMemeber]()
        if let ms = result?.memberArray {
          for imMember in ms {
            let member = NEQChatServerMemeber(imMember)
            members.append(member)
          }
        }
        completion(error, members)
      }
  }

  /// 分页查询社区成员信息
  public func getServerMembers(param: NIMQChatGetServerMembersParam, _ completion: @escaping (Error?, [NIMQChatServerMember]?) -> Void) {
    NIMSDK.shared().qchatServerManager.getServerMembers(param) { error, result in
      completion(error, result?.memberArray)
    }
  }

  /// 修改社区成员信息
  public func updateMyServerMember(_ param: NEQChatUpdateMyMemberInfoParam,
                                   _ completion: @escaping (Error?, NEQChatServerMemeber) -> Void) {
    NIMSDK.shared().qchatServerManager.updateMyMemberInfo(param.toImParam()) { error, member in
      completion(error, NEQChatServerMemeber(member))
    }
  }

  /// 修改他人社区成员信息
  public func updateServerMember(_ param: NEQChatUpdateServerMemberInfoParam,
                                 _ completion: @escaping (Error?, NEQChatServerMemeber) -> Void) {
    NIMSDK.shared().qchatServerManager
      .updateServerMemberInfo(param.toImPara()) { error, member in
        completion(error, NEQChatServerMemeber(member))
      }
  }

  /// 踢除社区成员
  public func kickoutServerMembers(_ param: NEQChatKickServerMembersParam,
                                   _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatServerManager.kickServerMembers(param.toImParam()) { error in
      completion(error)
    }
  }

  /// 游客模式加入
  public func enterAsVisitor(_ param: NIMQChatEnterServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatEnterServerAsVisitorResult?) -> Void) {
    NIMSDK.shared().qchatServerManager.enter(asVisitor: param) { error, result in
      completion(error, result)
    }
  }

  /// 退出游客模式
  public func leaveAsVisitor(_ param: NIMQChatLeaveServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatLeaveServerAsVisitorResult?) -> Void) {
    NIMSDK.shared().qchatServerManager.leave(asVisitor: param) { error, result in
      completion(error, result)
    }
  }

  /// 游客模式订阅社区
  public func subscribeAsVisitor(_ param: NIMQChatSubscribeServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatSubscribeServerAsVisitorResult?) -> Void) {
    NIMSDK.shared().qchatServerManager.subscribe(asVisitor: param) { error, result in
      completion(error, result)
    }
  }

  // MARK: callback

  func callback() {
    mutiDelegate |> { delegate in
      delegate.callBack()
    }
  }

  public func addDelegate(delegate: QChatServerProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: QChatServerProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }
}
