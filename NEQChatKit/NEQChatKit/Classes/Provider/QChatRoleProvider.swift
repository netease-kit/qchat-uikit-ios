
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import AVFoundation
import Foundation
import NECoreIM2Kit
import NECoreKit
import NIMQChat
import NIMSDK
import UIKit

public protocol QChatRoleProviderDelegate: NSObjectProtocol {}

@objcMembers
public class QChatRoleProvider: NSObject {
  public static let shared = QChatRoleProvider()
  private let mutiDelegate = MultiDelegate<QChatRoleProviderDelegate>(strongReferences: false)

  public func createRole(_ param: NEQChatServerRoleParam,
                         _ completion: @escaping (Error?, NEQChatServerRole) -> Void) {
    let roleParam = param.toIMParam()
    NIMSDK.shared().qchatRoleManager.createServerRole(roleParam) { error, role in
      completion(error, NEQChatServerRole(role))
    }
  }

  /// 获取服务器身份组
  public func getRoles(_ param: NEQChatGetServerRoleParam,
                       _ completion: @escaping (Error?, [NEQChatServerRole]?, Set<NSNumber>?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getServerRoles(param.toImParam()) { error, result in
      var roles = [NEQChatServerRole]()
      result?.serverRoleArray.forEach { role in
        let sRole = NEQChatServerRole(role)
        roles.append(sRole)
      }
      completion(error, roles, result?.isMemberSet)
    }
  }

  public func updateServerRolePriorities(_ param: NEQChatUpdateServerRolePrioritiesParam,
                                         _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .updateServerRolePriorities(param.toImParam()) { error, result in
        completion(error)
      }
  }

  public func deleteRoles(_ param: NEQChatDeleteServerRoleParam,
                          _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().qchatRoleManager.deleteServerRole(param.toIMParam()) { error in
      completion(error)
    }
  }

  /// 更新服务器身份组
  public func updateRole(_ param: NEQChatUpdateServerRoleParam,
                         _ completion: @escaping (Error?, NEQChatServerRole) -> Void) {
    let imParam = param.toImParam()
    NIMSDK.shared().qchatRoleManager.updateServerRole(imParam) { error, role in
      let serverRole = NEQChatServerRole(role)
      completion(error, serverRole)
    }
  }

  /// 查询某服务器下某身份组下的成员列表
  public func getServerRoleMembers(_ param: NEQChatGetServerRoleMembersParam,
                                   _ completion: @escaping (Error?, [NEQChatRoleMember]) -> Void) {
    NIMSDK.shared().qchatRoleManager.getServerRoleMembers(param.toImParam()) { error, result in
      var members = [NEQChatRoleMember]()
      result?.memberArray.forEach { member in
        members.append(NEQChatRoleMember(member))
      }
      completion(error, members)
    }
  }

  /// 将某些人加入某服务器身份组
  public func addRoleMember(_ param: NEQChatAddServerRoleMemberParam,
                            _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NIMSDK.shared().qchatRoleManager.addServerRoleMembers(param.toImParam()) { error, result in
      var successAccids = [String]()
      var failedAccids = [String]()
      if let err = error {
        completion(err, successAccids, failedAccids)
      } else {
        if let sAccids = result?.successfulAccidArray {
          for value in sAccids {
            successAccids.append(value)
          }
        }
        if let fAccids = result?.failedAccidArray {
          for value in fAccids {
            failedAccids.append(value)
          }
        }
        completion(error, successAccids, failedAccids)
      }
    }
  }

  /// 将某些人移除某服务器身份组
  public func deleateRoleMember(_ param: NEQChatRemoveServerRoleMemberParam,
                                _ completion: @escaping (Error?, [String], [String]) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .removeServerRoleMember(param.toImParam()) { error, result in
        var success = [String]()
        var faileds = [String]()
        result?.successfulAccidArray.forEach { accid in
          success.append(accid)
        }
        result?.failedAccidArray.forEach { accid in
          faileds.append(accid)
        }
        completion(error, success, faileds)
      }
  }

  // 添加身份组到某个频道下
  public func addChannelRole(param: NEQChatAddChannelRoleParam,
                             _ completion: @escaping (NSError?, NEQChatChannelRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.addChannelRole(param.toImParam()) { error, cRole in
      if error != nil {
        completion(error as NSError?, nil)
      } else {
        completion(error as NSError?, NEQChatChannelRole(role: cRole))
      }
    }
  }

  // 移除某个频道下的身份组
  public func removeChannelRole(param: NEQChatRemoveChannelRoleParam,
                                _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatRoleManager.removeChannelRole(param.toImParam()) { error in
      completion(error as NSError?)
    }
  }

  /// 查询频道下身份组列表
  public func getChannelRoles(param: NEQChatChannelRoleParam,
                              _ completion: @escaping (NSError?, [NEQChatChannelRole]?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getChannelRoles(param.toIMParam()) { error, result in
      guard let roleArray = result?.channelRoleArray else {
        completion(error as NSError?, nil)
        return
      }
      var array = [NEQChatChannelRole]()
      for role in roleArray {
        array.append(NEQChatChannelRole(role: role))
      }
      completion(error as NSError?, array)
    }
  }

  // 查询身份组是否已经添加到频道中，返回已经添加的身份组列表
  public func getExistingChannelRoles(param: NEQChatGetExistingChannelRolesByServerRoleIdsParam,
                                      _ completion: @escaping (NSError?, [NEQChatChannelRole]?)
                                        -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingChannelRoles(byServerRoleIds: param.toIMParam()) { error, result in
        guard let roleArray = result?.channelRoleArray else {
          completion(error as NSError?, nil)
          return
        }
        var array = [NEQChatChannelRole]()
        for role in roleArray {
          array.append(NEQChatChannelRole(role: role))
        }
        completion(error as NSError?, array)
      }
  }

  // 查询频道下成员的权限
  public func getMemberRoles(param: NEQChatGetMemberRolesParam,
                             _ completion: @escaping (NSError?, [NEQChatMemberRole]?) -> Void) {
    NIMSDK.shared().qchatRoleManager.getMemberRoles(param.toImParam()) { error, result in
      guard let roleArray = result?.memberRoleArray else {
        completion(error as NSError?, nil)
        return
      }
      var array = [NEQChatMemberRole]()
      for member in roleArray {
        array.append(NEQChatMemberRole(member: member))
      }
      completion(error as NSError?, array)
    }
  }

  // 设置频道下身份组权限
  public func updateChannelRole(param: NEQChatUpdateChannelRoleParam,
                                _ completion: @escaping (NSError?, NEQChatChannelRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager
      .updateChannelRole(param.toIMParam()) { error, channelRole in
        completion(error as NSError?, NEQChatChannelRole(role: channelRole))
      }
  }

  /// 通过accid查询自定义身份组列表
  public func getServerRolesByAccId(param: NEQChatGetServerRolesByAccIdParam,
                                    _ completion: @escaping (Error?, [NEQChatServerRole]?) -> Void) {
    let imParam = param.toIMParam()
    print("im param : ", imParam)
    NIMSDK.shared().qchatRoleManager.getServerRoles(byAccid: imParam) { error, result in
      var roles = [NEQChatServerRole]()
      result?.serverRoles.forEach { role in
        roles.append(NEQChatServerRole(role))
      }
      completion(error, roles)
    }
  }

  /// 查询一批accids的自定义身份组列表
  public func getExistingServerRolesByAccids(param: NEQChatGetExistingAccidsInServerRoleParam,
                                             _ completion: @escaping (NSError?,
                                                                      [String: [NEQChatServerRole]]?)
                                               -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingAccids(inServerRole: param.toImParam()) { error, result in
        var serverRoles = [String: [NEQChatServerRole]]()
        result?.accidServerRolesDic?.forEach { key, serverRole in
          var memberRoleArray = [NEQChatServerRole]()
          for role in serverRole {
            memberRoleArray.append(NEQChatServerRole(role))
          }
          serverRoles[key] = memberRoleArray
        }
        completion(error as NSError?, serverRoles)
      }
  }

  // 添加成员到频道
  public func addMemberRole(_ param: NEQChatAddMemberRoleParam,
                            _ completion: @escaping (NSError?, NEQChatMemberRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.addMemberRole(param.toIMParam()) { error, memberRole in
      if let m = memberRole {
        completion(error as NSError?, NEQChatMemberRole(member: m))
      } else {
        completion(error as NSError?, nil)
      }
    }
  }

  // 移除某个频道下的成员
  public func removeMemberRole(param: NEQChatRemoveMemberRoleParam,
                               _ completion: @escaping (NSError?) -> Void) {
    NIMSDK.shared().qchatRoleManager.removeMemberRole(param.toIMParam()) { error in
      completion(error as NSError?)
    }
  }

  /// 将某些人移除某服务器身份组
  public func removeServerRoleMember(param: NIMQChatRemoveServerRoleMemberParam,
                                     _ completion: @escaping (Error?, NIMQChatRemoveServerRoleMembersResult?) -> Void) {
    NIMSDK.shared().qchatRoleManager.removeServerRoleMember(param) { error, result in
      completion(error, result)
    }
  }

  // 设置某个频道下的成员的权限
  public func updateMemberRole(param: NEQChatUpdateMemberRoleParam,
                               _ completion: @escaping (NSError?, NEQChatMemberRole?) -> Void) {
    NIMSDK.shared().qchatRoleManager.updateMemberRole(param.toIMParam()) { error, memberRole in
      completion(error as NSError?, NEQChatMemberRole(member: memberRole))
    }
  }

  /// 查询自己是否有某个权限
  public func checkPermission(param: NIMQChatCheckPermissionParam, complete: @escaping (NSError?, Bool) -> Void) {
    NIMSDK.shared().qchatRoleManager.checkPermission(param) { error, result in
      complete(error as NSError?, result)
    }
  }

  //    查询成员是否已经添加到频道中，返回已经添加的成员列表
  public func getExistingMemberRoles(param: NEQChatGetExistingAccidsOfMemberRolesParam,
                                     _ completion: @escaping (NSError?, [NEQChatMemberRole]?) -> Void) {
    print(#function + "⬆️accid:\(param.accids)")
    NIMSDK.shared().qchatRoleManager
      .getExistingAccids(ofMemberRoles: param.toIMParam()) { error, result in
        guard let memberRoles = result?.accidArray else {
          completion(error as NSError?, nil)
          return
        }
        var array = [NEQChatMemberRole]()
        for memberRole in memberRoles {
          array.append(NEQChatMemberRole(aid: memberRole))
        }
        print(#function + "⬇️array:\(array)")
        completion(error as NSError?, array)
      }
  }

  public func getExistingServerRoleMembersByAccids(_ param: NEQChatGetExistingServerRoleMembersByAccidsParam,
                                                   _ completion: @escaping (Error?, [String])
                                                     -> Void) {
    NIMSDK.shared().qchatRoleManager
      .getExistingServerRoleMembers(byAccids: param.toImParam()) { error, result in
        var accids = [String]()
        result?.accidArray.forEach { member in
          accids.append(member)
        }
        completion(error, accids)
      }
  }

  public func addDelegate(delegate: QChatRoleProviderDelegate) {
    mutiDelegate.addDelegate(delegate)
  }

  public func removeDelegate(delegate: QChatRoleProviderDelegate) {
    mutiDelegate.removeDelegate(delegate)
  }
}
