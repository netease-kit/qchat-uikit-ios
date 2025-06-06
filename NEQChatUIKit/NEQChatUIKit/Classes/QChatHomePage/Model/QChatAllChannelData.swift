
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit

protocol QChatAllChannelDataDelegate: NSObjectProtocol {
  func dataGetSuccess(_ serverId: UInt64, _ channels: [NEQChatChatChannel])
  func dataGetError(_ serverId: UInt64, _ error: Error)
}

@objcMembers
public class QChatAllChannelData: NSObject {
  var repo = QChatRepo.shared
  let limit = 200
  weak var delegate: QChatAllChannelDataDelegate?
  var serverId: UInt64 = 0
  var channelInfos = [NEQChatChatChannel]()
  public var nextTimetag: TimeInterval = 0

  init(sid: UInt64) {
    super.init()
    serverId = sid
    getChannelData()
  }

  func getChannelData() {
    var param = NEQChatGetChannelsByPageParam(timeTag: nextTimetag, serverId: serverId)
    param.limit = 200
    weak var weakSelf = self
    repo.getChannelsByPage(param: param) { error, result in
      if let err = error {
        if let sid = weakSelf?.serverId {
          weakSelf?.delegate?.dataGetError(sid, err)
        }
      } else {
        if let datas = result?.channels {
          weakSelf?.channelInfos.append(contentsOf: datas)
        }
        if let nextTimeTag = result?.nextTimetag {
          weakSelf?.nextTimetag = nextTimeTag
        }
        if let hasMore = result?.hasMore, hasMore == true {
          weakSelf?.getChannelData()
        } else {
          print("getChannelData finish : ", weakSelf?.serverId as Any)
          if let sid = weakSelf?.serverId, let channels = weakSelf?.channelInfos {
            weakSelf?.delegate?.dataGetSuccess(sid, channels)
          }
        }
      }
    }
  }
}
