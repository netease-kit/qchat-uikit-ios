// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit

@objcMembers
public class QChatUpdateChannelViewModel: NSObject {
  public var channel: NEQChatChatChannel?
  // 临时记录修改的值
  public var channelTmp: NEQChatChatChannel?
  private let className = "QChatUpdateChannelViewModel"

  init(channel: NEQChatChatChannel?) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    self.channel = channel
    channelTmp = channel
  }

  func updateChannelInfo(completion: @escaping (NSError?, NEQChatChatChannel?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    var param = NEQChatUpdateChannelParam(channelId: channel?.channelId)
    param.name = channelTmp?.name
    param.topic = channelTmp?.topic
    param.custom = channelTmp?.custom
    QChatRepo.shared.updateChannelInfo(param) { [weak self] error, channel in
      if error == nil {
        self?.channel = channel
      }
      completion(error, channel)
    }
  }

  func deleteChannel(completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    QChatChannelProvider.shared.deleteChannel(channelId: channel?.channelId, completion)
  }
}
