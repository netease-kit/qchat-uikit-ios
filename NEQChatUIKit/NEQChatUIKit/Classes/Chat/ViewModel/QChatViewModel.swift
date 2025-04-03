// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import NIMQChat

@objc
public protocol QChatViewModelDelegate: NSObjectProtocol {
  func onRecvMessages(_ messages: [NIMQChatMessage])
  func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult)
  func willSend(_ message: NIMQChatMessage)
  func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?)
  func send(_ message: NIMQChatMessage, progress: Float)
  func onDeleteMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath])
  func onRevokeMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath])
  func onReloadMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath])
}

@objcMembers
public class QChatViewModel: NSObject, NIMQChatMessageManagerDelegate {
  public var channel: NEQChatChatChannel?
  public var server: NEQChatServer?
  public var messages: [QChatMessageFrame] = .init()
  public weak var delegate: QChatViewModelDelegate?
  private var lastMsg: NIMQChatMessage?
  public var repo = QChatRepo.shared
  public var operationModel: QChatMessageFrame?

  init(channel: NEQChatChatChannel?, server: NEQChatServer?) {
    NELog.infoLog(ModuleName + " " + QChatViewModel.className(), desc: #function)
    super.init()
    self.channel = channel
    self.server = server
    QChatSystemMessageProvider.shared.addDelegate(delegate: self)
  }

  deinit {
    QChatSystemMessageProvider.shared.removeDelegate(delegate: self)
  }

  public func sendTextMessage(text: String, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", text.count:\(text.count)")
    if text.count <= 0 {
      return
    }
    if let cid = channel?.channelId, let sid = channel?.serverId {
      let message = NIMQChatMessage()
      message.text = text
      message.from = QChatKitClient.instance.imAccid()
      QChatSystemMessageProvider.shared.sendMessage(
        message: message,
        session: NIMSession(forQChat: Int64(cid), qchatServerId: Int64(sid))
      ) { error in
        completion(error)
      }
    }
  }

  public func sendImageMessage(image: UIImage, _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if let cid = channel?.channelId, let sid = channel?.serverId {
      let message = NIMQChatMessage()
      message.messageObject = NIMImageObject(image: image)
      message.from = QChatKitClient.instance.imAccid()
      QChatSystemMessageProvider.shared.sendMessage(
        message: message,
        session: NIMSession(forQChat: Int64(cid), qchatServerId: Int64(sid))
      ) { error in
        completion(error)
      }
    }
  }

  public func sendAudioMessage(path: String, _ completion: @escaping (Error?) -> Void) {
    if let cid = channel?.channelId, let sid = channel?.serverId {
      let message = NIMQChatMessage()
      message.messageObject = NIMAudioObject(sourcePath: path)
      message.from = QChatKitClient.instance.imAccid()
      QChatSystemMessageProvider.shared.sendMessage(
        message: message,
        session: NIMSession(forQChat: Int64(cid), qchatServerId: Int64(sid))
      ) { error in
        completion(error)
      }
    }
  }

  // 查询本地消息
  public func getMessageHistory(_ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if let cid = channel?.channelId, let sid = channel?.serverId {
      let param = NIMQChatGetMessageCacheParam()
      param.serverId = sid
      param.channelId = cid

      QChatSystemMessageProvider.shared
        .getLocalMessage(param: param) { [weak self] error, messages in
          if let messageArray = messages, messageArray.count > 0 {
            self?.downloadAudioAttachment(messageArray)
            var userIds = [String]()
            var isTop = false
            for msg in messageArray {
              if msg == messageArray.last {
                self?.lastMsg = msg
                isTop = true
              }

              let messageFrame = self?.addTimeForHistoryMessage(msg, isTop: isTop) ?? QChatMessageFrame()
              messageFrame.isFromLocalCache = true
              if let userId = messageFrame.message?.from, !userIds.contains(userId) {
                userIds.append(userId)
              }
              self?.messages.insert(messageFrame, at: 0)
            }

            self?.getUserInfo(userIds: userIds) { error in
              completion(error)
            }
          } else {
            completion(error)
          }
        }
    } else {
      completion(NSError.paramError())
    }
  }

