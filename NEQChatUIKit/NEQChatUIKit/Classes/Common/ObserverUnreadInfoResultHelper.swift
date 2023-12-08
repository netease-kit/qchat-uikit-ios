//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

public class ObserverUnreadInfoResultHelper: NSObject, NIMLoginManagerDelegate {
  // 单例
  public static let shared = ObserverUnreadInfoResultHelper()

  // 未读数记录
  private var unreadInfoResultDic = [UInt64: UInt]()

  // 监听账号切换，清理未读数缓存
  public func onLogin(_ step: NIMLoginStep) {
    if step == .logout {
      unreadInfoResultDic.removeAll()
    }
  }

  override private init() {
    super.init()
    NIMSDK.shared().loginManager.add(self)
  }

  // 总未读数
  public func getTotalUnreadCountForServer() -> UInt {
    var count: UInt = 0
    unreadInfoResultDic.forEach { (key: UInt64, value: UInt) in
      count = count + value
    }
    return count
  }

  // 某个服务的未读数
  public func getUnreadCountForServer(serverId: UInt64) -> UInt {
    if let count = unreadInfoResultDic[serverId] {
      return count
    }
    return 0
  }

  // 添加某个服务的未读数
  public func appendUnreadCountForServer(serverId: UInt64, count: UInt) {
    unreadInfoResultDic[serverId] = count
  }

  // 清除所有未读数
  public func clearAllUnreadCount() {
    unreadInfoResultDic.removeAll()
  }

  // 清除某个server 的未读数
  public func clearUnreadCountForServer(serverId: UInt64) {
    unreadInfoResultDic.removeValue(forKey: serverId)
  }
}
