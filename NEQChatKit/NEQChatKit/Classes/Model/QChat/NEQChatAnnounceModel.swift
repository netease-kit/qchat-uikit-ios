//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class NEQChatAnnounceModel: NSObject {
  public var channelId: NSNumber? // 公告频道对应的唯一频道 id
  public var roleId: NSNumber? // 公告频道固定的管理员身份组 id
  public var emojiReplay = 1 // 是否允许服务器进行表情回复

  public func isInValid() -> Bool {
    if let cid = channelId?.int64Value, let rid = roleId?.int64Value, cid > 0, rid > 0 {
      return false
    }
    return true
  }
}
