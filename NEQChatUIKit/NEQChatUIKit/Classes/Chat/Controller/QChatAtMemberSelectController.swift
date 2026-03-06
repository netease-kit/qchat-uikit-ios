// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECommonKit
import NECommonUIKit
import NEQChatKit
import NIMQChat
import UIKit

/// 选择 @ 成员后的回调: (显示名（含"@"前缀）, accid)
public typealias QChatAtMemberSelectBlock = (String, String) -> Void

/// QChat @提及 成员选择控制器
public class QChatAtMemberSelectController: NEBaseViewController,
  UITableViewDelegate, UITableViewDataSource {
  // MARK: - Public Properties

  /// 频道信息
  public var channel: NEQChatChatChannel?

  /// 选中成员后的回调
  public var selectedBlock: QChatAtMemberSelectBlock?

  // MARK: - Private Properties

  private var members: [NEQChatServerMemeber] = []
  private var lastMember: NEQChatServerMemeber?

  // MARK: - UI

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.rowHeight = 60
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatGroupIdentityMemberCell.self,
      forCellReuseIdentifier: "\(QChatGroupIdentityMemberCell.self)"
    )
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    return tableView
  }()

  // MARK: - Lifecycle

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadData()
  }

  // MARK: - Setup

  private func setupUI() {
    title = localizable("qchat_member")
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: - Data

  private func loadData() {
    guard let channel = channel else { return }
    var param = NEQChatChannelMembersParam(
      serverId: channel.serverId ?? 0,
      channelId: channel.channelId ?? 0
    )
    param.limit = 50
    QChatChannelProvider.shared.getChannelMembers(param: param) { [weak self] _, result in
      self?.members = result?.memberArray ?? []
      self?.lastMember = result?.memberArray?.last
      DispatchQueue.main.async {
        self?.tableView.reloadData()
        self?.tableView.mj_footer?.resetNoMoreData()
      }
    }
  }

  @objc private func loadMoreData() {
    guard let channel = channel else {
      tableView.mj_footer?.endRefreshingWithNoMoreData()
      return
    }
    var param = NEQChatChannelMembersParam(
      serverId: channel.serverId ?? 0,
      channelId: channel.channelId ?? 0
    )
    param.timeTag = lastMember?.createTime
    param.limit = 50
    QChatChannelProvider.shared.getChannelMembers(param: param) { [weak self] _, result in
      guard let self = self, let newMembers = result?.memberArray, !newMembers.isEmpty else {
        self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        return
      }
      self.members.append(contentsOf: newMembers)
      self.lastMember = newMembers.last
      self.tableView.reloadData()
      self.tableView.mj_footer?.endRefreshing()
    }
  }

  // MARK: - UITableViewDataSource

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    members.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatGroupIdentityMemberCell.self)",
      for: indexPath
    ) as! QChatGroupIdentityMemberCell
    let member = members[indexPath.row]
    cell.memberModel = member
    cell.arrowImageView.isHidden = true
    return cell
  }

  // MARK: - UITableViewDelegate

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let member = members[indexPath.row]
    let displayName = (member.nick?.count ?? 0 > 0) ? (member.nick ?? "") : (member.accid ?? "")
    let addText = "@" + displayName
    let accid = member.accid ?? ""
    selectedBlock?(addText, accid)
    dismiss(animated: true, completion: nil)
  }
}
