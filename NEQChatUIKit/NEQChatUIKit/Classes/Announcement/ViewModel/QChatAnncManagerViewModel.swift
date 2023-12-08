//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

public protocol QChatAnncManagerViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
  func didNeedBack()
}

@objcMembers
public class QChatAnncManagerViewModel: NSObject, NIMQChatMessageManagerDelegate {
  let repo = QChatRepo.shared
  var managerMembers = [ServerMemeber]()
  var normalMembers = [ServerMemeber]()
  var limit = 100
  var isControllerShow = true // 判断当前controller是否显示

  var lastTimeTag: Double = 0

  var qchatServer: QChatServer?

  var hasPermission = false // 是否有权限移除订阅者，订阅者列表使用

  var allMemberMark = Set<String>()

  public weak var delegate: QChatAnncManagerViewModelDelegate?

  override public init() {
    super.init()
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  public func inviteMembersToServer(serverId: UInt64, accids: [String],
                                    _ completion: @escaping (NSError?, [String]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    let param = QChatInviteServerMembersParam(serverId: serverId, accids: accids)

    repo.inviteMembersToServerWithResult(param: param) { error, failedIds, bandedFialedIds in
      completion(error, failedIds)
    }
  }

  func getManagerMembers(_ roleId: UInt64?, _ serverId: UInt64?, _ owner: String?, _ isLoadMore: Bool = false, _ timeTag: Double = 0, _ completion: @escaping (NSError?, Bool) -> Void) {
    var param = GetServerRoleMembersParam()
    param.serverId = serverId
    param.roleId = roleId
    param.limit = limit
    param.timeTag = timeTag
    if managerMembers.count > 1 {
      if let last = managerMembers.last {
        param.accid = last.accid
      }
    }
    // 是否还有更多数据
    var isNoMoreData = false
    repo.getServerRoleMembers(param) { [weak self] error, members in
      if let err = error {
        completion(err as NSError, isNoMoreData)
      } else {
        self?.getServerMember(roleMembers: members, owner, serverId, isLoadMore) { [weak self] error, serverMembers in
          if let err = error {
            completion(err as NSError, isLoadMore)
          } else {
            if serverMembers.count <= 0 {
              isNoMoreData = true
            }
            self?.managerMembers.append(contentsOf: serverMembers)
            completion(nil, isNoMoreData)
          }
        }
      }
    }
  }

  func getServerMember(roleMembers: [RoleMember]?, _ owner: String?, _ serverId: UInt64?, _ isLoadMore: Bool = false, _ completion: @escaping (NSError?, [ServerMemeber]) -> Void) {
    var memberItems = [QChatGetServerMemberItem]()

    // 把创建者放在管理员第一个
    if isLoadMore == false, let accid = owner, let sid = serverId {
      let item = QChatGetServerMemberItem(serverId: sid, accid: accid)
      memberItems.append(item)
    }

    var retMembers = [ServerMemeber]()

    roleMembers?.forEach { member in
      retMembers.append(member.convertToServerMember())
    }
    if isLoadMore {
      completion(nil, retMembers)
      return
    }
    let param = QChatGetServerMembersParam(serverAccIds: memberItems)
    repo.getServerMembers(param: param) { error, members in
      if let err = error {
        completion(err as NSError, retMembers)
      } else {
        if let ownerMember = members?.first {
          retMembers.insert(ownerMember, at: 0)
        }
        completion(nil, retMembers)
      }
    }
  }

  func getMemberWithRoles(_ serverId: UInt64?, _ timeTag: Double?,
                          _ completion: @escaping (NSError?, [ServerMemeber]?, Bool) -> Void) {
    var param = GetServerMembersByPageParam()
    param.limit = limit
    param.serverId = serverId
    param.timeTag = timeTag

    var isNoMoreData = false
    repo.getServerMembers(param) { [weak self] error, members in

      if error == nil {
        if members.count < self?.limit ?? 0 {
          isNoMoreData = true
        }
        let memberArr = members
        var accidList = [String]()
        var dic = [String: ServerMemeber]()

        for memberModel in memberArr {
          accidList.append(memberModel.accid ?? "")
          if let accid = memberModel.accid {
            dic[accid] = memberModel
            self?.allMemberMark.insert(accid)
          }
        }

        let roleParam = QChatGetExistingAccidsInServerRoleParam(
          serverId: param.serverId!,
          accids: accidList
        )
        self?.repo.getExistingServerRolesByAccids(roleParam) { error, serverRolesDict in
          serverRolesDict?.forEach { key, roleArray in
            dic[key]?.roles = roleArray
          }
          var tempServerArray = [ServerMemeber]()
          for var memberModel in memberArr {
            if let accid = memberModel.accid, let dicMember = dic[accid] {
              memberModel.roles = dicMember.roles
              memberModel.imName = dicMember.imName
              tempServerArray.append(memberModel)
            }
          }

          for member in tempServerArray {
            print("create time ", member.createTime as Any)
            print("name ", member.nick as Any)
          }
          print("getMemberWithRoles call back ")
          completion(nil, tempServerArray, isNoMoreData)
        }

      } else {
        completion(error as NSError?, nil, isNoMoreData)
        print("getServerMembersByPage failed,error = \(error!)")
        NELog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + ", CALLBACK FAILED, error:" + error!.localizedDescription)
      }
    }
  }

  func getNormalMember(_ serverId: UInt64?, _ roleId: UInt64?, _ owner: String?, _ timeTag: Double = 0, _ completion: @escaping (NSError?, Bool) -> Void) {
    getMemberWithRoles(serverId, timeTag) { [weak self] error, members, isNoMoreData in
      if let err = error {
        completion(err as NSError, isNoMoreData)
      } else {
        if let rid = roleId {
          if let ms = members {
            for i in 0 ..< ms.count {
              let member = ms[i]
              if let createTime = member.createTime {
                self?.lastTimeTag = createTime
              }
              if member.accid == owner {
                break
              }
              var findRoleid = false
              member.roles?.forEach { role in
                if role.roleId == rid {
                  findRoleid = true
                }
              }
              if findRoleid == false {
                self?.normalMembers.append(member)
              }
            }
          }
        }
        completion(nil, isNoMoreData)
      }
    }
  }

  func reloadNormalMember(_ serverId: UInt64?, _ roleId: UInt64?, _ owner: String?, _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(className(), desc: "reloadNormalMember rid : \(roleId ?? 0)")
    getMemberWithRoles(serverId, 0) { [weak self] error, members, isNoMoreData in
      NELog.infoLog(self?.className() ?? "", desc: "reloadNormalMember members \(members?.count ?? 0)")
      if let err = error {
        completion(err as NSError)
      } else {
        if let rid = roleId {
          NELog.infoLog(self?.className() ?? "", desc: "reloadNormalMember rid \(rid)")
          self?.normalMembers.removeAll()
          members?.forEach { member in
            if member.accid == owner {
              return
            }
            var findRoleid = false
            member.roles?.forEach { role in
              if role.roleId == rid {
                findRoleid = true
              }
            }
            if findRoleid == false {
              NELog.infoLog(self?.className() ?? "", desc: "add normal member \(member)")
              self?.normalMembers.append(member)
            }
          }
        }
        completion(nil)
      }
    }
  }

  public func getExistingServerRoleMembersByAccids(_ param: GetExistingServerRoleMembersByAccidsParam,
                                                   _ completion: @escaping (Error?, [String])
                                                     -> Void) {
    repo.getExistingServerRoleMembersByAccids(param, completion)
  }

  public func addManagerMember(_ serverId: UInt64?, _ roleId: UInt64?, _ accids: [String]?, _ completion: @escaping (NSError?) -> Void) {
    var param = AddServerRoleMemberParam()
    param.serverId = serverId
    param.roleId = roleId
    param.accountArray = accids
    repo.addRoleMember(param) { [weak self] error, successIds, failedIds in
      if let err = error {
        completion(err as NSError)
      } else {
        if let sid = serverId {
          var items = [QChatGetServerMemberItem]()
          successIds.forEach { accid in
            let item = QChatGetServerMemberItem(serverId: sid, accid: accid)
            items.append(item)
          }
          let param = QChatGetServerMembersParam(serverAccIds: items)
          self?.repo.getServerMembers(param: param) { [weak self] error, members in
            members?.forEach { member in
              if self?.managerMembers.count ?? 0 > 0 {
                self?.managerMembers.insert(member, at: 1)
              } else {
                self?.managerMembers.insert(member, at: 0)
              }
            }
            completion(error as NSError?)
          }
        }
      }
    }
  }

  public func removeNormalMeber(_ serverId: UInt64?, _ accid: [String]?, _ completion: @escaping (NSError?) -> Void) {
    var param = KickServerMembersParam()
    param.serverId = serverId
    param.accounts = accid
    repo.kickoutServerMembers(param) { error in
      completion(error as NSError?)
    }
  }

  public func removeManagerMember(_ serverId: UInt64?, _ roleId: UInt64?, _ accids: [String]?, _ completion: @escaping (NSError?) -> Void) {
    let param = NIMQChatRemoveServerRoleMemberParam()
    if let sid = serverId {
      param.serverId = sid
    }
    if let rid = roleId {
      param.roleId = rid
    }
    if let accounts = accids {
      param.accountArray = accounts
    }

    repo.removeServerRoleMember(param: param) { error, result in
      completion(error as NSError?)
    }
  }

  public func checkPermission(_ server: QChatServer?, _ completion: @escaping (NSError?, Bool) -> Void) {
    guard let sid = server?.serverId, let cid = server?.announce?.channelId?.uint64Value else {
      return
    }
    repo.checkPermission(serverId: sid, channelId: cid, permissionType: .manageRole) { error, permission in
      completion(error, permission)
    }
  }

  public func addMemberRole(_ serverId: UInt64?, _ channelId: UInt64?, _ accid: String?) {
    let param = AddMemberRoleParam(serverId: serverId, channelId: channelId, accid: accid)
    repo.addMemberRole(param: param) { [weak self] error, memberRole in
      NELog.infoLog(self?.className() ?? "", desc: "add member role error : \(error?.localizedDescription ?? "")")
    }
  }

  public func removeMemberRole(_ serverId: UInt64?, _ channelId: UInt64?, _ accid: String?) {
    let param = RemoveMemberRoleParam(serverId: serverId, channelId: channelId, accid: accid)
    repo.removeMemberRole(param: param) { [weak self] error in
      NELog.infoLog(self?.className() ?? "", desc: "remove member role error : \(error?.localizedDescription ?? "")")
    }
  }

  func didRemoveManager(_ accids: [String], _ serverId: UInt64) {
    print("did listen remove manager")
    if let sid = qchatServer?.serverId, sid != serverId {
      return
    }

    var accidSet = Set<String>()
    accids.forEach { accid in
      accidSet.insert(accid)
    }
    if accidSet.contains(QChatKitClient.instance.imAccid()) {
      delegate?.didNeedBack()
      return
    }
    managerMembers.removeAll { member in
      if let accid = member.accid, accidSet.contains(accid) {
        return true
      }
      return false
    }
    delegate?.didNeedRefreshUI()
  }

  public func loadMoreManagerMemberData(_ completion: @escaping (NSError?, Bool) -> Void) {
    var timeTag: Double = 0
    if let last = managerMembers.last, let createTime = last.createTime {
      timeTag = createTime
    }
    getManagerMembers(qchatServer?.announce?.roleId?.uint64Value, qchatServer?.serverId, qchatServer?.owner, true, timeTag) { error, isNoMoreData in
      completion(error, isNoMoreData)
    }
  }

  public func loadMoreNormalMemberData(_ completion: @escaping (NSError?, Bool) -> Void) {
    getNormalMember(qchatServer?.serverId, qchatServer?.announce?.roleId?.uint64Value, qchatServer?.owner, lastTimeTag) { error, isNoMoreData in
      print("load more normal data")
      completion(error, isNoMoreData)
    }
  }

  func didRemoveNormal(_ accids: [String], _ serverId: UInt64) {
    print("did listen remove normal")
    if let sid = qchatServer?.serverId, sid != serverId {
      return
    }
    var accidSet = Set<String>()
    accids.forEach { accid in
      accidSet.insert(accid)
      allMemberMark.remove(accid)
    }
    normalMembers.removeAll { member in
      if let accid = member.accid, accidSet.contains(accid) {
        return true
      }
      return false
    }

    delegate?.didNeedRefreshUI()
  }

  // 检查通知中的操作对象是否是自己
  func checkIsCurrentUser(_ systemNoti: NIMQChatSystemNotification) -> Bool {
    if let sid = qchatServer?.serverId, sid == systemNoti.serverId {
      if let accid = systemNoti.fromAccount, accid == QChatKitClient.instance.imAccid() {
        return true
      }
    }
    return false
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        if systemNoti.type == .serverMemberLeave,
           let accid = systemNoti.fromAccount {
          // 主动离开社区
          didRemoveNormal([accid], systemNoti.serverId)
          didRemoveManager([accid], systemNoti.serverId)

        } else if systemNoti.type == .serverMemberKick,
                  let attach = systemNoti.attach as? NIMQChatKickServerMembersDoneAttachment {
          // 踢除社区成员
          if let accids = attach.kickedAccids, let sid = attach.server?.serverId {
            didRemoveNormal(accids, sid)
          }
        } else if systemNoti.type == .addServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatAddServerRoleMembersNotificationAttachment {
          // 加入社区身份组成员

        } else if systemNoti.type == .removeServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatRemoveServerRoleMembersNotificationAttachment {
          // 移除社区身份组成员
          if let accids = attach.removeServerRoleAccIds {
            didRemoveManager(accids, systemNoti.serverId)
          }
        } else if systemNoti.type == .serverRoleAuthUpdate,
                  let updateAttach = systemNoti.attach as? NIMQChatUpdateServerRoleAuthNotificationAttachment {
          // 更新社区身份组权限
        } else if systemNoti.type == .addServerRoleMembers {
          if let attach = systemNoti.attach as? NIMQChatAddServerRoleMembersNotificationAttachment {
            if let accids = attach.addServerRoleAccIds {
              didRemoveNormal(accids, systemNoti.serverId)
            }
          }
        } else if systemNoti.type == .memberRoleAuthUpdate {
          if let sid = qchatServer?.serverId, sid == systemNoti.serverId {
            checkPermission(qchatServer) { error, permission in
              if error == nil {
                self.hasPermission = permission
                self.delegate?.didNeedRefreshUI()
              }
            }
          }
        }
      }
    }
  }
}
