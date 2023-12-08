// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import SDWebImageSVGKitPlugin
import SDWebImageWebPCoder
import UIKit

@objc public protocol QChatServerDelegate: NSObjectProtocol {
  @objc optional func serverUnReadTotalCountChange(count: UInt)
}

@objcMembers
public class QChatHomeViewModel: NSObject, QChatRepoMessageDelegate, QChatAllChannelDataDelegate {
  typealias ServerListRefresh = () -> Void

  var dataDic = WeakDictionary<UInt64, QChatServer>()

//  var serverUnReadDic = [UInt64: UInt]()

  var requestFlag = [UInt64: QChatAllChannelData]()

  var channelDataDic = [UInt64: [UInt64: UInt]]()

  let repo = QChatRepo.shared

  var currentServerId: UInt64? {
    didSet {}
  }

  var delegate: ViewModelDelegate?

  var updateServerList: ServerListRefresh?

  public var serverDelgate: QChatServerDelegate?

  private let visitorCacheFileName = "/visitorBanner.plist"

  public var visitorServerCache = [UInt64]()

  override public init() {
    super.init()
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    repo.delegate = self
    let webpCoder = SDImageWebPCoder()
    SDImageCodersManager.shared.addCoder(webpCoder)
    let svgCoder = SDImageSVGKCoder.shared
    SDImageCodersManager.shared.addCoder(svgCoder)
  }

  public func onUnReadChange(_ unreads: [NIMQChatUnreadInfo]?,
                             _ lastUnreads: [NIMQChatUnreadInfo]?) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ",qchat onUnReadChange unreads.count:\(unreads?.count ?? 0)")

    var set = Set<UInt64>()

    unreads?.forEach { [weak self] unread in
      set.insert(unread.serverId)
      if self?.channelDataDic[unread.serverId] != nil {
        self?.channelDataDic[unread.serverId]?[unread.channelId] = unread.unreadCount
      } else {
        var channelDic = [UInt64: UInt]()
        channelDic[unread.channelId] = unread.unreadCount
        self?.channelDataDic[unread.serverId] = channelDic
      }
    }

    set.forEach { sid in
      let model = dataDic[sid]
      print("server model : ", model?.name as Any)
      let unreadCount = getServerUnread(sid)
      // serverUnReadDic[sid] = unreadCount
      ObserverUnreadInfoResultHelper.shared.appendUnreadCountForServer(serverId: sid, count: unreadCount)

      if let cSid = currentServerId, cSid == sid {
        delegate?.dataDidChange()
      }
    }

    if set.count > 0 {
      serverDelgate?.serverUnReadTotalCountChange?(count: ObserverUnreadInfoResultHelper.shared.getTotalUnreadCountForServer())
    }

    if let block = updateServerList {
      block()
    }
  }

  public func serverUnreadInfoChanged(_ serverUnreadInfoDic: [NSNumber: NIMQChatServerUnreadInfo]) {
    NELog.infoLog(ModuleName + " " + "serverUnreadInfoChanged", desc: "serverUnreadInfoDic : \(serverUnreadInfoDic)")
  }

  func checkServerExistUnread(_ serverId: UInt64) -> Bool {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    if let channelDic = channelDataDic[serverId] {
      for key in channelDic.keys {
        if let unreadCount = channelDic[key], unreadCount > 0 {
          return true
        }
      }
    }
    return false
  }

  func getServerUnread(_ serverId: UInt64) -> UInt {
    var count: UInt = 0
    if let channelDic = channelDataDic[serverId] {
      for key in channelDic.keys {
        if let unreadCount = channelDic[key], unreadCount > 0 {
          count = count + unreadCount
        }
      }
    }
    return count
  }

  public func createServer(parameter: CreateServerParam,
                           _ completion: @escaping (NSError?, CreateServerResult?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", name:\(parameter.name ?? "nil")")
    QChatServerProvider.shared.createServer(param: parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func getServers(parameter: QChatGetServersParam,
                         _ completion: @escaping (NSError?, QChatGetServersResult?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", serverIds.count:\(parameter.serverIds?.count ?? 0)"
    )
    repo.getServers(parameter) { error, serverResult in
      completion(error, serverResult)
    }
  }

  public func getServerList(parameter: GetServersByPageParam,
                            _ completion: @escaping (NSError?, [QChatServer]?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function)
    repo.getServerList(param: parameter) { [weak self] error, result in
      var retServers = [QChatServer]()
      var invalidServers = [QChatServer]()

      result?.servers.forEach { server in
        if let announce = server.announce, announce.isInValid() == true {
          invalidServers.append(server)
        } else {
          retServers.append(server)
        }
      }
      self?.deleteInvalidServers(invalidServers)
      completion(error, retServers)
    }
  }

  public func getServerMemberList(parameter: QChatGetServerMembersParam,
                                  _ completion: @escaping (NSError?,
                                                           QChatGetServerMembersResult?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className(),
      desc: #function + ", serverAccIds.count:\(parameter.serverAccIds?.count ?? 0)"
    )
    QChatServerProvider.shared.getServerMembers(param: parameter) { error, result in
      completion(error, result)
    }
  }

  public func getServerMembersByPage(parameter: QChatGetServerMembersByPageParam,
                                     _ completion: @escaping (NSError?,
                                                              QChatGetServerMembersResult?)
                                       -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(parameter.serverId ?? 0)")
    QChatServerProvider.shared.getServerMembersByPage(param: parameter) { error, result in
      completion(error, result)
    }
//        repo.getServerMembersByPage(parameter, completion)
  }

  public func applyServerJoin(parameter: QChatApplyServerJoinParam,
                              _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(parameter.serverId)")
    QChatServerProvider.shared.applyServerJoin(param: parameter) { error in
      completion(error)
    }
  }

  public func inviteMembersToServer(serverId: UInt64, accids: [String],
                                    _ completion: @escaping (NSError?) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    let param = QChatInviteServerMembersParam(serverId: serverId, accids: accids)
    repo.inviteMembersToServer(param) { error in
      completion(error)
    }
  }

  public func updateMyServerMember(_ param: UpdateMyMemberInfoParam,
                                   _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(param.serverId ?? 0)")
    repo.updateMyServerMember(param, completion)
  }

  public func updateServerMember(_ param: UpdateServerMemberInfoParam,
                                 _ completion: @escaping (Error?, ServerMemeber) -> Void) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(param.serverId ?? 0)")
    repo.updateServerMember(param, completion)
  }

  public func getUnread(_ servers: [QChatServer]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", servers.count:\(servers.count)")

//    if currentServerId == nil {
//      currentServerId = servers.first?.serverId
//    }

    servers.forEach { server in
      if let sid = server.serverId {
        dataDic[sid] = server
      }
      getAllChannel(server)
    }
  }

  func getAllChannel(_ server: QChatServer) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(server.serverId ?? 0)")
    if let sid = server.serverId, requestFlag[sid] == nil {
      let allChannelData = QChatAllChannelData(sid: sid)
      allChannelData.delegate = self
      requestFlag[sid] = allChannelData
    }
  }

  func getChannelUnread(_ serverId: UInt64, _ channels: [ChatChannel]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId), channels.count:\(channels.count)")
