
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
class MessageCallRecordModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?

  required init(message: NIMMessage?) {
    super.init(message: message)
    type = .rtcCallRecord
    var isAuiodRecord = false
    if let object = message?.messageObject as? NIMRtcCallRecordObject, let isSend = message?.isOutgoingMsg {
      attributeStr = NSMutableAttributedString()
      var image: UIImage?
      var bound = CGRect.zero
      let offset: CGFloat = -1
      if object.callType == .audio {
        isAuiodRecord = true
        image = coreLoader.loadImage("audio_record")
        bound = CGRect(x: 0, y: offset - 5, width: 24, height: 24)
      } else {
        image = coreLoader.loadImage("video_record")
        bound = CGRect(x: 0, y: offset, width: 24, height: 14)
      }
      switch object.callStatus {
      case .complete:
        var timeString = "00:00"
        if let duration = object.durations[NIMSDK.shared().loginManager.currentAccount()] {
          timeString = Date.getFormatPlayTime(duration.doubleValue)
        }
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_complete") + " \(timeString)"))
      case .canceled:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_canceled")))
      case .rejected:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_rejected")))
      case .timeout:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_timeout")))
      case .busy:
        attributeStr?.append(NSAttributedString(string: chatLocalizable("call_busy")))
      default:
        break
      }
      let attachment = NSTextAttachment()
      attachment.image = image
      attachment.bounds = bound
      if isSend {
        attributeStr?.append(NSAttributedString(string: " "))
        attributeStr?.append(NSAttributedString(attachment: attachment))
      } else {
        attributeStr?.insert(NSAttributedString(string: " "), at: 0)
        attributeStr?.insert(NSAttributedString(attachment: attachment), at: 0)
      }

      attributeStr?.addAttribute(NSAttributedString.Key.font, value: NEKitChatConfig.shared.ui.messageFont, range: NSMakeRange(0, attributeStr?.length ?? 0))

      attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: NEKitChatConfig.shared.ui.messageColor, range: NSMakeRange(0, attributeStr?.length ?? 0))
    }

    let textSize = NEChatUITool.getSizeWithAtt(
      att: attributeStr ?? NSAttributedString(string: ""),
      font: DefaultTextFont(16),
      maxSize: CGSize(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    )

    var h = qChat_min_h
    h = textSize.height + (isAuiodRecord ? 20 : 24)
    contentSize = CGSize(width: textSize.width + qChat_cell_margin * 2, height: h)

    height = Float(contentSize.height + qChat_margin) + fullNameHeight
  }
}
