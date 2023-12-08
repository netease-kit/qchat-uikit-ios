//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import UIKit

@objc
@objcMembers
open class QChatSquareServer: NSObject {
  public var server: QChatServer?
  public var isJoinedServer = false // 是否已经加入server
}