//    print("getChannelUnread channel count : ", channels.count)
    var param = GetChannelUnreadInfosParam()
    var targets = [ChannelIdInfo]()

    channels.forEach { channel in
      var channelIdInfo = ChannelIdInfo()
      channelIdInfo.serverId = serverId
      channelIdInfo.channelId = channel.channelId
      targets.append(channelIdInfo)
    }
    param.targets = targets
//        weak var weakSelf = self
    repo.getChannelUnReadInfo(param) { error, infos in

      print("get channel unread info : ", error as Any)
      /*
       infos?.forEach({ info in
           if  weakSelf?.channelDataDic[info.serverId] != nil {
               weakSelf?.channelDataDic[info.serverId]?[info.channelId] = info.unreadCount
           }else {
               var channelDic = [UInt64: UInt]()
               channelDic[info.channelId] = info.unreadCount
               weakSelf?.channelDataDic[info.serverId] = channelDic
           }
       })
       if let last = infos?.last, let sid = weakSelf?.currentServerId {
           if last.serverId == sid {
               weakSelf?.delegate?.dataDidChange()
           }
       }
       if let server = weakSelf?.dataDic[serverId], let block = weakSelf?.updateServerList, let hasUnread =  weakSelf?.checkServerExistUnread(serverId){
           server.hasUnread = hasUnread
           block()
           if let cSid = weakSelf?.currentServerId, cSid == serverId {
               weakSelf?.delegate?.dataDidChange()
           }
       }*/
    }
  }

  func dataGetSuccess(_ serverId: UInt64, _ channels: [ChatChannel]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    print("get unread channel success : ", channels.count)
    requestFlag.removeValue(forKey: serverId)
    getChannelUnread(serverId, channels)
  }

  func dataGetError(_ serverId: UInt64, _ error: Error) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    requestFlag.removeValue(forKey: serverId)
    print("get all channels error : ", error)
  }

  func getChannelUnreadCount(_ serverId: UInt64, _ channelId: UInt64) -> UInt {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", serverId:\(serverId)")
    if let channelDic = channelDataDic[serverId], let count = channelDic[channelId] {
      return count
    }
    return 0
  }

  func enterAsVisitor(_ serverId: UInt64, _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatEnterServerAsVisitorParam()
    param.serverIds = [NSNumber(value: serverId)]
    weak var weakSelf = self
    repo.enterAsVisitor(param) { error, result in
      completion(error)
      let param = NIMQChatSubscribeServerAsVisitorParam()
      param.serverIds = [NSNumber(value: serverId)]
      param.operateType = .subscribe
      weakSelf?.subscribeAsVisitor(param) { error in
        NELog.infoLog(weakSelf?.className() ?? "", desc: "visitor subscribeAsVisitor : \(error?.localizedDescription ?? "")")
        weakSelf?.visitorSubcribeAllChannel(serverId)
      }
    }
  }

  func leaveAsVisitor(_ serverIds: [NSNumber], _ completion: @escaping (Error?) -> Void) {
    let param = NIMQChatLeaveServerAsVisitorParam()
    param.serverIds = serverIds
    repo.leaveAsVisitor(param) { error, result in
      completion(error)
    }
  }

  // 游客模式订阅channel
  public func subscribeChannel(_ param: NIMQChatSubscribeChannelAsVisitorParam, _ completion: @escaping (Error?) -> Void) {
    repo.subscribeChannel(param) { [weak self] error, result in
      NELog.infoLog(self?.className() ?? "", desc: "subscribeChannel failedChannelInfos : \(result?.failedChannelInfos ?? []) error : \(error?.localizedDescription ?? "")")
      completion(error)
    }
  }

  // 游客模式订阅Server
  public func subscribeAsVisitor(_ param: NIMQChatSubscribeServerAsVisitorParam, _ completion: @escaping (Error?) -> Void) {
    repo.subscribeAsVisitor(param) { [weak self] error, result in
      NELog.infoLog(self?.className() ?? "", desc: "subscribeAsVisitor failedServerIds : \(result?.failedServerIds ?? []) error : \(error?.localizedDescription ?? "")")
      completion(error)
    }
  }

  public func visitorSubcribeAllChannel(_ serverId: UInt64) {
    var param = QChatGetChannelsByPageParam(timeTag: 0, serverId: serverId)
    param.limit = 100

    repo.getChannelsByPage(param: param) { [weak self] error, result in
      var channelInfos = [NIMQChatChannelIdInfo]()
      result?.channels.forEach { channel in
        if let cid = channel.channelId, let sid = channel.serverId {
          let channelInfo = NIMQChatChannelIdInfo(channelId: cid, serverId: sid)
          channelInfos.append(channelInfo)
        }
      }
      if channelInfos.count > 0 {
        let param = NIMQChatSubscribeChannelAsVisitorParam()
        param.channelIdInfos = channelInfos
        param.operateType = .subscribe
        self?.subscribeChannel(param) { error in
        }
      }
    }
  }

  // 游客数据清理
  func clearVisitorCache() {
    loadVisitorCache()
    var serverIds = [NSNumber]()
    visitorServerCache.forEach { sid in
      serverIds.append(NSNumber(value: sid))
    }

    if serverIds.count > 0 {
      leaveAsVisitor(serverIds) { [weak self] error in
        self?.visitorServerCache.removeAll()
        if let array = self?.visitorServerCache {
          self?.writeVisitorCacheFile(array)
        }
      }
    }
  }

  // 数组写文件
  func writeVisitorCacheFile(_ array: [UInt64]) {
    let path = (NEPathUtils.getDocumentPath() ?? "") + visitorCacheFileName
    (array as NSArray).write(toFile: path, atomically: true)
  }

  // 从文件读数组
  func loadVisitorCache() {
    let path = (NEPathUtils.getDocumentPath() ?? "") + visitorCacheFileName
    let array = NSArray(contentsOfFile: path)

    array?.forEach { serverId in
      if let sid = serverId as? UInt64 {
        visitorServerCache.append(sid)
      }
    }
  }

  // 删除 visitor 缓存文件
  func deleteVisitorCache() {
    let path = (NEPathUtils.getDocumentPath() ?? "") + visitorCacheFileName
    if FileManager.default.fileExists(atPath: path) {
      do {
        try FileManager.default.removeItem(atPath: path)
      } catch {
        NELog.errorLog(ModuleName + " " + className(), desc: "deleteVisitorCache error = \(error)")
      }
    }
  }

  // 查找数组中第一个不是公告频道的server数据
  public func findFirstNormalServer(_ servers: [QChatServer]?) -> QChatServer? {
    var server: QChatServer?
    if let qchatServers = servers {
      for qchatServer in qchatServers {
        if qchatServer.announce == nil {
          server = qchatServer
          break
        }
      }
    }
    return server
  }

  public func deleteInvalidServers(_ servers: [QChatServer]) {
    servers.forEach { [weak self] server in
      if let sid = server.serverId {
        self?.repo.deleteServer(sid) { error in
        }
      }
    }
  }

  func checkJoinServer(server: QChatServer, _ completion: @escaping (Error?, Bool) -> Void) {
    guard let sid = server.serverId else {
      return
    }
    var items = [QChatGetServerMemberItem]()
    let currentAccid = QChatKitClient.instance.imAccid()
    let item = QChatGetServerMemberItem(serverId: sid, accid: currentAccid)
    items.append(item)
    let param = QChatGetServerMembersParam(serverAccIds: items)
    repo.getServerMembers(param: param) { error, members in
      var isJoined = false
      if let member = members?.first, sid == member.serverId {
        isJoined = true
      }
      completion(error, isJoined)
    }
  }
}
