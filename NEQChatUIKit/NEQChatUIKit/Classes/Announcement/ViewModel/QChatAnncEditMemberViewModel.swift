// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit
import NIMSDK

public protocol QChatAnncEditMemberViewModelDelegate: NSObjectProtocol {
  func didClickRemoveAdmin()
  func didRefresh()
  func showErrorToast(_ error: NSError)
  func showToastInView(_ string: String)
}

@objcMembers
public class QChatAnncEditMemberViewModel: NSObject {
  public let repo = QChatRepo.shared
  var member: ServerMemeber?
  var server: QChatServer?
  weak var delegate: QChatAnncEditMemberViewModelDelegate?

  /// 发消息
  let sendMsg = QChatSettingModel()
  var sendMsgSwitchOpen = true
  /// 编辑频道信息
  let editChannelInfo = QChatSettingModel()
  var editChannelInfoSwitchOpen = true
  /// 删除消息
  let deleteMsg = QChatSettingModel()
  var deleteMsgSwitchOpen = true
  /// 管理订阅者
  let manageSubscriber = QChatSettingModel()
  var manageSubscriberSwitchOpen = true
  /// 管理表情评论
  let manageEmotionComment = QChatSettingModel()
  var manageEmotionCommentSwitchOpen = true

  init(server: QChatServer?, member: ServerMemeber?) {
    super.init()
    self.server = server
    self.member = member

    // 校验是否已添加定制权限，无则加
    addMemberRole { [weak self] memberRole in
      self?.setSwitchOpen(memberRoles: memberRole)
    }
  }

  /// 权限列表
  func getSetionAuthority() -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 发消息
    sendMsg.title = localizable("send_message")
    sendMsg.type = QChatSettingCellType.SettingSwitchCell.rawValue
    sendMsg.swichChange = { [weak self] isOpen in
      self?.sendMsg.switchOpen = isOpen
    }
    model.cellModels.append(sendMsg)

    // 编辑频道信息
    editChannelInfo.title = localizable("edit_channel_info")
    editChannelInfo.type = QChatSettingCellType.SettingSwitchCell.rawValue
    editChannelInfo.swichChange = { [weak self] isOpen in
      self?.editChannelInfo.switchOpen = isOpen
    }
    model.cellModels.append(editChannelInfo)

    // 删除消息
    deleteMsg.title = localizable("delete_message")
    deleteMsg.type = QChatSettingCellType.SettingSwitchCell.rawValue
    deleteMsg.swichChange = { [weak self] isOpen in
      self?.deleteMsg.switchOpen = isOpen
    }
    model.cellModels.append(deleteMsg)

    // 管理订阅者
    manageSubscriber.title = localizable("manage_subscribers")
    manageSubscriber.type = QChatSettingCellType.SettingSwitchCell.rawValue
    manageSubscriber.swichChange = { [weak self] isOpen in
      self?.manageSubscriber.switchOpen = isOpen
    }
    model.cellModels.append(manageSubscriber)

    // 管理表情评论
    manageEmotionComment.title = localizable("manage_emotion_comment")
    manageEmotionComment.type = QChatSettingCellType.SettingSwitchCell.rawValue
    manageEmotionComment.swichChange = { [weak self] isOpen in
      self?.manageEmotionComment.switchOpen = isOpen
    }
    model.cellModels.append(manageEmotionComment)

