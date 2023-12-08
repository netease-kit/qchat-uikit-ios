// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit
import UIKit

@objcMembers
public class QChatPermissionViewModel: NSObject {
  let permission = QChatPermissionModel()

  var commons = [QChatPermissionCellModel]()

  var messages = [QChatPermissionCellModel]()

  var members = [QChatPermissionCellModel]()

  let repo = QChatRepo.shared

  var delegate: ViewModelDelegate?

  var hasPermissionKey = [String: String]()

  private let className = "QChatPermissionViewModel"

  override init() {}

  func getData(_ serverRole: ServerRole) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverRole.serverId ?? 0)")
    weak var weakSelf = self
//        print("get data authors : ", serverRole.auths as Any)
    serverRole.auths?.forEach { info in
      if info.status == .Allow {
        if let key = info.permissionType?.rawValue {
          weakSelf?.hasPermissionKey[key] = key
        }
      }
    }
    loadData(permission.commonPermission, permission.commonPermissionDic, &commons)
    loadData(permission.messagePermission, permission.messagePermissionDic, &messages)
    loadData(permission.memberPermission, permission.memberPermissionDic, &members)

//        delegate?.dataDidChange()
  }

  func loadData(_ keys: [String], _ keyValues: [String: String],
                _ datas: inout [QChatPermissionCellModel]) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", keys.count:\(keys.count)")
    for index in 0 ..< keys.count {
      let model = QChatPermissionCellModel()
      model.permission = permission
      let key = keys[index]
      let name = keyValues[key]
      model.title = name
      model.permissionKey = key
      if let value = permission.value(forKey: key) as? String {
        if hasPermissionKey[value] != nil {
          model.hasPermission = true
        }
      }
      model.cornerType = .none
      if index == 0 {
        model.cornerType = model.cornerType.union(.topLeft.union(.topRight))
      }
      if index == keys.count - 1 {
        model.cornerType = model.cornerType.union(.bottomLeft).union(.bottomRight)
      }
      datas.append(model)
    }
  }
}
