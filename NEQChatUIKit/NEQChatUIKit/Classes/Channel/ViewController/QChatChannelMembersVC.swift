
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreQChatKit
import NEQChatKit
import UIKit

public class QChatChannelMembersVC: QChatTableViewController, QChatMemberInfoViewDelegate {
  public var channel: ChatChannel?
  private var channelMembers: [ServerMemeber]?
  var memberInfoView: QChatMemberInfoView?
  var lastMember: ServerMemeber?
  var isVisitorMode = false

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  func commonUI() {
    title = channel?.name
    view.backgroundColor = .white
    if isVisitorMode == false {
      addRightAction(UIImage.ne_imageNamed(name: "Setting"), #selector(enterChannelSetting), self)
      navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "Setting"))
      navigationView.addMoreButtonTarget(target: self, selector: #selector(enterChannelSetting))
    }

    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false

    tableView.rowHeight = 66
    tableView.register(
      QChatGroupIdentityMemberCell.self,
      forCellReuseIdentifier: "\(QChatGroupIdentityMemberCell.self)"
    )
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadData)
    )
  }

  @objc func loadData() {
    var param = ChannelMembersParam(
      serverId: channel?.serverId ?? 0,
      channelId: channel?.channelId ?? 0
    )
    param.limit = 50
    QChatChannelProvider.shared
      .getChannelMembers(param: param) { [weak self] error, cMembersResult in
        print(
          "cMembersResult.memberArray:\(cMembersResult?.memberArray) thread:\(Thread.current) "
        )
        self?.channelMembers = cMembersResult?.memberArray
        self?.lastMember = cMembersResult?.memberArray?.last
        self?.tableView.reloadData()
        self?.tableView.mj_footer?.resetNoMoreData()
        self?.tableView.mj_header?.endRefreshing()
      }
  }

  @objc func loadMoreData() {
    var param = ChannelMembersParam(
      serverId: channel?.serverId ?? 0,
      channelId: channel?.channelId ?? 0
    )
    param.timeTag = lastMember?.createTime
    param.limit = 50
    QChatChannelProvider.shared
      .getChannelMembers(param: param) { [weak self] error, cMembersResult in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
          return
        }

        if let members = cMembersResult?.memberArray, members.count > 0 {
          for m in members {
            self?.channelMembers?.append(m)
          }
          self?.lastMember = members.last
          self?.tableView.reloadData()
        } else {
//                end
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        }
      }
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    channelMembers?.count ?? 0
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatGroupIdentityMemberCell.self)",
      for: indexPath
    ) as! QChatGroupIdentityMemberCell
    let member = channelMembers![indexPath.row] as ServerMemeber
    cell.memberModel = member
    cell.arrowImageView.isHidden = true
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let m = channelMembers![indexPath.row]
    memberInfoView = QChatMemberInfoView(inView: view)
    memberInfoView?.setup(accid: m.accid, nickName: m.nick, avatarUrl: m.avatar)
    memberInfoView?.delegate = self
    memberInfoView?.present()
    loadRolesOfMember(member: m)
  }

  func loadRolesOfMember(member: ServerMemeber) {
    let param = GetServerRolesByAccIdParam(serverId: channel?.serverId, accid: member.accid)
    QChatRoleProvider.shared.getServerRolesByAccId(param: param) { [weak self] error, roles in
      print("roles:\(roles?.count) error: \(error)")
      guard let roleList = roles else {
        return
      }
      var names = [String]()

      for r in roleList {
        names.append(r.name ?? "")
      }
      self?.memberInfoView?.setupRoles(dataArray: names)
    }
  }

  @objc func enterChannelSetting() {
    if isVisitorMode == true {
      return
    }
    let settingVC = QChatChannelSettingVC()
    settingVC.didUpdateChannel = { [weak self] channel in
      self?.channel = channel
      self?.title = channel?.name
    }

    settingVC.didDeleteChannel = { [weak self] channel in
      self?.navigationController?.popViewController(animated: true)
    }

    settingVC.viewModel = QChatUpdateChannelViewModel(channel: channel)
    let nav = UINavigationController(rootViewController: settingVC)
    nav.modalPresentationStyle = .fullScreen
    present(nav, animated: true, completion: nil)
  }

  func didClickUserHeader(_ accid: String?) {
    if let uid = accid {
      if QChatKitClient.instance.isMySelf(uid) {
        Router.shared.use(
          MeSettingRouter,
          parameters: ["nav": navigationController as Any],
          closure: nil
        )
      } else {
        Router.shared.use(
          ContactUserInfoPageRouter,
          parameters: ["nav": navigationController as Any, "uid": uid as Any],
          closure: nil
        )
      }
    }
  }
}
