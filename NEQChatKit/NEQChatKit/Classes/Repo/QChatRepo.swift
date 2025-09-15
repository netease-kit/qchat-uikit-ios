// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMQChat
import NIMSDK

@objc public protocol QChatRepoMessageDelegate: NSObjectProtocol {
  @objc optional func onReceive(_ messages: [NIMQChatMessage])

  @objc optional func onUnReadChange(_ unreads: [NIMQChatUnreadInfo]?,
                                     _ lastUnreads: [NIMQChatUnreadInfo]?)

  @objc optional func serverUnreadInfoChanged(_ serverUnreadInfoDic: [NSNumber: NIMQChatServerUnreadInfo])
}

@objcMembers
public class QChatRepo: NSObject, QChatMessageProviderDelegate {
  private let moduleName = "NEQChatKit"
  private let className = "QChatRepo"
  public static let shared = QChatRepo()

  public let roleProvider = QChatRoleProvider.shared

  public let serverProvider = QChatServerProvider.shared

  public let channelProvider = QChatChannelProvider.shared

  public let contactProvider = FriendProvider.shared

  public let userProvider = UserProvider.shared

  public let messageProvider = QChatMessageProvider.shared

  public let settingProvider = SettingProvider.shared

  public let apnsProvider = QChatApnsProvider.shared

  public weak var delegate: QChatRepoMessageDelegate? {
    didSet {
      if delegate != nil {
        messageProvider.addDelegate(self)
      } else {
        messageProvider.removeDelegate(self)
      }
    }
  }

  override private init() {
    super.init()
    buryDataPoints()
  }

  /// 数据埋点
  private func buryDataPoints() {
    let reportData = BaseReportData()
    reportData.imVersion = QChatKitClient.instance.sdkVersion()
    reportData.component = "QChatKit"
    reportData.appKey = QChatKitClient.instance.appKey()
    reportData.reportType = "init"
    reportData.version = qChatKitVersion
    XKitReporter.shared().report(reportData)
  }

