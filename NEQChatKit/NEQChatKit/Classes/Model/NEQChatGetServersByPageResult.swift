
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatGetServersByPageResult {
  public var servers = [NEQChatServer]()

  init(serversResult: NIMQChatGetServersByPageResult?) {
    guard let serverArray = serversResult?.servers else { return }

    for server in serverArray {
      let itemModel = NEQChatServer(server: server)
      servers.append(itemModel)
    }
  }

  public init() {}
}
