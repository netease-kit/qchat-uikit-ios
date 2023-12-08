//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit

@objcMembers
public class QChatMineCreateViewModel: NSObject {
  let repo = QChatRepo.shared

  public func createAnncServer(parameter: inout CreateServerParam,
                               _ completion: @escaping (NSError?, QChatServer?) -> Void) {
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

  public func createServer(parameter: CreateServerParam,
                           _ completion: @escaping (NSError?, CreateServerResult?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", name:\(parameter.name ?? "nil")")
    repo.createServer(param: parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func updateEveryoneRolePermission(server: QChatServer) {
    getEveryOneRole(server.serverId) { [weak self] error, everyoneRole in
      self?.didUpdateEveryoneDefaultPermission(server.serverId, everyoneRole)
    }
  }

  public func deleteInvalidServer(server: QChatServer) {
    guard let sid = server.serverId else {
      return
    }
    repo.deleteServer(sid) { error in
    }
  }

  func getEveryOneRole(_ serverId: UInt64?, _ completion: @escaping (NSError?, ServerRole?) -> Void) {
    var param = GetServerRoleParam()
    param.serverId = serverId
    param.limit = 2
    repo.getRoles(param) { error, roles, sets in
      // 根据type找到everyone身份组
      var retRole: ServerRole?
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

  func didUpdateEveryoneDefaultPermission(_ serverId: UInt64?, _ role: ServerRole?) {
    print("everyone role : ", role as Any)

    var param = UpdateServerRoleParam()
    param.serverId = serverId
    param.roleId = role?.roleId
    param.commands = [StatusInfo]()

    let permissionTypes = [ChatPermissionType.manageServer, ChatPermissionType.sendMsg, ChatPermissionType.inviteToServer, ChatPermissionType.kickOthersInServer, ChatPermissionType.deleteOtherMsg, ChatPermissionType.manageChannel, ChatPermissionType.manageRole]

    permissionTypes.forEach { type in
      var status = StatusInfo()
      status.permissionType = type
      status.status = .Deny
      param.commands?.append(status)
    }

    // 禁止表情回复权限
    var status = StatusInfo()
    status.customType = emojiAuthType
    status.status = .Deny
    param.commands?.append(status)

    NELog.infoLog(className(), desc: "mine craete notice server param: \(param)")

    repo.updateRole(param) { [weak self] error, role in
      NELog.infoLog(self?.className() ?? "", desc: "mine craete notice server roleProvider.updateRole error: \(error?.localizedDescription ?? "")")
    }
  }
}
