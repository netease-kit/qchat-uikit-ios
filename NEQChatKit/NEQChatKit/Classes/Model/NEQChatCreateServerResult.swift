
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatCreateServerResult {
  public var server: NEQChatServer?

  init(serverResult: NIMQChatCreateServerResult?) {
    server = NEQChatServer(server: serverResult?.server)
  }
}
