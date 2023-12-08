// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit
import NIMSDK

typealias IdGroupViewModelBlock = () -> Void

typealias ServerMagagerRolePermissionChange = () -> Void

@objcMembers
public class QChatIdGroupViewModel: NSObject, NIMQChatMessageManagerDelegate {
  let repo = QChatRepo.shared
  var topDatas = [QChatIdGroupModel]()
  var datas = [QChatIdGroupModel]()
  var sortBtnCellDatas = [QChatIdGroupModel]() // only one
  weak var delegate: ViewModelDelegate?

  var changeBlock: ServerMagagerRolePermissionChange?

  var hasManagerRolePermission = false

  var serverId: UInt64?

  var limitCount = 20

  private let className = "IdGroupViewModelBlock"

  override init() {
    super.init()
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  deinit {
    NIMSDK.shared().qchatMessageManager.remove(self)
  }

  func getRoles(_ serverId: UInt64?, _ refresh: Bool = false, _ block: IdGroupViewModelBlock?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", serverId:\(serverId ?? 0)")
    var param = GetServerRoleParam()
    param.serverId = serverId
    param.limit = limitCount
    if let last = datas.last, let pri = last.role?.priority, refresh == false {
      param.priority = pri
    }
    weak var weakSelf = self
    print("param : ", param)

    repo.getRoles(param) { error, roles, sets in
      if let err = error {
        weakSelf?.delegate?.dataDidError(err)
      } else if let rs = roles {
        print("get roles success : ", rs.count)
        weakSelf?.parseData(rs, refresh)
      }
      if let completion = block {
        completion()
      }
    }
  }

  func parseData(_ roles: [ServerRole], _ refresh: Bool) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", roles.count:\(roles.count)")
    var models = [QChatIdGroupModel]()
    roles.forEach { role in
      print("get data proprity : ", role.priority as Any)
      let model = QChatIdGroupModel(role)
      models.append(model)
    }
    filterData(models, refresh)
    if roles.count < limitCount {
      delegate?.dataNoMore?()
    }
  }

  func filterData(_ models: [QChatIdGroupModel], _ refresh: Bool) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", models.count:\(models.count)")
    if refresh == true {
      topDatas.removeAll()
      datas.removeAll()
      sortBtnCellDatas.removeAll()
    }

    if let first = models.first {
      topDatas.append(first)
    }
    if models.count >= 2 {
      datas.append(contentsOf: models.suffix(models.count - 1))
    }

    if datas.count > 0 {
      if let first = sortBtnCellDatas.first {
        first.idName = localizable("qchat_id_group") + "(\(datas.count))"
      } else {
        let data = QChatIdGroupModel()
        data.idName = localizable("qchat_id_group") + "(\(datas.count))"
        sortBtnCellDatas.append(data)
      }
    }
    delegate?.dataDidChange()
  }

  func addRole(_ role: ServerRole) {
    var models = [QChatIdGroupModel]()
    models.append(contentsOf: topDatas)
    models.append(contentsOf: datas)
    models.append(QChatIdGroupModel(role))
    topDatas.removeAll()
    datas.removeAll()
    filterData(models, false)
  }

  public func checkPermission(_ serverId: UInt64?, _ completion: @escaping (NSError?, Bool) -> Void) {
    guard let sid = serverId else {
      return
    }
    repo.checkPermission(serverId: sid, channelId: nil, permissionType: .manageRole) { [weak self] error, permission in
      self?.hasManagerRolePermission = permission
      completion(error, permission)
    }
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    result.systemNotifications?.forEach { [weak self] systemNotification in
      if let sid = self?.serverId, sid == systemNotification.serverId {
        if systemNotification.type == .serverRoleAuthUpdate {
          self?.checkPermission(self?.serverId) { error, permission in
            if let block = self?.changeBlock {
              block()
            }
          }
        }
      }
    }
  }
}