  /// 消息接收回调
  public func onReceive(_ messages: [NIMQChatMessage]) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messages.count:\(messages.count)")
    delegate?.onReceive?(messages)
  }

  /// 未读数变更回调
  public func onUnReadChange(_ unreads: [NIMQChatUnreadInfo]?,
                             _ lastUnreads: [NIMQChatUnreadInfo]?) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", unreads.count:\(unreads?.count ?? 0)")
    delegate?.onUnReadChange?(unreads, lastUnreads)
  }

  /// 社区未读数变更回调
  public func serverUnreadInfoChanged(_ serverUnreadInfoDic: [NSNumber: NIMQChatServerUnreadInfo]) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", server unreads change :\(serverUnreadInfoDic)")
    delegate?.serverUnreadInfoChanged?(serverUnreadInfoDic)
  }

  /// 创建身份组
  public func createRole(_ param: NEQChatServerRoleParam,
                         _ completion: @escaping (Error?, NEQChatServerRole) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.createRole(param, completion)
  }

  /// 获取社区身份组
  public func getRoles(_ param: NEQChatGetServerRoleParam,
                       _ completion: @escaping (Error?, [NEQChatServerRole]?, Set<NSNumber>?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.getRoles(param, completion)
  }

  /// 批量更新社区身份组的权限优先级
  public func updateServerRolePriorities(_ param: NEQChatUpdateServerRolePrioritiesParam,
                                         _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.updateServerRolePriorities(param, completion)
  }

  /// 查询主题下身份组列表
  public func getChannelRoles(_ param: NEQChatChannelRoleParam,
                              _ completion: @escaping (Error?, [NEQChatChannelRole]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId)")
    roleProvider.getChannelRoles(param: param, completion)
  }

  /// 查询某社区下某身份组下的成员列表
  public func getServerRoleMembers(_ param: NEQChatGetServerRoleMembersParam,
                                   _ completion: @escaping (Error?, [NEQChatRoleMember]) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.getServerRoleMembers(param, completion)
  }

  /// 更新社区身份组
  public func updateRole(_ param: NEQChatUpdateServerRoleParam,
                         _ completion: @escaping (Error?, NEQChatServerRole) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.updateRole(param, completion)
  }

  /// 删除社区身份组
  public func deleteRoles(_ param: NEQChatDeleteServerRoleParam,
                          _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.deleteRoles(param, completion)
  }

  /// 分页查询社区成员信息
  public func getServerMembers(_ param: NEQChatGetServerMembersByPageParam,
                               _ completion: @escaping (Error?, [NEQChatServerMemeber]) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    serverProvider.getServerMembers(param, completion)
  }

  /// 修改社区成员信息
  public func updateMyServerMember(_ param: NEQChatUpdateMyMemberInfoParam,
                                   _ completion: @escaping (Error?, NEQChatServerMemeber) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    serverProvider.updateMyServerMember(param, completion)
  }

  /// 修改他人社区成员信息
  public func updateServerMember(_ param: NEQChatUpdateServerMemberInfoParam,
                                 _ completion: @escaping (Error?, NEQChatServerMemeber) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    serverProvider.updateServerMember(param, completion)
  }

  /// 将某些人加入某社区身份组
  public func addRoleMember(_ param: NEQChatAddServerRoleMemberParam,
                            _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.addRoleMember(param, completion)
  }

  /// 设置话题下身份组权限
  public func updateChannelRole(param: NEQChatUpdateChannelRoleParam,
                                _ completion: @escaping (NSError?, NEQChatChannelRole?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.updateChannelRole(param: param, completion)
  }

  /// 删除话题下的身份组
  public func removeChannelRole(param: NEQChatRemoveChannelRoleParam,
                                _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.removeChannelRole(param: param, completion)
  }

  /// 通过accid查询自定义身份组列表
  public func getServerRolesByAccId(param: NEQChatGetServerRolesByAccIdParam,
                                    _ completion: @escaping (Error?, [NEQChatServerRole]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.getServerRolesByAccId(param: param, completion)
  }

  /// 删除
  public func deleateRoleMember(_ param: NEQChatRemoveServerRoleMemberParam,
                                _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.deleateRoleMember(param, completion)
  }

  /// 添加成员到话题
  public func addMemberRole(param: NEQChatAddMemberRoleParam,
                            _ completion: @escaping (NSError?, NEQChatMemberRole?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channelId:\(param.channelId ?? 0)")
    roleProvider.addMemberRole(param, completion)
  }

  /// 查询话题下成员的权限
  public func getMemberRoles(param: NEQChatGetMemberRolesParam,
                             _ completion: @escaping (NSError?, [NEQChatMemberRole]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channelId:\(param.channelId ?? 0)")
    roleProvider.getMemberRoles(param: param, completion)
  }

  /// 设置某个话题下的成员的权限
  public func updateMemberRole(param: NEQChatUpdateMemberRoleParam,
                               _ completion: @escaping (NSError?, NEQChatMemberRole?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channelId:\(param.channelId ?? 0)")
    roleProvider.updateMemberRole(param: param, completion)
  }

  /// 移除某个话题下的成员
  public func removeMemberRole(param: NEQChatRemoveMemberRoleParam,
                               _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channelId:\(param.channelId ?? 0)")
    roleProvider.removeMemberRole(param: param, completion)
  }

  /// 将某些人移除某社区身份组
  public func removeServerRoleMember(param: NIMQChatRemoveServerRoleMemberParam,
                                     _ completion: @escaping (Error?, NIMQChatRemoveServerRoleMembersResult?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", param:\(param)")
    roleProvider.removeServerRoleMember(param: param, completion)
  }

  //    MARK: message

  /// 撤回圈组消息
  public func revokeMessage(param: NIMQChatRevokeMessageParam, completion: NIMQChatUpdateMessageHandler?) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messageId:\(param.message.messageId)")
    messageProvider.revokeMessage(param: param, completion: completion)
  }

  /// 删除圈组消息
  public func deleteMessage(param: NIMQChatDeleteMessageParam, completion: NIMQChatUpdateMessageHandler?) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messageId:\(param.message.messageId)")
    messageProvider.deleteMessage(param: param, completion: completion)
  }

  /// 发送快捷评论
  public func addQuickComment(type: Int64, to message: NIMQChatMessage, completion: NIMQChatHandler?) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messageId:\(message.messageId), type:\(type)")
    messageProvider.addQuickComment(type: type, to: message, completion: completion)
  }

  /// 删除快捷评论
  public func deleteQuickComment(type: Int64, to message: NIMQChatMessage, completion: NIMQChatHandler?) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messageId:\(message.messageId), type:\(type)")
    messageProvider.deleteQuickComment(type: type, to: message, completion: completion)
  }

  /// 批量获取快捷评论
  public func fetchQuickComments(messages: [NIMQChatMessage], completion: @escaping NIMQChatFetchQuickCommentsByMsgsHandler) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", messages.count:\(messages.count)")
    messageProvider.fetchQuickComments(messages: messages, completion: completion)
  }

