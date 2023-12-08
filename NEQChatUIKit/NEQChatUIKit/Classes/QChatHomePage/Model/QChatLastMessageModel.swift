//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

public class QChatLastMessageModel: NSObject {
  public var isRevoked = false

  public var isDeleted = false

  public var message: NIMQChatMessage

  public init(message: NIMQChatMessage) {
    self.message = message
    isRevoked = message.isRevoked
    isDeleted = message.isDeleted
  }
}
