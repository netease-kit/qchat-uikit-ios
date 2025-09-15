
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatGetServersResult {
  public var servers = [NEQChatServer]()

  init(serversResult: NIMQChatGetServersResult?) {
    guard let serversArray = serversResult?.servers else { return }
    for server in serversArray {
      let itemModel = NEQChatServer(server: server)
      servers.append(itemModel)
    }
  }
}
