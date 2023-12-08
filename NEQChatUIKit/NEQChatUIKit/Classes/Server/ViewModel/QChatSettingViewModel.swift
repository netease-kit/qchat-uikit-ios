// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK

public protocol SettingModelDelegate: NSObjectProtocol {
  func didClickChannelName()
  func didClickChannelDesc()
  func didClickAdministrator()
  func didClickSubscriber()
  func didClickHistory()
  func didClickEmotionReplyEnable(_ isOpen: Bool)
  func didClickLeave(_ isOwner: Bool)
  func didRefresh()
  func didReloadData(_ isAdmin: Bool)
  func didUpdateServerInfo(_ server: QChatServer?)
  func showToastInView(_ string: String)
}

// 页面需要销毁回调
typealias FinishControllerBlock = () -> Void

@objcMembers
public class QChatSettingViewModel: NSObject, NIMQChatMessageManagerDelegate {
  public let repo = QChatRepo.shared
  var server: QChatServer?
  weak var delegate: SettingModelDelegate?
  var didGoBack: FinishControllerBlock?

  // 管理员
  let manager = QChatSettingModel()
  var managerCount = 0 {
    didSet {
      manager.detailLabel = "\(managerCount)"
      delegate?.didRefresh()
    }
  }

  // 订阅者
  let subscriber = QChatSettingModel()
  var subscriberCount = 0 {
    didSet {
      subscriber.detailLabel = "\(subscriberCount)"
      delegate?.didRefresh()
    }
  }

  // 允许表情回复
  let emotionReplyEnable = QChatSettingModel()

  init(server: QChatServer? = nil) {
    super.init()
    self.server = server
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  deinit {
    NIMSDK.shared().qchatMessageManager.remove(self)
  }

  public func isMyServer() -> Bool {
    if let owner = server?.owner {
      let accid = QChatKitClient.instance.imAccid()
      if owner == accid {
        return true
      }
    }
    return false
  }

  /// 权限
  func getSetionAuthority() -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 成员
    let member = QChatSettingModel()
    member.title = localizable("qchat_member")
    model.cellModels.append(member)

    // 身份组
    let idGroup = QChatSettingModel()
    idGroup.title = localizable("qchat_id_group")
    model.cellModels.append(idGroup)

    model.setCornerType()
    return model
  }

  /// 频道信息
  func getSestionChannelInfo() -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 频道名称
    let manager = QChatSettingModel()
    manager.title = localizable("notice_name")
    manager.type = QChatSettingCellType.SettingArrowCell.rawValue
    manager.cellClick = { [weak self] in
      self?.delegate?.didClickChannelName()
    }
    model.cellModels.append(manager)

    // 频道说明
    let subscriber = QChatSettingModel()
    subscriber.title = localizable("channel_description")
    subscriber.type = QChatSettingCellType.SettingArrowCell.rawValue
    subscriber.cellClick = { [weak self] in
      self?.delegate?.didClickChannelDesc()
    }
    model.cellModels.append(subscriber)

    model.setCornerType()
    return model
  }

  /// 成员信息
  func getSestionMemberInfo() -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 管理员
    manager.title = localizable("administrator")
    manager.type = QChatSettingCellType.SettingArrowCell.rawValue
    manager.cellClick = { [weak self] in
      self?.delegate?.didClickAdministrator()
    }
    model.cellModels.append(manager)

    // 订阅者
    subscriber.title = localizable("subscriber")
    subscriber.type = QChatSettingCellType.SettingArrowCell.rawValue
    subscriber.cellClick = { [weak self] in
      self?.delegate?.didClickSubscriber()
    }
    model.cellModels.append(subscriber)

    model.setCornerType()
    return model
  }

  /// 消息管理
  func getSectionMessageManage(_ isAdministrator: Bool) -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 历史记录
//    let history = QChatSettingModel()
//    history.title = localizable("history_record")
//    history.type = QChatSettingCellType.SettingArrowCell.rawValue
//    history.cellClick = { [weak self] in
//      self?.delegate?.didClickHistory()
//    }
//    model.cellModels.append(history)

    // 消息提醒
