
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat
import NIMSDK

@objcMembers
public class QChatApnsProvider: NSObject, NIMQChatApnsManagerDelegate {
  public static let shared = QChatApnsProvider()
  override private init() {
    super.init()
    NIMSDK.shared().qchatApnsManager.add(self)
  }

  deinit {
    NIMSDK.shared().qchatApnsManager.remove(self)
  }

  public func getUserPushNotificationConfigByServer(server: [NSNumber], _ completion: @escaping (Error?, [NIMQChatUserPushNotificationConfig]?) -> Void) {
    NIMSDK.shared().qchatApnsManager.getUserPushNotificationConfig(byServer: server, completion: completion)
  }

  public func updatePushNotificationByProfile(profile: NIMPushNotificationProfile, server: UInt64, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatApnsManager.update(profile, server: server, completion: completion)
  }
}
