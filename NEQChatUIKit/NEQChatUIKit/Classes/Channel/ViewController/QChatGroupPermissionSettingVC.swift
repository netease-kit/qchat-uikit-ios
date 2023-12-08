
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

typealias ChannelUpdateSettingBlock = (_ channelRole: ChannelRole?) -> Void

public class QChatGroupPermissionSettingVC: QChatTableViewController,
  QChatPermissionSettingCellDelegate {
//    public var didUpdateBlock: ChannelUpdateSettingBlock?
  public var cRole: ChannelRole?
  private var commonAuths = [QChatRoleStatusInfoExt]()
  private var messageAuths = [QChatRoleStatusInfoExt]()
  private var memberAuths = [QChatRoleStatusInfoExt]()
  private var auths = [[QChatRoleStatusInfoExt]]()

  public init(cRole: ChannelRole?) {
    super.init(nibName: nil, bundle: nil)
    self.cRole = cRole
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    if let name = cRole?.name {
      title = name + localizable("authority_setting")
    } else {
      title = localizable("authority_setting")
    }
    navigationView.backgroundColor = .ne_lightBackgroundColor
    view.backgroundColor = .ne_lightBackgroundColor

    // 设置标题超长后的省略模式
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byTruncatingMiddle
    navigationController?.navigationBar.titleTextAttributes = [.paragraphStyle: paragraphStyle]

    tableView.register(
      QChatPermissionSettingCell.self,
      forCellReuseIdentifier: "\(QChatPermissionSettingCell.self)"
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
    if let auths = cRole?.auths {
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
      tableView.reloadData()
    }
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
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatPermissionSettingCell.self)",
      for: indexPath
    ) as! QChatPermissionSettingCell
    let auths = auths[indexPath.section]
    let authExt = auths[indexPath.row]
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

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as? QChatSectionView
    if section == 0 {
      view?.titleLabel.text = localizable("qchat_common_permission")
    } else if section == 1 {
      view?.titleLabel.text = localizable("qchat_message_permission")
    } else {
      view?.titleLabel.text = localizable("qchat_member_permission")
    }
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    42
  }

  //    MARK: QChatPermissionSettingCellDelegate

  func didSelected(cell: QChatPermissionSettingCell?, model: RoleStatusInfo?) {
    if let auth = model {
      let param = UpdateChannelRoleParam(
        serverId: cRole?.serverId,
        channelId: cRole?.channelId,
        roleId: cRole?.roleId,
        commands: [auth]
      )
      QChatRoleProvider.shared
        .updateChannelRole(param: param) { [weak self] error, channelRole in
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
//                        block(channelRole)
//                    }
          }
        }
    }
  }
}
