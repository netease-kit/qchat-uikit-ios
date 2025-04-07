
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit

@objcMembers
public class QChatPermissionModel: NSObject {
  var changeMap = [String: Bool]()

  // 通用权限
  var managerServer = NEQChatPermissionType.manageServer.rawValue
  var allChannelProperty = NEQChatPermissionType.manageChannel.rawValue
  var role = NEQChatPermissionType.manageRole.rawValue

  let commonPermission = [
    #keyPath(managerServer),
    #keyPath(allChannelProperty),
    #keyPath(role),
  ]

  let commonPermissionDic = [
    #keyPath(managerServer): localizable("qchat_manager_server"),
    #keyPath(allChannelProperty): localizable("qchat_manager_channel"),
    #keyPath(role): localizable("qchat_manager_role"),
  ]

  // 消息权限
  var sendMessage = NEQChatPermissionType.sendMsg.rawValue
  var revokeOtherMessage = NEQChatPermissionType.revokeMsg.rawValue
  var deleteOtherMessage = NEQChatPermissionType.deleteOtherMsg.rawValue

  let messagePermission = [#keyPath(sendMessage),
                           #keyPath(revokeOtherMessage),
                           #keyPath(deleteOtherMessage)]

  let messagePermissionDic =
    [#keyPath(sendMessage): localizable("qchat_send_message"),
     #keyPath(revokeOtherMessage): localizable("qchat_recall_message"),
     #keyPath(deleteOtherMessage): localizable("qchat_delete_message")]

  // 成员权限
  var modifyOwnServer = NEQChatPermissionType.modifySelfInfo.rawValue
  var modifyOthersServer = NEQChatPermissionType.modifyOthersInfoInServer.rawValue
  var inviteMember = NEQChatPermissionType.inviteToServer.rawValue
  var kickout = NEQChatPermissionType.kickOthersInServer.rawValue
  var managerBlackAndWhite = NEQChatPermissionType.manageBlackWhiteList.rawValue

  let memberPermission = [#keyPath(modifyOwnServer),
                          #keyPath(modifyOthersServer),
                          #keyPath(inviteMember),
                          #keyPath(kickout),
                          #keyPath(managerBlackAndWhite)]

  let memberPermissionDic = [
    #keyPath(modifyOwnServer): localizable("qchat_modify_own_server"),
    #keyPath(modifyOthersServer): localizable("qchat_modify_other_server"),
    #keyPath(inviteMember): localizable("qchat_invite_member"),
    #keyPath(kickout): localizable("qchat_kickout_member"),
    #keyPath(managerBlackAndWhite): localizable("qchat_manager_channel_list"),
  ]

  override init() {
    super.init()
  }

  func getChangePermission() -> [NEQChatPermissionType: Bool] {
    var permissions = [NEQChatPermissionType: Bool]()
    for (key, v) in changeMap {
      if let permissionKey = value(forKey: key) as? String,
         let type = NEQChatPermissionType(rawValue: permissionKey) {
        permissions[type] = v
      }
    }
    return permissions
  }
}
