//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEQChatKit
import UIKit

class QChatWhiteBlackViewModel: NSObject {
  let repo = QChatRepo.shared

  public func getOwner(_ serverId: UInt64?, _ completion: @escaping (String?) -> Void) {
    guard let sid = serverId else {
      return
    }
    let param = NEQChatGetServersParam(serverIds: [NSNumber(value: sid)])
    repo.getServers(param) { error, result in
      if let server = result?.servers.first, sid == server.serverId {
        completion(server.owner)
      }
    }
  }
}
