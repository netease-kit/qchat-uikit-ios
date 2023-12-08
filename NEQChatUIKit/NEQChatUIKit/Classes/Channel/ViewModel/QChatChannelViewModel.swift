// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NEQChatKit
import NIMSDK

public protocol QChatChannelViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshData()
  func didReRequestData()
  func didCheckPermission()
}

@objcMembers
public class QChatChannelViewModel: NSObject, NIMQChatMessageManagerDelegate {
  public var serverId: UInt64
  public var name: String?
  public var topic: String?
  public var type: ChannelType = .messageType
  public var isPrivate: Bool = false
  private let className = "QChatChannelViewModel"
  public var lastMsgDic = [UInt64: QChatLastMessageModel]()

  public weak var delegate: QChatChannelViewModelDelegate?

  public let repo = QChatRepo.shared

  public init(serverId: UInt64) {
    self.serverId = serverId
  }

  override public init() {
    serverId = 0
    super.init()
    QChatSystemMessageProvider.shared.addDelegate(delegate: self)
    NotificationCenter.default.addObserver(self, selector: #selector(revokeMsgNoti(noti:)), name: NSNotification.Name(rawValue: revokeMessageFlag), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteMsgNoti(noti:)), name: NSNotification.Name(rawValue: deleteMessageFlag), object: nil)
  }

  public func createChannel(_ completion: @escaping (NSError?, ChatChannel?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function)
    let visibleType: ChannelVisibleType = isPrivate ? .isPrivate : .isPublic
    let param = CreateChannelParam(
      serverId: serverId,
      name: name ?? "",
      topic: topic,
      visibleType: visibleType
    )
    QChatChannelProvider.shared.createChannel(param: param) { error, channel in
      completion(error, channel)
    }
  }

  public func getChannelsByPage(_ serverid: UInt64?, _ timeTag: TimeInterval, _ completion: @escaping (NSError?, QChatGetChannelsByPageResult?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", serverId:\(serverid ?? 0)"
    )
    if let sid = serverid {
      serverId = sid
      weak var weakSelf = self
      repo.fetchChannelsByServerIdWithLastMessage(sid, timeTag, 20) { error, result, lastMsgDic in
        lastMsgDic?.forEach { (key: NSNumber, value: NIMQChatMessage) in
          weakSelf?.lastMsgDic[key.uint64Value] = QChatLastMessageModel(message: value)
        }
        completion(error, result)
      }
    }
  }

  public func getChannelsByPage(parameter: QChatGetChannelsByPageParam,
                                _ completion: @escaping (NSError?, QChatGetChannelsByPageResult?)
                                  -> Void) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", serverId:\(parameter.serverId ?? 0)"
    )
    if let sid = parameter.serverId {
      serverId = sid
    }

    QChatChannelProvider.shared.getChannelsByPage(param: parameter) { error, channelResult in
      completion(error, channelResult)
    }
  }

  public func onRecvMessages(_ messages: [NIMQChatMessage]) {
    var isNeedRefresh = false
    messages.forEach { chatMessage in
      if chatMessage.qchatServerId == serverId {
        if checkLastMsgReplaceEnable(channelId: chatMessage.qchatChannelId, message: chatMessage) == true {
          lastMsgDic[chatMessage.qchatChannelId] = QChatLastMessageModel(message: chatMessage)
          isNeedRefresh = true
        }
      }
    }
    if isNeedRefresh == true {
      delegate?.didNeedRefreshData()
    }
  }

  public func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?) {
    if message.qchatServerId == serverId {
      lastMsgDic[message.qchatChannelId] = QChatLastMessageModel(message: message)
      delegate?.didNeedRefreshData()
    }
  }

  public func onMessageUpdate(_ event: NIMQChatUpdateMessageEvent) {
    if serverId == event.message.qchatServerId {
      didUpdateMessage(event.message)
    }
  }

  func didUpdateMessage(_ message: NIMQChatMessage) {
    if message.isDeleted == true {
      if checkLastMsgReplaceEnable(channelId: message.qchatChannelId, message: message) == true {
        lastMsgDic.removeValue(forKey: message.qchatChannelId)
        getLastMessage(NSNumber(value: message.qchatChannelId))
      }
    } else if message.isRevoked == true {
      setLastMessage(channelId: message.qchatChannelId, message: message)
      delegate?.didNeedRefreshData()
    }
  }

  private func getLastMessage(_ channelId: NSNumber) {
    repo.getLastMessage(serverId, [channelId]) { [weak self] err, lastMigDic in
      if err == nil {
        if let message = lastMigDic?[channelId] {
          self?.setLastMessage(channelId: channelId.uint64Value, message: message)
        } else {
          self?.lastMsgDic.removeValue(forKey: channelId.uint64Value)
        }
        self?.delegate?.didNeedRefreshData()
      } else {
        NELog.infoLog(QChatChannelViewModel.className(), desc: "get last msg err : \(err?.localizedDescription ?? "")")
      }
    }
  }

  private func setLastMessage(channelId: UInt64, message: NIMQChatMessage) {
    if lastMsgDic[channelId] != nil {
      if checkLastMsgReplaceEnable(channelId: channelId, message: message) {
        lastMsgDic[channelId] = QChatLastMessageModel(message: message)
      }
    } else {
      lastMsgDic[channelId] = QChatLastMessageModel(message: message)
    }
  }

  // 检查最后一条消息是否需要跟新
  private func checkLastMsgReplaceEnable(channelId: UInt64, message: NIMQChatMessage) -> Bool {
    if let lastMsg = lastMsgDic[channelId] {
      if lastMsg.message.timestamp <= message.timestamp {
        return true
      }
      return false
    }
    return true
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    var isNeedRefresh = false
    var isNeedCheckPermission = false
    result.systemNotifications?.forEach { [weak self] noti in
      if noti.serverId != self?.serverId {
        return
      }
      if noti.type == .channelVisibilityUpdate {
        isNeedRefresh = true
      } else if noti.type == .serverRoleAuthUpdate {
        isNeedCheckPermission = true
      }
    }

    if isNeedRefresh == true {
      delegate?.didReRequestData()
    }

    if isNeedCheckPermission {
      delegate?.didCheckPermission()
    }
  }

  func revokeMsgNoti(noti: Notification) {
    if let revokeParam = noti.object as? NIMQChatRevokeMessageParam {
      let msg = revokeParam.message
      if checkLastMsgReplaceEnable(channelId: msg.qchatChannelId, message: msg) {
        let messageModel = QChatLastMessageModel(message: msg)
        messageModel.isRevoked = true
        lastMsgDic[msg.qchatChannelId] = messageModel
        delegate?.didNeedRefreshData()
      }
    }
  }

  func deleteMsgNoti(noti: Notification) {
    if let deleteParam = noti.object as? NIMQChatDeleteMessageParam {
      let msg = deleteParam.message
      if checkLastMsgReplaceEnable(channelId: msg.qchatChannelId, message: msg) {
        lastMsgDic.removeValue(forKey: msg.qchatChannelId)
        getLastMessage(NSNumber(value: msg.qchatChannelId))
      }
    }
  }

  func checkManageChannelPermission(severId: UInt64, channelId: UInt64, _ completion: @escaping (NSError?, Bool) -> Void) {
    repo.checkPermission(serverId: serverId, channelId: channelId, permissionType: .manageChannel) { error, enable in
      completion(error, enable)
    }
  }
}