    model.setCornerType()
    return model
  }

  func getSectionLeave() -> QChatSettingSectionModel {
    let model = QChatSettingSectionModel()

    // 移除管理员
    let removeAdmin = QChatSettingModel()
    removeAdmin.type = QChatSettingCellType.SettingDestructiveCell.rawValue
    removeAdmin.title = localizable("remove_administrator")
    removeAdmin.cellClick = { [weak self] in
      self?.delegate?.didClickRemoveAdmin()
    }
    model.cellModels.append(removeAdmin)

    model.setCornerType()
    return model
  }

  /// 移除管理员
  func removeAdmin(_ completion: @escaping (Bool) -> Void) {
    guard let serverId = server?.serverId,
          let channelId = server?.announce?.channelId?.uint64Value,
          let roleId = server?.announce?.roleId?.uint64Value,
          let uid = member?.accid else {
      return
    }
    let param = NIMQChatRemoveServerRoleMemberParam()
    param.serverId = serverId
    param.roleId = roleId
    param.accountArray = [uid]

    repo.removeServerRoleMember(param: param) { [weak self] error, result in
      if let err = error as? NSError {
        self?.delegate?.showErrorToast(err)
        completion(false)
      } else if result?.successfulAccidArray.contains(uid) == true {
        // 移除定制权限
        self?.repo.removeMemberRole(param: RemoveMemberRoleParam(serverId: serverId, channelId: channelId, accid: uid)) { error in
          if let err = error {
            if err.code == errorCode_NetWorkError {
              completion(false)
            } else {
              completion(true)
            }
            self?.delegate?.showErrorToast(err)
          } else {
            completion(true)
          }
        }
      } else if result?.failedAccidArray.contains(uid) == true {
        self?.hasLeave { error, hasLeave in
          if let err = error {
            self?.delegate?.showErrorToast(err)
          } else {
            if hasLeave {
              // 已退出公共频道则回头到上一页
              completion(true)
            } else {
              completion(false)
            }
          }
        }
      } else {
        completion(false)
      }
    }
  }

  /// 添加定制权限
  func addMemberRole(_ completion: @escaping (MemberRole) -> Void) {
    var param = GetMemberRolesParam()
    param.serverId = server?.serverId
    param.channelId = server?.announce?.channelId?.uint64Value
    param.limit = 200

    // 查询是否有定制权限，没有则添加
    repo.getMemberRoles(param: param) { [weak self] error, memberRoles in
      if let error = error {
        print(error.localizedDescription)
      } else if let memberRoles = memberRoles {
        for memberRole in memberRoles {
          if memberRole.accid == self?.member?.accid {
            // 已存在定制权限
            completion(memberRole)
            return
          }
        }

        // 添加定制权限
        let addParam = AddMemberRoleParam(serverId: self?.server?.serverId, channelId: self?.server?.announce?.channelId?.uint64Value, accid: self?.member?.accid)
        self?.repo.addMemberRole(param: addParam) { error, memberRole in
          if let err = error {
            print(err.localizedDescription)
          } else if let memberRole = memberRole {
            completion(memberRole)
          }
        }
      }
    }
  }

  /// 设置开关状态
  func setSwitchOpen(memberRoles: MemberRole?) {
    if let memberRole = memberRoles {
      for cmd in memberRole.auths ?? [] {
        if cmd.customType == emojiAuthType {
          manageEmotionComment.switchOpen = cmd.status != .Deny
          manageEmotionCommentSwitchOpen = manageEmotionComment.switchOpen
        } else {
          switch cmd.type {
          case .sendMsg:
            sendMsg.switchOpen = cmd.status != .Deny
            sendMsgSwitchOpen = sendMsg.switchOpen
          case .manageChannel:
            editChannelInfo.switchOpen = cmd.status != .Deny
            editChannelInfoSwitchOpen = editChannelInfo.switchOpen
          case .deleteOtherMsg:
            deleteMsg.switchOpen = cmd.status != .Deny
            deleteMsgSwitchOpen = deleteMsg.switchOpen
          case .manageRole:
            manageSubscriber.switchOpen = cmd.status != .Deny
            manageSubscriberSwitchOpen = manageSubscriber.switchOpen
          default:
            break
          }
        }
      }
      delegate?.didRefresh()
    }
  }

  func saveAdminAuthStatus(_ completion: @escaping (NSError?) -> Void) {
    var commands = [RoleStatusInfo]()

    if sendMsg.switchOpen != sendMsgSwitchOpen {
      let sendMsgCmd = RoleStatusInfo(type: .sendMsg,
                                      status: sendMsg.switchOpen ? .Extend : .Deny)
      commands.append(sendMsgCmd)
    }
    if editChannelInfo.switchOpen != editChannelInfoSwitchOpen {
      let editChannelInfoCmd = RoleStatusInfo(type: .manageChannel,
                                              status: editChannelInfo.switchOpen ? .Extend : .Deny)
      commands.append(editChannelInfoCmd)
    }
    if deleteMsg.switchOpen != deleteMsgSwitchOpen {
      let deleteMsgCmd = RoleStatusInfo(type: .deleteOtherMsg,
                                        status: deleteMsg.switchOpen ? .Extend : .Deny)
      commands.append(deleteMsgCmd)
    }
    if manageSubscriber.switchOpen != manageSubscriberSwitchOpen {
      let manageSubscriberCmd = RoleStatusInfo(type: .manageRole,
                                               status: manageSubscriber.switchOpen ? .Extend : .Deny)
      commands.append(manageSubscriberCmd)
    }
    if manageEmotionComment.switchOpen != manageEmotionCommentSwitchOpen {
      let manageEmoCommentCmd = RoleStatusInfo(customtype: emojiAuthType, status: manageEmotionComment.switchOpen ? .Extend : .Deny)
      commands.append(manageEmoCommentCmd)
    }

    if commands.count > 0 {
      updateAdminAuthStatus(commands) { [self] error in
        if let err = error {
          if err.code != errorCode_NetWorkError {
            sendMsg.switchOpen = sendMsgSwitchOpen
            editChannelInfo.switchOpen = editChannelInfoSwitchOpen
            deleteMsg.switchOpen = deleteMsgSwitchOpen
            manageSubscriber.switchOpen = manageSubscriberSwitchOpen
            manageEmotionComment.switchOpen = manageEmotionCommentSwitchOpen
            delegate?.didRefresh()
          }
          completion(err)
        } else {
          sendMsgSwitchOpen = sendMsg.switchOpen
          editChannelInfoSwitchOpen = editChannelInfo.switchOpen
          deleteMsgSwitchOpen = deleteMsg.switchOpen
          manageSubscriberSwitchOpen = manageSubscriber.switchOpen
          manageEmotionCommentSwitchOpen = manageEmotionComment.switchOpen
          completion(nil)
        }
      }
    } else {
      hasLeave { [weak self] error, hasLeave in
        if let err = error {
          completion(err)
        } else {
          if hasLeave {
            self?.delegate?.showToastInView(localizable("save_failed"))
          } else {
            // 未做更改
            completion(nil)
          }
        }
      }
    }
  }

  /// 更新管理员的所有定制权限状态
  func updateAdminAuthStatus(_ commands: [RoleStatusInfo], _ completion: @escaping (NSError?) -> Void) {
    let param = UpdateMemberRoleParam(
      serverId: server?.serverId,
      channelId: server?.announce?.channelId?.uint64Value,
      accid: member?.accid,
      commands: commands
    )
    repo.updateMemberRole(param: param) { error, memberRole in
      completion(error)
    }
  }

  /// 查询是否已退出公告频道
  func hasLeave(_ completion: @escaping (NSError?, Bool) -> Void) {
    var param = GetExistingServerRoleMembersByAccidsParam()
    param.serverId = server?.serverId
    param.roleId = server?.announce?.roleId?.uint64Value
    param.accids = [member?.accid ?? ""]
    repo.getExistingServerRoleMembersByAccids(param) { [weak self] error, accids in
      if let err = error as? NSError {
        completion(err, false)
      } else {
        if accids.contains(self?.member?.accid ?? "") == false {
          // 已退出公告频道
          completion(nil, true)
        } else {
          completion(nil, false)
        }
      }
    }
  }
}
