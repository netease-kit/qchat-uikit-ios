
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEQChatKit
import NIMSDK

public class QChatMessageHelper {
  // 获取图片合适尺寸
  public class func getSizeWithMaxSize(_ maxSize: CGSize, size: CGSize, miniWH: CGFloat) -> CGSize {
    var realSize = CGSize.zero

    if min(size.width, size.height) > 0 {
      if size.width > size.height {
        // 宽大 按照宽给高
        let width = CGFloat(min(maxSize.width, size.width))
        realSize = CGSize(width: width, height: width * size.height / size.width)
        if realSize.height < miniWH {
          realSize.height = miniWH
        }
      } else {
        // 高大 按照高给宽
        let height = CGFloat(min(maxSize.height, size.height))
        realSize = CGSize(width: height * size.width / size.height, height: height)
        if realSize.width < miniWH {
          realSize.width = miniWH
        }
      }
    } else {
      realSize = maxSize
    }

    return realSize
  }

  public static func getCountLabel(_ count: Int) -> String {
    if count > 999_999 {
      return "\(count / 1_000_000)m"
    }
    if count > 999 {
      return "\(count / 1000)k"
    }
    return "\(count)"
  }

  // 消息长按操作列表
  public static func avalibleOperationsForMessage(_ model: QChatMessageFrame?,
                                                  enableEdit: Bool,
                                                  isAnnouncement: Bool = false) -> [QChatOperationItem]? {
    var items = [QChatOperationItem]()

    if model?.message?.messageType == .text {
      items.append(QChatOperationItem.copyItem())
    }

    if enableEdit {
      if model?.message?.deliveryState == .deliveried, !isAnnouncement {
        items.append(QChatOperationItem.recallItem())
      }
      items.append(QChatOperationItem.deleteItem())
    }
    return items
  }

  // 是否是撤回的消息
  public static func isRevokeMessage(event: NIMQChatUpdateMessageEvent) -> (Bool, String?) {
    if event.message.isRevoked {
      let revokeMessageContent = UserDefaults.standard.value(forKey: event.message.serverID)
      return (true, revokeMessageContent as? String)
    }
    return (false, nil)
  }

  // 是否是撤回的消息
  public static func isRevokeMessage(message: NIMQChatMessage) -> (Bool, String?) {
    if message.isRevoked {
      let revokeMessageContent = UserDefaults.standard.value(forKey: message.serverID)
      return (true, revokeMessageContent as? String)
    }
    return (false, nil)
  }

  // 是否是删除的消息
  public static func isDeleteMessage(event: NIMQChatUpdateMessageEvent) -> Bool {
    if let ext = event.updateParam.extension,
       let extDic = String.dictionaryFromString(string: ext),
       let isDelete = extDic[deleteMessageFlag] as? Bool, isDelete {
      return true
    }
    return false
  }

  /// 固定的快捷表情id
  public static func quickEmojiIDList() -> [String] {
    ["emoticon_emoji_84", "emoticon_emoji_0", "emoticon_emoji_21", "emoticon_emoji_85", "emoticon_emoji_86", "emoticon_emoji_55", "emoticon_emoji_48"]
  }
}