//    let messageRemind = QChatSettingModel()
//    messageRemind.title = localizable("message_remind")
//    messageRemind.type = QChatSettingCellType.SettingSwitchCell.rawValue
//    messageRemind.switchOpen = server?.enablePush ?? false
//    messageRemind.swichChange = { [weak self] isOpen in
//      self?.updateUserServerPushConfig(serverId: self?.server?.serverId ?? 0, enable: isOpen)
//    }
//    model.cellModels.append(messageRemind)

    if isAdministrator {
      // 允许表情回复
      emotionReplyEnable.title = localizable("emoticon_reply_enable")
      emotionReplyEnable.type = QChatSettingCellType.SettingSwitchCell.rawValue
      emotionReplyEnable.switchOpen = (server?.announce?.emojiReplay ?? 0) == 1
      emotionReplyEnable.swichChange = { [weak self] isOpen in
        self?.updateEmotionEnable(enable: isOpen) { success in
          if success {
            self?.delegate?.didClickEmotionReplyEnable(isOpen)
          } else {
            self?.emotionReplyEnable.switchOpen = !isOpen
            self?.delegate?.didRefresh()
          }
        }
      }
      model.cellModels.append(emotionReplyEnable)
    }

    model.setCornerType()

    return model
  }

  func getSectionLeave() -> QChatSettingSectionModel {
    let isOwner = isMyServer()

    // 离开
    let leave = QChatSettingModel()
    leave.type = QChatSettingCellType.SettingDestructiveCell.rawValue
    leave.title = isOwner ? localizable("dismiss_channel") : localizable("leave_channel")
    leave.cellClick = { [weak self] in
      self?.delegate?.didClickLeave(isOwner)
    }

    let model = QChatSettingSectionModel()
    model.cellModels.append(leave)
    model.setCornerType()

    return model
  }

  /// 获取管理员人数
  func getManagerNumber(_ completion: @escaping (Int) -> Void) {
    var param = GetServerRoleMembersParam()
    param.serverId = server?.serverId
    param.roleId = server?.announce?.roleId?.uint64Value
    param.limit = 200
    repo.getServerRoleMembers(param) { error, roleMemers in
      if error != nil {
        completion(0)
      } else {
        completion(roleMemers.count)
      }
    }
  }

  /// 获取社区人数
  func getServerMemberNumber(_ completion: @escaping (Int) -> Void) {
    guard let serverId = server?.serverId else {
      completion(1)
      return
    }
    repo.getServers(QChatGetServersParam(serverIds: [NSNumber(value: serverId)])) { error, results in
      if error != nil {
        completion(1)
      } else if let number = results?.servers.first?.memberNumber {
        completion(number)
      }
    }
  }

  /// 查询是否具有某个权限
  func checkPermission(command: StatusInfo, _ completion: @escaping (NSError?, Bool) -> Void) {
    guard let serverId = server?.serverId,
          let channelId = server?.announce?.channelId?.uint64Value else {
      return
    }

    var permissionType = command.permissionType?.convertQCathPermissionType()
    if let customType = command.customType {
      permissionType = NIMQChatPermissionType(rawValue: customType)
    }

    if let type = permissionType {
      repo.checkPermission(serverId: serverId, channelId: channelId, permissionType: type) { error, allow in
        completion(error, allow)
      }
    }
  }

  /// 查询是否具有编辑公告频道信息的权限
  func checkManageChannelPermission(_ completion: @escaping (Bool) -> Void) {
    var command = StatusInfo()
    command.permissionType = .manageChannel
    checkPermission(command: command) { [weak self] error, hasPermission in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.delegate?.showToastInView(localizable("network_error"))
        case errorCode_NoPermission:
          self?.delegate?.showToastInView(localizable("no_permession"))
        default:
          self?.delegate?.showToastInView(err.localizedDescription)
        }
      } else {
        completion(hasPermission)
      }
    }
  }

  /// 更新允许表情回复设置
  func updateEmotionEnable(enable: Bool, _ completion: @escaping (Bool) -> Void) {
    var command = StatusInfo()
    command.customType = emojiAuthType

    // 查询是否有更改表情回复设置的权限
    checkPermission(command: command) { [weak self] error, hasPermission in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.delegate?.showToastInView(localizable("network_error"))
        case errorCode_NoPermission:
          self?.delegate?.showToastInView(localizable("no_permession"))
        default:
          self?.delegate?.showToastInView(err.localizedDescription)
        }
        completion(false)
      } else {
        if hasPermission {
          let announce = NEAnnounceModel()
          announce.channelId = self?.server?.announce?.channelId
          announce.roleId = self?.server?.announce?.roleId
          announce.emojiReplay = enable ? 1 : 0
          let dic: [String: Any] = ["announce": announce.yx_modelToJSONObject() as Any]
          let custom = NECommonUtil.getJSONStringFromDictionary(dic)

          guard var param = self?.server?.convertUpdateServerParam() else {
            return
          }
          param.custom = custom

          self?.repo.updateServer(param) { error, _ in
            if let err = error as? NSError {
              NELog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + " \(err.localizedDescription)")
              self?.delegate?.didRefresh()
              self?.delegate?.showToastInView(err.localizedDescription)
              completion(false)
            } else {
              self?.server?.announce?.emojiReplay = enable ? 1 : 0
              completion(true)
            }
          }
        } else {
          self?.delegate?.showToastInView(localizable("no_permession"))
          completion(false)
        }
      }
    }
  }

  // MARK: NIMQChatMessageManagerDelegate

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        guard systemNoti.serverId == server?.serverId else {
          continue
        }
        if systemNoti.type == .serverMemberApplyDone,
           let attach = systemNoti.attach as? NIMQChatApplyJoinServerMemberDoneAttachment {
          // 申请加入社区
          subscriberCount = (attach.server?.memberNumber ?? 1) - managerCount
        } else if systemNoti.type == .serverMemberInviteDone,
                  let attach = systemNoti.attach as? NIMQChatInviteServerMembersDoneAttachment {
          // 邀请社区成员
          subscriberCount = (attach.server?.memberNumber ?? 1) - managerCount
        } else if systemNoti.type == .serverMemberLeave,
                  let attch = systemNoti.attach as? NIMQChatLeaveServerAttachment {
          // 主动离开社区
          getManagerNumber { [weak self] count in
            self?.managerCount = count + 1
            self?.subscriberCount = (attch.server?.memberNumber ?? 1) - count - 1
          }
          if systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
            if let goBack = didGoBack {
              goBack()
            }
          }
        } else if systemNoti.type == .serverMemberKick,
                  let attach = systemNoti.attach as? NIMQChatKickServerMembersDoneAttachment {
          // 踢除社区成员
          subscriberCount = (attach.server?.memberNumber ?? 1) - managerCount

          if attach.kickedAccids?.contains(where: { accid in
            accid == QChatKitClient.instance.imAccid()
          }) == true {
            if let goBack = didGoBack {
              goBack()
            }
          }
        } else if systemNoti.type == .addServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatAddServerRoleMembersNotificationAttachment {
          // 添加社区身份组成员
          if systemNoti.serverId == server?.serverId, attach.roleId == server?.announce?.roleId?.uint64Value {
            // 添加管理员
            managerCount += attach.addServerRoleAccIds?.count ?? 0
            subscriberCount -= attach.addServerRoleAccIds?.count ?? 0
            if attach.addServerRoleAccIds?.contains(QChatKitClient.instance.imAccid()) == true {
              // 自己被添加, 刷新页面
              delegate?.didReloadData(true)
            }
          }
        } else if systemNoti.type == .removeServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatRemoveServerRoleMembersNotificationAttachment {
          // 移除社区身份组成员
          if systemNoti.serverId == server?.serverId, attach.roleId == server?.announce?.roleId?.uint64Value {
            // 移除管理员
            managerCount -= attach.removeServerRoleAccIds?.count ?? 0
            subscriberCount += attach.removeServerRoleAccIds?.count ?? 0
            if attach.removeServerRoleAccIds?.contains(QChatKitClient.instance.imAccid()) == true {
              // 自己被移除, 刷新页面
              delegate?.didReloadData(false)
            }
          }
        } else if systemNoti.type == .serverRoleAuthUpdate,
                  let _ = systemNoti.attach as? NIMQChatUpdateServerRoleAuthNotificationAttachment {
          // 更新社区身份组权限
        } else if systemNoti.type == .serverUpdate,
                  let updateAttach = systemNoti.attach as? NIMQChatUpdateServerAttachment {
          let oldEmoAuth = server?.announce?.emojiReplay
          server = QChatServer(server: updateAttach.server)
          if server?.announce?.emojiReplay != oldEmoAuth {
            // 允许表情评论回复状态改变
            emotionReplyEnable.switchOpen = server?.announce?.emojiReplay == 1
            delegate?.didRefresh()
          }
          delegate?.didUpdateServerInfo(server)
        } else if systemNoti.type == .serverRemove {
          if let goBack = didGoBack {
            goBack()
          }
        }
      }
    }
  }
}