  public func getMoreMessageHistory(_ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if let cid = channel?.channelId, let sid = channel?.serverId {
      var param = NEQChatGetMessageHistoryParam(serverId: sid, channelId: cid)
      param.lastMsg = lastMsg
      QChatSystemMessageProvider.shared
        .getMessageHistory(param: param) { [weak self] error, messages in
          if let messageArray = messages, messageArray.count > 0 {
            self?.downloadAudioAttachment(messageArray)
            var userIds = [String]()
            var isTop = false
            for msg in messageArray {
              if msg == messageArray.last {
                self?.lastMsg = msg
                isTop = true
              }

              let messageFrame = self?.addTimeForHistoryMessage(msg, isTop: isTop) ?? QChatMessageFrame()
              messageFrame.isFromLocalCache = true
              if let userId = messageFrame.message?.from, !userIds.contains(userId) {
                userIds.append(userId)
              }
              self?.messages.insert(messageFrame, at: 0)
            }

            self?.getUserInfo(userIds: userIds) { error in

              let chunkMessages = messageArray.chunk(20)

              for chunkMessage in chunkMessages {
                self?.fetchQuickComments(messages: chunkMessage, completion: { error, result in
                  if let msgsComments = result?.msgIdQuickCommentDic {
                    self?.messages.forEach { msgFrame in
                      if msgFrame.message?.isRevoked == false {
                        // 已撤回消息不展示快捷评论
                        if let msgId = msgFrame.message?.serverID, let msgComments = msgsComments[msgId] {
                          msgFrame.quickComments = msgComments.commentArray
                        }
                      }
                    }
                  }
                  completion(error)
                })
              }
            }
          } else {
            completion(error)
          }
        }
    } else {
      completion(NSError.paramError())
    }
  }

  public func downloadAudioAttachment(_ messages: [NIMQChatMessage]) {
    for message in messages {
      if message.messageType == NIMMessageType.audio.rawValue {
        try? NIMSDK.shared().qchatMessageManager.fetchMessageAttachment(message)
      }
    }
  }

  public func getUserInfo(userIds: [String],
                          _ completion: @escaping (Error?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count:\(messages.count)")
    FriendProvider.shared.getUserInfoAdvanced(userIds: userIds) { userInfoList, error in
      for msg in self.messages {
        for u in userInfoList {
          if msg.message?.from == u.userId {
            msg.avatar = u.userInfo?.thumbAvatarUrl
            msg.nickname = u.userInfo?.nickName
          }
        }
      }
      completion(error)
    }
  }

  public func markMessageRead(time: TimeInterval) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    if let cid = channel?.channelId, let sid = channel?.serverId {
      var param = NEQChatMarkMessageReadParam(serverId: sid, channelId: cid)
      param.ackTimestamp = time
      weak var weakSelf = self
      QChatSystemMessageProvider.shared.markMessageRead(param: param) { error in
        if error != nil {
          NELog.errorLog(
            ModuleName + " " + (weakSelf?.className() ?? "QChatViewModel"),
            desc: "❌markMessageRead failed,error = \(error!)"
          )
        }
      }
    }
  }

  // 获取消息列表中的所有图片路径列表
  public func getUrls() -> [String] {
    var urls = [String]()
    for messageFrame in messages {
      if messageFrame.message?.messageType == NIMMessageType.image.rawValue, let object = messageFrame.message?.messageObject as? NIMImageObject {
        if let path = object.path, FileManager.default.fileExists(atPath: path) {
          urls.append(path)
        } else if let url = object.url {
          urls.append(url)
        }
      }
    }

    return urls
  }