//    MARK: channel

  /// 修改圈组主题信息
  public func updateChannelInfo(_ param: NEQChatUpdateChannelParam,
                                _ completion: @escaping (NSError?, NEQChatChatChannel?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channelId:\(param.channelId ?? 0)")
    channelProvider.updateChannelInfo(param: param, completion)
  }

  /// 查询话题成员信息列表
  public func getChannelMembers(param: NEQChatChannelMembersParam,
                                _ completion: @escaping (NSError?, NEQChatChannelMembersResult?)
                                  -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId)")
    channelProvider.getChannelMembers(param: param, completion)
  }

  /// 查询成员是否在该话题的黑白名单中
  public func getExistingChannelBlackWhiteMembers(param: NEQChatGetExistingChannelBlackWhiteMembersParam,
                                                  _ completion: @escaping (NSError?,
                                                                           NEQChatBlackWhiteMembersResult?)
                                                    -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    channelProvider.getExistingChannelBlackWhiteMembers(param: param, completion)
  }

  /// 从云信服务器批量获取用户资料
  public func fetchUserInfo(accountList: [String],
                            _ completion: @escaping ([V2NIMUser]?, NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", accountList.count:\(accountList.count)")
    userProvider.getUserListFromCloud(accountIds: accountList) { users, error in
      completion(users, error?.nserror as? NSError)
    }
  }

  /// 踢除社区成员
  public func kickoutServerMembers(_ param: NEQChatKickServerMembersParam,
                                   _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    serverProvider.kickoutServerMembers(param, completion)
  }

  // MARK: Server

  /// 查询社区信息
  public func getServers(_ parameter: NEQChatGetServersParam,
                         _ completion: @escaping (NSError?, NEQChatGetServersResult?) -> Void) {
    NEALog.infoLog(
      moduleName + " " + className,
      desc: #function + ", serverIds.count:\(parameter.serverIds?.count ?? 0)"
    )
    serverProvider.getServers(param: parameter, completion)
  }

  /// 修改社区信息
  public func updateServer(_ param: NEQChatUpdateServerParam, _ completion: @escaping (Error?, NEQChatServer) -> Void) {
    serverProvider.updateServer(param) { error, result in
      completion(error, NEQChatServer(server: result?.server))
    }
  }

  /// 分页查询社区成员信息
  public func getServerMembersByPage(_ parameter: NEQChatGetServerMembersByPageParam,
                                     _ completion: @escaping (NSError?,
                                                              NEQChatGetServerMembersResult?)
                                       -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(parameter.serverId ?? 0)")
    serverProvider.getServerMembersByPage(param: parameter, completion)
  }

  /// 邀请社区成员
  public func inviteMembersToServer(_ parameter: NEQChatInviteServerMembersParam,
                                    _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(parameter.serverId ?? 0)")
    serverProvider.inviteMembersToServer(param: parameter, completion)
  }

  /// 邀请社区成员(携带成功失败列表)
  public func inviteMembersToServerWithResult(param: NEQChatInviteServerMembersParam,
                                              _ completion: @escaping (NSError?, [String]?, [String]?) -> Void) {
    serverProvider.inviteMembersToServerWithResult(param: param, completion)
  }

  // MARK: Role

  /// 查询一批accids的自定义身份组列表
  public func getExistingServerRolesByAccids(_ parameter: NEQChatGetExistingAccidsInServerRoleParam,
                                             _ completion: @escaping (NSError?,
                                                                      [String: [NEQChatServerRole]]?)
                                               -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(parameter.serverId)")
    roleProvider.getExistingServerRolesByAccids(param: parameter, completion)
  }

  /// 查询自己是否有某个权限
  public func checkPermission(serverId: UInt64, channelId: UInt64?, permissionType: NIMQChatPermissionType, complete: @escaping (NSError?, Bool) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(serverId), channelId:\(String(describing: channelId)), permissionType:\(permissionType)")
    let param = NIMQChatCheckPermissionParam()
    param.serverId = serverId
    if let channelId = channelId {
      param.channelId = channelId
    }
    param.permissionType = permissionType
    roleProvider.checkPermission(param: param, complete: complete)
  }

  /// 查询一批accids是否在某个社区身份组,返回在的成员信息
  public func getExistingServerRoleMembersByAccids(_ param: NEQChatGetExistingServerRoleMembersByAccidsParam,
                                                   _ completion: @escaping (Error?, [String])
                                                     -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    roleProvider.getExistingServerRoleMembersByAccids(param, completion)
  }

  /// 查询话题未读信息
  public func getChannelUnReadInfo(_ param: NEQChatGetChannelUnreadInfosParam,
                                   _ completion: @escaping (Error?, [NIMQChatUnreadInfo]?)
                                     -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", targets.count:\(param.targets?.count ?? 0)")
    channelProvider.getChannelUnReadInfo(param, completion)
  }

  /// 分页查询圈组主题信息
  public func getChannelsByPage(param: NEQChatGetChannelsByPageParam,
                                _ completion: @escaping (NSError?, NEQChatGetChannelsByPageResult?)
                                  -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(param.serverId ?? 0)")
    channelProvider.getChannelsByPage(param: param, completion)
  }

  /// 主动离开社区
  public func leaveServer(_ serverId: UInt64?, _ completion: @escaping (Error?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    serverProvider.leaveServer(serverId, completion)
  }

  /// 批量获取话题最后一条消息
  public func getLastMessage(_ serverId: UInt64, _ channelIds: [NSNumber], _ completion: @escaping (Error?, [NSNumber: NIMQChatMessage]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(serverId)")
    let param = NIMQChatGetLastMessageOfChannelsParam()
    param.serverId = serverId
    param.channelIds = channelIds
    messageProvider.getLastMessage(param: param, completion)
  }

  /// 游客模式加入
  public func enterAsVisitor(_ param: NIMQChatEnterServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatEnterServerAsVisitorResult?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverIds:\(param.serverIds)")

    serverProvider.enterAsVisitor(param, completion)
  }

  /// 退出游客模式
  public func leaveAsVisitor(_ param: NIMQChatLeaveServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatLeaveServerAsVisitorResult?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverIds:\(param.serverIds)")
    serverProvider.leaveAsVisitor(param, completion)
  }

  /// 游客模式订阅channel
  public func subscribeChannel(_ param: NIMQChatSubscribeChannelAsVisitorParam, _ completion: @escaping (Error?, NIMQChatSubscribeChannelAsVisitorResult?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", channel ids:\(param.channelIdInfos)")
    channelProvider.subscribeChannel(param, completion)
  }

  /// 游客模式订阅Server
  public func subscribeAsVisitor(_ param: NIMQChatSubscribeServerAsVisitorParam, _ completion: @escaping (Error?, NIMQChatSubscribeServerAsVisitorResult?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverIds:\(param.serverIds)")
    serverProvider.subscribeAsVisitor(param, completion)
  }

  /// 分页获取话题信息，回调中携带last message
  public func fetchChannelsByServerIdWithLastMessage(_ serverId: UInt64, _ timeTag: TimeInterval, _ limit: Int, _ completion: @escaping (NSError?, NEQChatGetChannelsByPageResult?, [NSNumber: NIMQChatMessage]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", serverId:\(serverId), timeTag:\(timeTag), limit:\(limit)")

    var param = NEQChatGetChannelsByPageParam(timeTag: timeTag, serverId: serverId)
    if limit > 0 {
      param.limit = limit
    }
    weak var weakSelf = self
    channelProvider.getChannelsByPage(param: param) { error, result in
      if error == nil {
        if let channels = result?.channels {
          if channels.count <= 0 {
            completion(nil, nil, nil)
            return
          }
          var channelIds = [NSNumber]()
          for channel in channels {
            if let cid = channel.channelId {
              channelIds.append(NSNumber(value: cid))
            }
          }
          weakSelf?.getLastMessage(serverId, channelIds) { err, lastMsgDics in
            completion(err as NSError?, result, lastMsgDics)
          }
        } else {
          completion(nil, result, nil)
        }
      } else {
        completion(error, result, nil)
      }
    }
  }

  /// 申请加入社区
  public func applyServerJoin(param: NEQChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + " server id : \(param.serverId)")

    serverProvider.applyServerJoin(param: param, completion)
  }

  /// 批量查询社区成员信息
  public func getServerMembers(param: NEQChatGetServerMembersParam, _ completion: @escaping (Error?, [NEQChatServerMemeber]?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + " param : \(param)")
    serverProvider.getServerMembers(param: param.toIMParam()) { error, members in
      var retMembers = [NEQChatServerMemeber]()
      members?.forEach { qchatServerMebmer in
        let member = NEQChatServerMemeber(qchatServerMebmer)
        retMembers.append(member)
      }
      completion(error, retMembers)
    }
  }

  /// 批量拉取社区
  public func getServerList(param: NEQChatGetServersByPageParam,
                            _ completion: @escaping (NSError?, NEQChatGetServersByPageResult?)
                              -> Void) {
    serverProvider.getServerCount(param: param) { error, result in
      completion(error, result)
    }
  }

  /// 创建社区
  public func createServer(param: NEQChatCreateServerParam,
                           _ completion: @escaping (NSError?, NEQChatCreateServerResult?) -> Void) {
    QChatServerProvider.shared.createServer(param: param, completion)
  }

  /// 删除社区
  public func deleteServer(_ serverid: UInt64, _ completion: @escaping (Error?) -> Void) {
    serverProvider.deleteServer(serverid, completion)
  }

  /// 申请加入社区
  public func applyServerJoin(parameter: NEQChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NEALog.infoLog(moduleName + " " + className(), desc: #function + ", serverId:\(parameter.serverId)")
    QChatServerProvider.shared.applyServerJoin(param: parameter) { error in
      completion(error)
    }
  }

  /// 查询社区内成员信息
  public func getServerMemberList(parameter: NEQChatGetServerMembersParam,
                                  _ completion: @escaping (NSError?,
                                                           NEQChatGetServerMembersResult?) -> Void) {
    NEALog.infoLog(
      moduleName + " " + className(),
      desc: #function + ", serverAccIds.count:\(parameter.serverAccIds?.count ?? 0)"
    )
    QChatServerProvider.shared.getServerMembers(param: parameter) { error, result in
      completion(error, result)
    }
  }

  /// 创建公告主题
  public func createAnncServer(_ param: inout NEQChatCreateServerParam, _ completion: @escaping (NSError?, NEQChatServer?) -> Void) {
    NEALog.infoLog(moduleName + " " + className, desc: #function + ", server name:\(param.name ?? "")")
    let announce = NEQChatAnnounceModel()
    var dic = [String: Any]()
    dic["announce"] = announce.yx_modelToJSONObject()
    let custom = NECommonUtil.getJSONStringFromDictionary(dic)
    param.custom = custom
    serverProvider.createServer(param: param) { [weak self] error, result in
      if let err = error {
        completion(err, nil)
      } else if let server = result?.server {
        self?.createAnncChannelAndUpdateServer(server, server.name ?? "manager", server.icon) { error, model in
          server.announce = model
          DispatchQueue.main.async {
            completion(error, server)
          }
        }
      }
    }
  }

  // MARK: APNS

  public func getUserPushNotificationConfigByServer(server: [NSNumber], _ completion: @escaping (Error?, [NIMQChatUserPushNotificationConfig]?) -> Void) {
    apnsProvider.getUserPushNotificationConfigByServer(server: server, completion)
  }

  public func updatePushNotificationByProfile(profile: NIMPushNotificationProfile, server: UInt64, _ completion: @escaping (Error?) -> Void) {
    apnsProvider.updatePushNotificationByProfile(profile: profile, server: server, completion)
  }

  // MARK: - Private

  /// 创建公告主题server成功之后创建话题以及更新其他需要信息
  private func createAnncChannelAndUpdateServer(_ server: NEQChatServer, _ roleName: String, _ icon: String?, _ completion: @escaping (NSError?, NEQChatAnnounceModel?) -> Void) {
    let channel = NEQChatCreateChannelParam(serverId: server.serverId ?? 0, name: server.name ?? "", topic: nil, visibleType: .isPublic)

    let workingGroup = DispatchGroup()
    let workingQueue = DispatchQueue(label: "public_server")

    weak var weakSelf = self

    var lastError: NSError? // 记录中间出现的错误信息
    var channelId: UInt64?
    var roleId: UInt64?
    workingGroup.enter()
    workingQueue.async {
      weakSelf?.channelProvider.createChannel(param: channel) { error, channel in
        NEALog.infoLog(QChatRepo.className(), desc: "create announcement   \(error?.localizedDescription ?? "")")

        if let err = error {
          lastError = err
        } else {
          channelId = channel?.channelId
        }
        workingGroup.leave()
      }
    }

    workingGroup.enter()
    workingQueue.async {
      weakSelf?.updateServerManager(server, roleName) { error, role in
        NEALog.infoLog(QChatRepo.className(), desc: "updateServerManager notice  \(error?.localizedDescription ?? "")")

        if let err = error {
          lastError = err
        } else {
          roleId = role?.roleId
        }
        workingGroup.leave()
      }
    }

    workingGroup.notify(queue: workingQueue) {
      if lastError != nil {
        completion(lastError, nil)
        return
      }
      // 创建话题，创建管理员身份组以及更新无异常，开始更新社区信息

      let announce = NEQChatAnnounceModel()
      if let cid = channelId {
        announce.channelId = NSNumber(value: cid)
      }
      if let rid = roleId {
        announce.roleId = NSNumber(value: rid)
      }
      var dic = [String: Any]()
      dic["announce"] = announce.yx_modelToJSONObject()
      let custom = NECommonUtil.getJSONStringFromDictionary(dic)
      var updateServerParam = NEQChatUpdateServerParam(name: server.name ?? "", icon: icon)
      updateServerParam.custom = custom
      updateServerParam.serverId = server.serverId
      updateServerParam.name = server.name
      NEALog.infoLog(QChatRepo.className(), desc: "update custom : \(updateServerParam.custom ?? "") channel id \(channelId ?? 0) role id \(roleId ?? 0) dic : \(dic)  update param : \(updateServerParam)")

      updateServerParam.inviteMode = .autoEnter
      updateServerParam.applyMode = .autoEnter
      weakSelf?.serverProvider.updateServer(updateServerParam) { error, _ in
        NEALog.infoLog(QChatRepo.className(), desc: "update server notice \(error?.localizedDescription ?? "")")
        if let err = error {
          completion(err as NSError, announce)
        } else {
          completion(nil, announce)
        }
      }
    }
  }

  private func updateServerManager(_ server: NEQChatServer, _ roleName: String, _ completion: @escaping (NSError?, NEQChatServerRole?) -> Void) {
    var role = NEQChatServerRoleParam()
    role.serverId = server.serverId
    role.name = roleName
    role.type = .custom
    weak var weakSelf = self
    NEALog.infoLog(QChatRepo.className(), desc: "private udpapte server manager sid: \(server.serverId ?? 0) role name : \(roleName)")
    roleProvider.createRole(role) { error, serverRole in
      if let err = error {
        NEALog.infoLog(QChatRepo.className(), desc: "private udpapte server manager error : \(err.localizedDescription)")
        completion(err as NSError, nil)
      } else {
        var param = NEQChatUpdateServerRoleParam()
        if let sid = server.serverId, let rid = serverRole.roleId {
          param.serverId = sid
          param.roleId = rid
        }
        param.name = serverRole.name
        param.commands = [NEQChatPermissionStatusInfo]()

        let permissionTypes = [NEQChatPermissionType.manageServer, NEQChatPermissionType.sendMsg, NEQChatPermissionType.inviteToServer, NEQChatPermissionType.kickOthersInServer, NEQChatPermissionType.deleteOtherMsg, NEQChatPermissionType.manageChannel, NEQChatPermissionType.manageRole]

        for type in permissionTypes {
          var status = NEQChatPermissionStatusInfo()
          status.permissionType = type
          param.commands?.append(status)
        }

        // 添加表情回复权限
        var status = NEQChatPermissionStatusInfo()
        status.customType = emojiAuthType
        param.commands?.append(status)

        weakSelf?.roleProvider.updateRole(param) { error, role in
          NEALog.infoLog(QChatRepo.className(), desc: "roleProvider.updateRole error: \(error?.localizedDescription ?? "")")
          if let err = error {
            completion(err as NSError, nil)
          } else {
            completion(nil, role)
          }
        }
      }
    }
  }
}
