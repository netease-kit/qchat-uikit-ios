
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreAudio
import MJRefresh
import NECoreQChatKit
import NEQChatKit
import UIKit

typealias AddMemberRoleBlock = (_ memberRole: MemberRole?) -> Void
public class QChatAddMemberVC: QChatSearchVC {
  public var channel: ChatChannel?
  private var serverMembers: [ServerMemeber]?
  private var channelMembers: [ServerMemeber]?
  private var lastTimeTag: Double?
//    public var didAddMemberRole: AddMemberRoleBlock?

  public init(channel: ChatChannel?) {
    super.init(nibName: nil, bundle: nil)
    self.channel = channel
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    title = localizable("add_member")
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false

    tableView.register(
      QChatImageTextCell.self,
      forCellReuseIdentifier: "\(QChatImageTextCell.self)"
    )
    tableView.rowHeight = 60
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadData)
    )
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMore)
    )
    loadData()
  }

  @objc func loadData() {
    lastTimeTag = 0
    var param = GetServerMembersByPageParam()
    param.serverId = channel?.serverId
    param.limit = 50
    param.timeTag = lastTimeTag
    QChatServerProvider.shared.getServerMembers(param) { [weak self] error, sMembers in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
        self?.emptyView.isHidden = false
      } else {
        if !sMembers.isEmpty {
          self?.lastTimeTag = sMembers.last?.createTime
//                    var filteredMemberArray = sMembers
          if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
            // 过滤掉已经存在在channel中的成员
            var ids = [String]()
            for member in sMembers {
              if let id = member.accid {
                ids.append(id)
              }
            }
            let param = GetExistingAccidsOfMemberRolesParam(
              serverId: sid,
              channelId: cid,
              accids: ids
            )
            QChatRoleProvider.shared
              .getExistingMemberRoles(param: param) { error, existMemberArray in
                var filterMembers = [ServerMemeber]()
                if let existMembers = existMemberArray, !existMembers.isEmpty {
                  for m in sMembers {
                    if existMembers.contains(where: { existMember in
                      m.accid == existMember.accid || m.accid == IMKitLoginManager.instance.currentAccount()
                    }) {
                    } else {
                      filterMembers.append(m)
                    }
                  }
                  self?.serverMembers = filterMembers
                  self?.emptyView.isHidden = !filterMembers.isEmpty

                } else {
                  var serMembers = [ServerMemeber]()
                  for sMem in sMembers {
                    if sMem.accid != IMKitLoginManager.instance.currentAccount() {
                      serMembers.append(sMem)
                    }
                  }
                  self?.serverMembers = serMembers
                  self?.emptyView.isHidden = !serMembers.isEmpty
                }
                self?.tableView.mj_footer?.resetNoMoreData()
                self?.tableView.mj_header?.endRefreshing()
                self?.tableView.reloadData()
              }
          } else {
            self?.emptyView.isHidden = !sMembers.isEmpty
            self?.serverMembers = sMembers
            self?.tableView.mj_footer?.resetNoMoreData()
            self?.tableView.mj_header?.endRefreshing()
            self?.tableView.reloadData()
          }
        } else {
          // 空白页
          self?.emptyView.isHidden = false
        }
      }
    }
  }

  @objc func loadMore() {
    var param = GetServerMembersByPageParam()
    param.serverId = channel?.serverId
    param.limit = 50
    param.timeTag = lastTimeTag
    QChatServerProvider.shared.getServerMembers(param) { [weak self] error, sMembers in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
      } else {
        if !sMembers.isEmpty {
          self?.lastTimeTag = sMembers.last?.createTime
          if let sid = self?.channel?.serverId, let cid = self?.channel?.channelId {
            // 过滤掉已经存在在channel中的成员
            var ids = [String]()
            for member in sMembers {
              if let id = member.accid {
                ids.append(id)
              }
            }
            let param = GetExistingAccidsOfMemberRolesParam(
              serverId: sid,
              channelId: cid,
              accids: ids
            )
            QChatRoleProvider.shared
              .getExistingMemberRoles(param: param) { error, existMemberArray in
                if let existMembers = existMemberArray, !existMembers.isEmpty {
                  for m in sMembers {
                    if existMembers.contains(where: { existMember in
                      m.accid == existMember.accid || m.accid == IMKitLoginManager.instance.currentAccount()
                    }) {
                    } else {
                      self?.serverMembers?.append(m)
                    }
                  }
                }
                self?.emptyView.removeFromSuperview()
                self?.tableView.mj_footer?.endRefreshing()
                self?.tableView.reloadData()
              }
          } else {
            for m in sMembers {
              if m.accid != IMKitLoginManager.instance.currentAccount() {
                self?.serverMembers?.append(m)
              }
            }
            self?.emptyView.isHidden = true
            self?.tableView.mj_footer?.endRefreshing()
            self?.tableView.reloadData()
          }
        } else {
          self?.emptyView.isHidden = true
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        }
      }
    }
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    serverMembers?.count ?? 0
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(QChatImageTextCell.self)",
      for: indexPath
    ) as! QChatImageTextCell
    cell.backgroundColor = .white
    cell.rightStyle = .indicate
    let member = serverMembers?[indexPath.row]
    cell.setup(accid: member?.accid, nickName: member?.nick, avatar: member?.avatar)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // 成员权限设置
    let member = serverMembers?[indexPath.row]
    addMemberInChannel(member: member, index: indexPath.row)
  }

  private func addMemberInChannel(member: ServerMemeber?, index: Int) {
    let param = AddMemberRoleParam(
      serverId: channel?.serverId,
      channelId: channel?.channelId,
      accid: member?.accid
    )
    QChatRoleProvider.shared.addMemberRole(param) { [weak self] error, memberRole in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        case errorCode_NoExist:
          self?.showToast(localizable("qchat_member_no_exist"))
        case errorCode_Existed:
          self?.showToast(localizable("qchat_member_exised"))
        default:
          self?.showToast(err.localizedDescription)
        }
      } else {
        self?.serverMembers?.remove(at: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: DispatchWorkItem(block: {
          self?.showToastInWindow(localizable("qchat_add_success"))
          self?.emptyView.isHidden = !(self?.serverMembers?.isEmpty ?? true)
        }))
        self?.tableView.reloadData()
        let settingVC = QChatMemberPermissionSettingVC(
          channel: self?.channel,
          memberRole: memberRole
        )
        self?.navigationController?.pushViewController(settingVC, animated: true)
//                if let block = self.didAddMemberRole {
//                    block(memberRole)
//                }
      }
    }
  }

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      image: UIImage.ne_imageNamed(name: "rolePlaceholder"),
      content: localizable("noMember_add"),
      frame: CGRect(
        x: 0,
        y: topConstant,
        width: self.view.bounds.size.width,
        height: self.view.bounds.size.height
      )
    )
    self.view.addSubview(view)
    return view
  }()
}
