//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMQChat
import NIMSDK
import UIKit

@objc
public class QChatUtil: NSObject {
  class func getLastMsgContent(_ msg: NIMQChatMessage) -> String {
    var content = ""
    switch msg.messageType {
    case NIMMessageType.text.rawValue:
      content = msg.text ?? ""
    case NIMMessageType.image.rawValue:
      content = localizable("picture")
    case NIMMessageType.audio.rawValue:
      content = localizable("voice")
    case NIMMessageType.video.rawValue:
      content = localizable("video")
    case NIMMessageType.file.rawValue:
      content = localizable("file")
    case NIMMessageType.location.rawValue:
      content = localizable("location")
    default:
      content = localizable("unknown")
    }
    return content
  }
}
