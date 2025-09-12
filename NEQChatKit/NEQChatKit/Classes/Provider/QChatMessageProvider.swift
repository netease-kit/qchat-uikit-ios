
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NIMQChat
import NIMSDK

public protocol QChatMessageProviderDelegate: NSObjectProtocol {
  func onReceive(_ messages: [NIMQChatMessage])

  func onUnReadChange(_ unreads: [NIMQChatUnreadInfo]?, _ lastUnreads: [NIMQChatUnreadInfo]?)

  func serverUnreadInfoChanged(_ serverUnreadInfoDic: [NSNumber: NIMQChatServerUnreadInfo])
}

@objcMembers
public class QChatMessageProvider: NSObject, NIMQChatManagerDelegate,
  NIMEventSubscribeManagerDelegate {
  public static let shared = QChatMessageProvider()

  private let mutiDelegate = MultiDelegate<QChatMessageProviderDelegate>(strongReferences: false)

  override init() {
    super.init()
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  public func addDelegate(_ delegate: QChatMessageProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(_ delegate: QChatMessageProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }

  /// 获取channel最后一条消息
  public func getLastMessage(param: NIMQChatGetLastMessageOfChannelsParam, _ completion: @escaping (Error?, [NSNumber: NIMQChatMessage]?) -> Void) {
    NIMSDK.shared().qchatMessageManager.getLastMessage(ofChannels: param) { error, result in
      completion(error, result?.lastMessageOfChannelDic)
      print("getLastMessage error: \(String(describing: error)) result: \(String(describing: result))")
    }
  }

  /// 撤回圈组消息
  public func revokeMessage(param: NIMQChatRevokeMessageParam, completion: NIMQChatUpdateMessageHandler?) {
    NIMSDK.shared().qchatMessageManager.revokeMessage(param, completion: completion)
  }

  public func deleteMessage(param: NIMQChatDeleteMessageParam, completion: NIMQChatUpdateMessageHandler?) {
    NIMSDK.shared().qchatMessageManager.deleteMessage(param, completion: completion)
  }

  /// 发送快捷评论
  public func addQuickComment(type: Int64, to message: NIMQChatMessage, completion: NIMQChatHandler?) {
    NIMSDK.shared().qchatMessageExtendManager.addQuickCommentType(type, to: message, completion: completion)
  }

  public func deleteQuickComment(type: Int64, to message: NIMQChatMessage, completion: NIMQChatHandler?) {
    NIMSDK.shared().qchatMessageExtendManager.deleteQuickCommentType(type, to: message, completion: completion)
  }

  public func fetchQuickComments(messages: [NIMQChatMessage], completion: @escaping NIMQChatFetchQuickCommentsByMsgsHandler) {
    NIMSDK.shared().qchatMessageExtendManager.fetchQuickComments(messages, completion: completion)
  }
}

extension QChatMessageProvider: NIMQChatMessageManagerDelegate {
  public func onRecvMessages(_ messages: [NIMQChatMessage]) {
//        print("on recv message : ", messages)
    mutiDelegate.invokeDelegates { delegate in
      delegate.onReceive(messages)
    }
  }

  public func unreadInfoChanged(_ event: NIMQChatUnreadInfoChangedEvent) {
//        print("un read info change : ", event)
    mutiDelegate.invokeDelegates { delegate in
      delegate.onUnReadChange(event.unreadInfo, event.lastUnreadInfo)
    }
  }

  // server 未读数改变回到
  public func serverUnreadInfoChanged(_ serverUnreadInfoDic: [NSNumber: NIMQChatServerUnreadInfo]) {
    mutiDelegate.invokeDelegates { delegate in
      delegate.serverUnreadInfoChanged(serverUnreadInfoDic)
    }
  }
}
