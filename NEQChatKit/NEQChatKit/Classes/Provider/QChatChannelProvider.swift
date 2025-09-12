
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreMedia
import Foundation
import NECoreIM2Kit
import NIMQChat
import NIMSDK

public protocol QChatChannelProviderDelegate: NSObjectProtocol {
  func callBack()
}

@objcMembers
public class QChatChannelProvider: NSObject, NIMQChatChannelManagerDelegate {
  public static let shared = QChatChannelProvider()
  private let mutiDelegate = MultiDelegate<QChatChannelProviderDelegate>(strongReferences: false)

  override init() {
    super.init()
    NIMSDK.shared().qchatChannelManager.add(self)
  }

  /// 创建圈组话题
  public func createChannel(param: NEQChatCreateChannelParam,
                            _ completion: @escaping (NSError?, NEQChatChatChannel?) -> Void) {
    print(#function + "param:\(param.toIMParam())")
    NIMSDK.shared().qchatChannelManager.createChannel(param.toIMParam()) { error, chatChannel in
      print("file:" + #file + "function:" + #function +
        "error:\(error?.localizedDescription ?? "")" +
        "chatChannel:\(chatChannel?.channelId ?? 0)")
      completion(error as NSError?, NEQChatChatChannel(channel: chatChannel))
    }
  }

  /// 修改圈组话题信息
  public func updateChannelInfo(param: NEQChatUpdateChannelParam,
                                _ completion: @escaping (NSError?, NEQChatChatChannel?) -> Void) {
    NIMSDK.shared().qchatChannelManager.updateChannel(param.toIMParam()) { error, chatChannel in
      print("file:" + #file + "function:" + #function +
        "error:\(error?.localizedDescription ?? "")" +
        "chatChannel:\(chatChannel?.channelId ?? 0)")
      completion(error as NSError?, NEQChatChatChannel(channel: chatChannel))
    }
  }

  /// 删除圈组话题
  public func deleteChannel(channelId: UInt64?, _ completion: @escaping (NSError?) -> Void) {
    let param = NIMQChatDeleteChannelParam()
    param.channelId = channelId ?? 0
    NIMSDK.shared().qchatChannelManager.deleteChannel(param) { error in
      completion(error as NSError?)
    }
  }

  /// 查询主题成员信息
  public func getChannelMembers(param: NEQChatChannelMembersParam,
                                _ completion: @escaping (NSError?, NEQChatChannelMembersResult?)
                                  -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelMembers(byPage: param.toIMParam()) { error, result in
        completion(error as NSError?, NEQChatChannelMembersResult(memberResult: result))
      }
  }

  /// 分页查询主题黑白名单成员列表
  public func getBlackWhiteMembersByPage(param: NEQChatGetChannelBlackWhiteMembers,
                                         _ completion: @escaping (NSError?,
                                                                  NEQChatChannelMembersResult?) -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getBlackWhiteMembers(byPage: param.toIMParam()) { error, result in
        print("error\(error) blackmemberArray:\(result?.memberArray)")
        completion(error as NSError?, NEQChatChannelMembersResult(whiteMemberResult: result))
      }
  }

  /// 主题添加、删除黑白名单
  public func updateBlackWhiteMembers(param: NEQChatUpdateChannelBlackWhiteMembersParam,
                                      _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatChannelManager.updateBlackWhiteMembers(param.toIMParam()) { error in
      completion(error as NSError?)
    }
  }

  /// 批量查询主题黑白名单成员列表
  public func getExistingChannelBlackWhiteMembers(param: NEQChatGetExistingChannelBlackWhiteMembersParam,
                                                  _ completion: @escaping (NSError?,
                                                                           NEQChatBlackWhiteMembersResult?)
                                                    -> Void) {
    print(#function + "param:\(param)")
    NIMSDK.shared().qchatChannelManager
      .getExistingChannelBlackWhiteMembers(param.toIMParam()) { error, result in
        print(#function + "error:\(param) result:\(result)")
        completion(error as NSError?, NEQChatBlackWhiteMembersResult(result: result))
      }
  }

  /// 分页查询圈组主题信息
  public func getChannelsByPage(param: NEQChatGetChannelsByPageParam,
                                _ completion: @escaping (NSError?, NEQChatGetChannelsByPageResult?)
                                  -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelsByPage(param.toIMParam()) { error, channelsResult in
        completion(
          error as NSError?,
          NEQChatGetChannelsByPageResult(channelsResult: channelsResult)
        )
      }
  }

  /// 游客模式订阅主题
  public func subscribeChannel(_ param: NIMQChatSubscribeChannelAsVisitorParam, _ completion: @escaping (Error?, NIMQChatSubscribeChannelAsVisitorResult?) -> Void) {
    NIMSDK.shared().qchatChannelManager.subscribe(asVisitor: param) { error, result in
      completion(error, result)
    }
  }

  /// 查询话题未读信息
  public func getChannelUnReadInfo(_ param: NEQChatGetChannelUnreadInfosParam,
                                   _ completion: @escaping (Error?, [NIMQChatUnreadInfo]?)
                                     -> Void) {
    NIMSDK.shared().qchatChannelManager
      .getChannelUnreadInfos(param.toImParam()) { error, result in
        completion(error, result?.unreadInfo)
      }
  }

  // MARK: callback

  func callback() {
    mutiDelegate |> { delegate in
      delegate.callBack()
    }
  }
}
