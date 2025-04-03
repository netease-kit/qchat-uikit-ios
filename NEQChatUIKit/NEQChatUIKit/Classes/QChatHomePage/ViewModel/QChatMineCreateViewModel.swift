//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit

@objcMembers
public class QChatMineCreateViewModel: NSObject {
  let repo = QChatRepo.shared

  public func createAnncServer(parameter: inout NEQChatCreateServerParam,
                               _ completion: @escaping (NSError?, NEQChatServer?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", name:\(parameter.name ?? "nil")")
    repo.createAnncServer(&parameter) { [weak self] error, server in
      if let err = error {
        completion(err, nil)
        if let qchatServer = server {
          self?.deleteInvalidServer(server: qchatServer)
        }
      } else {
        if let qchatSever = server {
          self?.updateEveryoneRolePermission(server: qchatSever)
        }
        completion(nil, server)
      }
    }
  }

  public func createServer(parameter: NEQChatCreateServerParam,
                           _ completion: @escaping (NSError?, NEQChatCreateServerResult?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", name:\(parameter.name ?? "nil")")
    repo.createServer(param: parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func updateEveryoneRolePermission(server: NEQChatServer) {
    getEveryOneRole(server.serverId) { [weak self] error, everyoneRole in
      self?.didUpdateEveryoneDefaultPermission(server.serverId, everyoneRole)
    }
  }

  public func deleteInvalidServer(server: NEQChatServer) {
    guard let sid = server.serverId else {
      return
    }
    repo.deleteServer(sid) { error in
    }
  }

  func getEveryOneRole(_ serverId: UInt64?, _ completion: @escaping (NSError?, NEQChatServerRole?) -> Void) {
    var param = NEQChatGetServerRoleParam()
    param.serverId = serverId
    param.limit = 2
    repo.getRoles(param) { error, roles, sets in
      // 根据type找到everyone身份组
      var retRole: NEQChatServerRole?
      if let rs = roles {
        for role in rs {
          if role.type == .everyone {
            retRole = role
          }
        }
      }
      completion(error as NSError?, retRole)
    }
  }

  func didUpdateEveryoneDefaultPermission(_ serverId: UInt64?, _ role: NEQChatServerRole?) {
    print("everyone role : ", role as Any)

    var param = NEQChatUpdateServerRoleParam()
    param.serverId = serverId
    param.roleId = role?.roleId
    param.commands = [NEQChatPermissionStatusInfo]()

    let permissionTypes = [NEQChatPermissionType.manageServer, NEQChatPermissionType.sendMsg, NEQChatPermissionType.inviteToServer, NEQChatPermissionType.kickOthersInServer, NEQChatPermissionType.deleteOtherMsg, NEQChatPermissionType.manageChannel, NEQChatPermissionType.manageRole]

    for type in permissionTypes {
      var status = NEQChatPermissionStatusInfo()
      status.permissionType = type
      status.status = .Deny
      param.commands?.append(status)
    }

    // 禁止表情回复权限
    var status = NEQChatPermissionStatusInfo()
    status.customType = emojiAuthType
    status.status = .Deny
    param.commands?.append(status)

    NELog.infoLog(className(), desc: "mine craete notice server param: \(param)")

    repo.updateRole(param) { [weak self] error, role in
      NELog.infoLog(self?.className() ?? "", desc: "mine craete notice server roleProvider.updateRole error: \(error?.localizedDescription ?? "")")
    }
  }
}
