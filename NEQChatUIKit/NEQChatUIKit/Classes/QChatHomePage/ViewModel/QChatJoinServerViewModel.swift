//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

@objcMembers
public class QChatJoinServerViewModel: NSObject {
  let repo = QChatRepo.shared

  public var isAnnouncement = false

  public func getServers(parameter: QChatGetServersParam,
                         _ completion: @escaping (NSError?, [QChatServer]) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", serverIds.count:\(parameter.serverIds?.count ?? 0)"
    )
    repo.getServers(parameter) { error, serverResult in

      var retServers = [QChatServer]()
      serverResult?.servers.forEach { [weak self] server in
        if self?.isAnnouncement == true {
          if server.announce != nil, server.announce?.isInValid() == false {
            retServers.append(server)
          }
        } else {
          if server.announce == nil {
            retServers.append(server)
          }
        }
      }
      completion(error, retServers)
    }
  }
}
