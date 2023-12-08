//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

public protocol QChatSquareViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshData()
}

public class QChatSquareViewModel: NSObject, NIMQChatMessageManagerDelegate {
  let repo = QChatRepo.shared

  var datas = [QChatSquareServer]()

  var delegate: QChatSquareViewModelDelegate?

  var serverDic = [UInt64: QChatSquareServer]()

  override public init() {
    super.init()
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  deinit {
    NIMSDK.shared().qchatMessageManager.remove(self)
  }

  func checkJoinServer(servers: [QChatSquareServer], _ completion: @escaping (Error?) -> Void) {
    var items = [QChatGetServerMemberItem]()
    let currentAccid = QChatKitClient.instance.imAccid()
    weak var weakSelf = self
    servers.forEach { server in
      if let sid = server.server?.serverId {
        let item = QChatGetServerMemberItem(serverId: sid, accid: currentAccid)
        items.append(item)
        weakSelf?.serverDic[sid] = server
      }
    }
    let param = QChatGetServerMembersParam(serverAccIds: items)
    repo.getServerMembers(param: param) { error, members in
      members?.forEach { member in
        if let sid = member.serverId {
          weakSelf?.serverDic[sid]?.isJoinedServer = true
        }
      }
      completion(error)
    }
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    var isChange = false
    result.systemNotifications?.forEach { [weak self] systemNoti in
      if let server = self?.serverDic[systemNoti.serverId] {
        if systemNoti.type == .serverMemberApplyDone || systemNoti.type == .serverMemberInviteAccept, systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
          server.isJoinedServer = true
          isChange = true
        } else if systemNoti.type == .serverMemberKick || systemNoti.type == .serverMemberLeave, systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
          server.isJoinedServer = false
          isChange = true
        }
      }
    }

    if isChange == true {
      delegate?.didNeedRefreshData()
    }
  }
}
