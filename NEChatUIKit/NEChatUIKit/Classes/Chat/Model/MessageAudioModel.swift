
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
class MessageAudioModel: MessageContentModel {
  public var duration: Int = 0
  public var isPlaying = false
  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .audio
    var audioW = 96.0
    let audioTotalWidth = 265.0
    // contentSize
    if let obj = message?.messageObject as? NIMAudioObject {
      duration = obj.duration / 1000
      if duration > 2 {
        audioW = min(Double(duration) * 8 + audioW, audioTotalWidth)
      }
    }
    contentSize = CGSize(width: audioW, height: qChat_min_h)
    height = Float(contentSize.height + qChat_margin) + fullNameHeight
  }
}
