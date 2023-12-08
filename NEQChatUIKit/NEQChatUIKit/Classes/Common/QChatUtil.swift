//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objc
public class QChatUtil: NSObject {
  class func getLastMsgContent(_ msg: NIMQChatMessage) -> String {
    var content = ""
    switch msg.messageType {
    case .text:
      content = msg.text ?? ""
    case .image:
      content = localizable("picture")
    case .audio:
      content = localizable("voice")
    case .video:
      content = localizable("video")
    case .file:
      content = localizable("file")
    case .location:
      content = localizable("location")
    default:
      content = localizable("unknown")
    }
    return content
  }
}