  // 获取消息的 index
  public func indexOfMessage(message: NIMQChatMessage) -> Int {
    for (i, model) in messages.enumerated() {
      if model.message?.messageId == message.messageId {
        return i
      }
    }
    return -1
  }

  public func revokeMessage(_ completion: NIMQChatUpdateMessageHandler?) {
    if let message = operationModel?.message {
      // 撤回消息扩展内容
      var revokeExt = [String: Any]()
      revokeExt[revokeMessageFlag] = true
      if message.messageType == NIMMessageType.text.rawValue {
        // 消息撤回之后，text 会被清空
        UserDefaults.standard.setValue(message.text, forKey: message.serverID)
        UserDefaults.standard.synchronize()
      }

      // 更新信息
      let updateParam = NIMQChatUpdateParam()
      updateParam.extension = String.stringFromDictionary(dictionary: revokeExt)

      let revokeParam = NIMQChatRevokeMessageParam()
      revokeParam.message = message
      revokeParam.updateParam = updateParam
      repo.revokeMessage(param: revokeParam) { [weak self] error, updateResult in
        if error == nil {
          self?.revokeMessageUpdateUI(message)
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: revokeMessageFlag), object: revokeParam)
        }
        completion?(error, updateResult)
      }
    }
  }

  public func deleteMessage(_ completion: NIMQChatUpdateMessageHandler?) {
    if let message = operationModel?.message {
      if message.deliveryState == NIMMessageDeliveryState.failed.rawValue {
        // 发送失败的消息UI上直接移除
        deleteMessageUpdateUI(message)
        return
      }

      // 撤回消息扩展内容
      var deleteExt = [String: Any]()
      deleteExt[deleteMessageFlag] = true

      // 更新信息
      let updateParam = NIMQChatUpdateParam()
      updateParam.extension = String.stringFromDictionary(dictionary: deleteExt)

      let deleteParam = NIMQChatDeleteMessageParam()
      deleteParam.message = message
      deleteParam.updateParam = updateParam
      repo.deleteMessage(param: deleteParam) { [weak self] error, updateResult in
        if error == nil {
          self?.deleteMessageUpdateUI(message)
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: deleteMessageFlag), object: deleteParam)
        }
        completion?(error, updateResult)
      }
    }
  }

  func deleteMessageUpdateUI(_ message: NIMQChatMessage) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    let index = indexOfMessage(message: message)
    if index >= 0 {
      messages.remove(at: index)
      delegate?.onDeleteMessage(message, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  func revokeMessageUpdateUI(_ message: NIMQChatMessage) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    let index = indexOfMessage(message: message)
    if index >= 0 {
      messages[index].isRevoked = true
      messages[index].revokeText = message.text
      messages[index].quickComments = nil
      let newMessage = messages[index].message
      newMessage?.text = localizable("message_recalled")
      messages[index].message = newMessage
      delegate?.onRevokeMessage(message, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  public func addQuickComment(type: Int64,
                              to message: NIMQChatMessage,
                              completion: NIMQChatHandler?) {
    repo.addQuickComment(type: type, to: message) { [weak self] error in
      if error == nil {
        self?.addQuickCommentUpdateUI(type, message, selfReply: true)
      }
      completion?(error)
    }
  }

  public func addQuickCommentUpdateUI(_ type: Int64, _ message: NIMQChatMessage, selfReply: Bool?) {
    let index = indexOfMessage(message: message)
    if index >= 0 {
      let quickCommentDetail = NIMQChatMessageQuickCommentsDetail()
      quickCommentDetail.replyType = Int(type)
      quickCommentDetail.count = 1
      quickCommentDetail.selfReplyed = selfReply ?? false

      if let quickComments = messages[index].quickComments {
        for quickCommentDetail in quickComments {
          if quickCommentDetail.replyType == type {
            quickCommentDetail.count += 1
            quickCommentDetail.selfReplyed = selfReply ?? quickCommentDetail.selfReplyed
            messages[index].setFrame()
            delegate?.onReloadMessage(message, atIndexs: [IndexPath(row: index, section: 0)])
            return
          }
        }
        messages[index].quickComments?.append(quickCommentDetail)
      } else {
        messages[index].quickComments = [quickCommentDetail]
      }
      delegate?.onReloadMessage(message, atIndexs: [IndexPath(row: index, section: 0)])
    }
  }

  public func deleteQuickComment(type: Int64, to message: NIMQChatMessage, completion: NIMQChatHandler?) {
    repo.deleteQuickComment(type: type, to: message) { [weak self] error in
      if error == nil {
        self?.deleteQuickCommentUpdateUI(type, message, selfReply: false)
      }
      completion?(error)
    }
  }

  public func deleteQuickCommentUpdateUI(_ type: Int64, _ message: NIMQChatMessage, selfReply: Bool?) {
    let index = indexOfMessage(message: message)
    if index >= 0 {
      if let quickComments = messages[index].quickComments {
        for (i, quickCommentDetail) in quickComments.enumerated() {
          if quickCommentDetail.replyType == type {
            quickCommentDetail.count -= 1
            quickCommentDetail.selfReplyed = selfReply ?? quickCommentDetail.selfReplyed
            if quickCommentDetail.count == 0 {
              messages[index].quickComments?.remove(at: i)
            } else {
              messages[index].setFrame()
            }
            break
          }
        }
        delegate?.onReloadMessage(message, atIndexs: [IndexPath(row: index, section: 0)])
      }
    }
  }

  /// 查询表情评论
  public func fetchQuickComments(messages: [NIMQChatMessage], completion: @escaping NIMQChatFetchQuickCommentsByMsgsHandler) {
    repo.fetchQuickComments(messages: messages, completion: completion)
  }

  /// 表情评论类型是否存在(查询本地)
  func hasQuickComment(type: Int64) -> Bool {
    if let msgComments = operationModel?.quickComments {
      for comment in msgComments {
        if comment.replyType == type,
           comment.selfReplyed == true {
          return true
        }
      }
    }
    return false
  }

  // MARK: 公告频道

  /// 查询成员是否是管理员
  func isAdmistrator(serverId: UInt64?, accid: String?, completion: @escaping (Bool) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(String(describing: serverId)) accid:\(String(describing: accid))")
    guard let serverId = serverId,
          let accid = accid else {
      return
    }

    let param = NEQChatGetExistingAccidsInServerRoleParam(serverId: serverId, accids: [accid])
    repo.getExistingServerRolesByAccids(param) { [weak self] error, serverRoles in
      if let err = error {
        NELog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: #function + "getServerRolesByAccId CALLBACK ERROR:\(err.localizedDescription)")
      } else if let roles = serverRoles?[accid] {
        for role in roles {
          if role.roleId == self?.server?.announce?.roleId?.uint64Value {
            completion(true)
            return
          }
        }
        completion(false)
      } else {
        completion(false)
      }
    }
  }

  //    MARK: NIMChatManagerDelegate

  public func onRecvMessages(_ messages: [NIMQChatMessage]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messages.count:\(messages.count)")
    if lastMsg == nil {
      lastMsg = messages.first
    }

    downloadAudioAttachment(messages)
    var userIds = [String]()
    for msg in messages {
      if msg.qchatChannelId == channel?.channelId {
        if let userId = msg.from, !userIds.contains(userId) {
          userIds.append(userId)
        }
        let msgFrame = addTimeMessage(msg)
        self.messages.append(msgFrame)
      }
    }
    getUserInfo(userIds: userIds) { [weak self] error in
      if let time = self?.messages.last?.message?.timestamp {
        self?.markMessageRead(time: time)
      }
      self?.delegate?.onRecvMessages(messages)
    }
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    delegate?.onRecvSystemNotification(result)
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        // 更新快捷评论
        if systemNoti.type == .updateQuickComment,
           let quickCommentAttach = systemNoti.attach as? NIMQChatUpdateQuickCommentAttachment,
           let quickComment = quickCommentAttach.updateQuickCommentInfo {
          print("onRecvSystemNotification updateQuickComment")
          if let messageFrame = messages.first(where: { $0.message?.serverID == quickComment.msgServerId }),
             let message = messageFrame.message {
            if quickComment.opeType == .add {
              if systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
                addQuickCommentUpdateUI(quickComment.replyType, message, selfReply: true)
              } else {
                addQuickCommentUpdateUI(quickComment.replyType, message, selfReply: nil)
              }
            } else if quickComment.opeType == .delete {
              if systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
                deleteQuickCommentUpdateUI(quickComment.replyType, message, selfReply: false)
              } else {
                deleteQuickCommentUpdateUI(quickComment.replyType, message, selfReply: nil)
              }
            }
          }
        }
      }
    }
  }

  public func onMessageUpdate(_ event: NIMQChatUpdateMessageEvent) {
    // 对方撤回消息
    let (isRevoke, content) = QChatMessageHelper.isRevokeMessage(event: event)
    if event.message.isRevoked == true || isRevoke {
      event.message.text = content
      revokeMessageUpdateUI(event.message)
    }

    // 对方删除消息
    if event.message.isDeleted == true || QChatMessageHelper.isDeleteMessage(event: event) {
      deleteMessageUpdateUI(event.message)
    }
  }

  public func willSend(_ message: NIMQChatMessage) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:\(message.messageId)")
    print("\(#function)")
    if lastMsg == nil {
      lastMsg = message
    }

    messages.append(addTimeMessage(message))

    getUserInfo(userIds: [message.from ?? ""]) { error in
      self.delegate?.willSend(message)
    }
  }

  public func send(_ message: NIMQChatMessage, progress: Float) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:\(message.messageId)")
    print("\(#function)  progress\(progress)")
    delegate?.send(message, progress: progress)
  }

  public func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId:\(message.messageId)")
    let index = indexOfMessage(message: message)
    if index < 0 {
      return
    }

    if let e = error as NSError? {
      if e.code == errorCode_NoPermission {
        messages.remove(at: index)
      }
    } else {
      messages[index].message = message
    }
    delegate?.send(message, didCompleteWithError: error)
  }

  public func applyServerJoin(parameter: NEQChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(parameter.serverId)")
    repo.applyServerJoin(param: parameter) { error in
      completion(error)
    }
  }

  // 本地消息显示时间
  private func addTimeMessage(_ message: NIMQChatMessage) -> QChatMessageFrame {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    let lastTs = messages.last?.message?.timestamp ?? 0.0
    let curTs = message.timestamp
    let dur = curTs - lastTs
    let messageFrame = QChatMessageFrame()

    if (dur / 60) > 5 {
      messageFrame.showTime = true
      messageFrame.time = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
    }

    messageFrame.message = message
    return messageFrame
  }

  private func addTimeForHistoryMessage(_ message: NIMQChatMessage, isTop: Bool = false) -> QChatMessageFrame {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    let curTs = message.timestamp
    let messageFrame = QChatMessageFrame()

    // 首条消息显示时间
    if isTop {
      messageFrame.showTime = true
      messageFrame.time = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
      messageFrame.message = message
    }

    // 非首条消息则根据消息发送时间决定是否显示消息
    if let firstMsgFrame = messages.first,
       let firstTs = firstMsgFrame.message?.timestamp {
      let dur = firstTs - curTs
      if (dur / 60) > 5 {
        firstMsgFrame.showTime = true
        firstMsgFrame.time = String.stringFromDate(date: Date(timeIntervalSince1970: firstTs))
      }
    }

    messageFrame.message = message
    return messageFrame
  }
}
