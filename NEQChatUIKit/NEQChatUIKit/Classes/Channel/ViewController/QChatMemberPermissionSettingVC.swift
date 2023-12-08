
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

typealias UpdateSettingBlock = (_ memberRole: MemberRole?) -> Void
public class QChatMemberPermissionSettingVC: QChatTableViewController,
  QChatPermissionSettingCellDelegate {
  public var channel: ChatChannel?
  public var memberRole: MemberRole?
//    public var didUpdateBlock: UpdateSettingBlock?
  private var commonAuths = [QChatRoleStatusInfoExt]()
  private var messageAuths = [QChatRoleStatusInfoExt]()
  private var memberAuths = [QChatRoleStatusInfoExt]()

  private var auths = [[Any]]()

  init(channel: ChatChannel?, memberRole: MemberRole?) {
    super.init(nibName: nil, bundle: nil)
    self.channel = channel
    self.memberRole = memberRole
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("member_permission_setting")
    navigationView.backgroundColor = .ne_lightBackgroundColor
    view.backgroundColor = .ne_lightBackgroundColor

    tableView.register(
      QChatPermissionSettingCell.self,
      forCellReuseIdentifier: "\(QChatPermissionSettingCell.self)"
    )
    tableView.register(
      QChatImageTextCell.self,
      forCellReuseIdentifier: "\(QChatImageTextCell.self)"
    )
    tableView.register(
      QChatSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)"
    )
    tableView.sectionHeaderHeight = 42
    tableView.rowHeight = 48
    reloadData()
  }

  private func reloadData() {
    let members = [memberRole]
    auths.append(members as [Any])

    if let auths = memberRole?.auths {
      for auth in auths {
        var authExt = QChatRoleStatusInfoExt(status: auth)
        if let type = auth.type {
          let key = "auth_" + String(type.rawValue)
          authExt.title = localizable(key)
          switch auth.type {
          case .manageChannel:
            commonAuths.insert(authExt, at: 0)
          case .manageRole:
            commonAuths.append(authExt)
          case .sendMsg:
            messageAuths.append(authExt)
          //                case .DeleteOtherMsg:
          //                    messageAuths.append(authExt)
          //                case .RevokeMsg:
          //                    messageAuths.append(authExt)
          case .manageBlackWhiteList:
            memberAuths.append(authExt)
          default:
            break
          }
        }
      }

      if !commonAuths.isEmpty {
        self.auths.append(commonAuths)
      }
      if !messageAuths.isEmpty {
        self.auths.append(messageAuths)
      }
      if !memberAuths.isEmpty {
        self.auths.append(memberAuths)
      }
    }
    tableView.reloadData()
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    auths.count
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    auths[section].count
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      // 用户
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatImageTextCell.self)",
        for: indexPath
      ) as! QChatImageTextCell
      let members = auths[indexPath.section]
      let m = members[indexPath.row] as? MemberRole
      cell.setup(accid: m?.accid, nickName: m?.nick, avatar: m?.avatar)
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight).union(CornerType.bottomLeft.union(CornerType.bottomRight))
      cell.line.isHidden = true

      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatPermissionSettingCell.self)",
        for: indexPath
      ) as! QChatPermissionSettingCell
      let auths = auths[indexPath.section]
      let authExt = auths[indexPath.row] as? QChatRoleStatusInfoExt
      cell.updateModel(model: authExt)
      cell.delegate = self
      if indexPath.row == 0 {
        cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
      }
      if indexPath.row == auths.count - 1 {
        cell.cornerType = cell.cornerType.union(CornerType.bottomLeft.union(CornerType.bottomRight))
        cell.dividerLine.isHidden = true
      }
      return cell
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as? QChatSectionView
    if section == 1 {
      view?.titleLabel.text = localizable("qchat_common_permission")
    } else if section == 2 {
      view?.titleLabel.text = localizable("qchat_message_permission")
    } else if section == 3 {
      view?.titleLabel.text = localizable("qchat_member_permission")
    }
    return view
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 56
    } else {
      return 48
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }
    return 42
  }

//    MARK: QChatPermissionSettingCellDelegate

  func didSelected(cell: QChatPermissionSettingCell?, model: RoleStatusInfo?) {
    if let auth = model {
      let param = UpdateMemberRoleParam(
        serverId: channel?.serverId,
        channelId: channel?.channelId,
        accid: memberRole?.accid,
        commands: [auth]
      )
      QChatRoleProvider.shared
        .updateMemberRole(param: param) { [weak self] error, memberRole in
          if let err = error as NSError? {
            switch err.code {
            case errorCode_NetWorkError:
              self?.showToast(localizable("network_error"))
            case errorCode_NoPermission:
              self?.showToast(localizable("no_permession"))
            default:
              self?.showToast(err.localizedDescription)
            }
            cell?.selectedSuccess(success: false)
          } else {
            self?.view.hideAllToasts()
            cell?.selectedSuccess(success: true)
//                    if let block = self?.didUpdateBlock {
//                        block(memberRole)
//                    }
          }
        }
    }
  }
}
