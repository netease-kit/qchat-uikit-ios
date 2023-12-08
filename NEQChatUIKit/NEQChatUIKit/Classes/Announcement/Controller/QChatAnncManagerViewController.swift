//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECommonKit
import NECoreQChatKit
import NEQChatKit
import UIKit

@objcMembers
open class QChatAnncManagerViewController: NEBaseTableViewController, UITableViewDelegate,
  UITableViewDataSource, QChatMemberSelectControllerDelegate, QChatAnncCellDelegate, QChatAnncManagerViewModelDelegate, QChatMemberInfoViewDelegate {
  public var isManager = false // 是否是管理员列表，false 表示普通成员列表
  public var qchatServer: QChatServer?
  let viewmodel = QChatAnncManagerViewModel()
  var isRefresh = false
  var isOwner = false // 是否是创建者，管理员列表使用

  lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(imageName: "user_empty", content: localizable("noMember_add"), frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  override open func viewDidLoad() {
    super.viewDidLoad()
    edgesForExtendedLayout = .bottom
    navigationView.backgroundColor = .clear
    navigationView.titleBarBottomLine.isHidden = false
    viewmodel.delegate = self
    viewmodel.qchatServer = qchatServer
    setupUI()
    getData()
  }

  func setupUI() {
    title = isManager ? localizable("manage_manager") : localizable("manage_subscriber")

    view.addSubview(emptyView)
    NSLayoutConstraint.activate([
      emptyView.leftAnchor.constraint(equalTo: view.leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: view.rightAnchor),
      emptyView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
      emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    setupTable()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -34, right: 0)
    tableView.mj_footer = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    tableView.register(
      QChatAnncMemberCell.self,
      forCellReuseIdentifier: "\(QChatAnncMemberCell.self)"
    )
    tableView.register(
      QChatPlainTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatPlainTextArrowCell.self)"
    )
    tableView.register(
      QChatAnncMemberManagerCell.self,
      forCellReuseIdentifier: "\(QChatAnncMemberManagerCell.self)"
    )
  }

  func loadMoreData() {
    if isManager {
      viewmodel.loadMoreManagerMemberData { [weak self] error, isNoMoreData in
        if isNoMoreData {
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        } else {
          self?.tableView.mj_footer?.endRefreshing()
        }
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
          self?.didReloadTableData()
        }
      }
    } else {
      viewmodel.loadMoreNormalMemberData { [weak self] error, isNoMoreData in
        if isNoMoreData == true {
          self?.tableView.mj_footer?.endRefreshingWithNoMoreData()
        } else {
          self?.tableView.mj_footer?.endRefreshing()
        }
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
          self?.didReloadTableData()
        }
      }
    }
  }

  func getData() {
    if isManager {
      if let owner = qchatServer?.owner, owner == QChatKitClient.instance.imAccid() {
        isOwner = true
      }
      viewmodel.getManagerMembers(qchatServer?.announce?.roleId?.uint64Value, qchatServer?.serverId, qchatServer?.owner) { [weak self] error, isNoMoreData in
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
          self?.didReloadTableData()
        }
      }
    } else {
      viewmodel.checkPermission(qchatServer) { [weak self] error, permission in
        self?.viewmodel.hasPermission = permission
        self?.didReloadTableData()
      }
      viewmodel.getNormalMember(qchatServer?.serverId, qchatServer?.announce?.roleId?.uint64Value, qchatServer?.owner) { [weak self] error, isNoMoreData in
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
          self?.didReloadTableData()
        }
      }
    }
  }

  func getMemeber(index: NSInteger) -> ServerMemeber {
    if isManager {
      return viewmodel.managerMembers[index]
    }
    return viewmodel.normalMembers[index]
  }

  // MARK: QChatMemberInfoViewDelegate

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

  // MARK: Table Delegate

  public func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      if isManager {
        if isOwner == true {
          return 1
        }
        return 0
      }
      if viewmodel.hasPermission {
        return 1
      }
      return 0
    }
    if section == 1 {
      if isManager {
        return viewmodel.managerMembers.count
      }
      return viewmodel.normalMembers.count
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell: QChatPlainTextArrowCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatPlainTextArrowCell.self)",
        for: indexPath
      ) as! QChatPlainTextArrowCell
      cell.showDefaultLine = true
      cell.titleLabel.text = localizable("add_member")
      cell.dividerLineLeftMargin?.constant = 20
      return cell
    }

    if indexPath.section == 1 {
      let user = getMemeber(index: indexPath.row)
      if isManager {
        let cell: QChatAnncMemberManagerCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatAnncMemberManagerCell.self)",
          for: indexPath
        ) as! QChatAnncMemberManagerCell
        cell.configure(user: user)
        cell.removeBtn.isHidden = !isOwner
        cell.removeLabel.isHidden = !isOwner
        var isShow = false
        if isOwner == true {
          isShow = true
        }
        if qchatServer?.owner == user.accid {
          isShow = false
          cell.adminLabel.text = localizable("qchat_notice_channel_creator")
        } else {
          cell.adminLabel.text = localizable("qchat_notice_channel_admin")
        }
        cell.setIsShowRemove(isShow: isShow)
        cell.deletate = self
        cell.indexRow = indexPath.row

        return cell
      } else {
        let cell: QChatAnncMemberCell = tableView.dequeueReusableCell(
          withIdentifier: "\(QChatAnncMemberCell.self)",
          for: indexPath
        ) as! QChatAnncMemberCell
        cell.configure(user: user)
        cell.deletate = self
        cell.indexRow = indexPath.row
        cell.setIsShowRemove(isShow: viewmodel.hasPermission)
        return cell
      }
    }
    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    50
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    nil
  }

  public func tableView(_ tableView: UITableView,
                        viewForFooterInSection section: Int) -> UIView? {
    nil
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      if isManager {
        didAddManagerMember()
      } else {
        didAddNormalMember()
      }
    } else if indexPath.section == 1 {
      let member = getMemeber(index: indexPath.row)
      if isManager {
        if isOwner, member.accid != qchatServer?.owner {
          let memberManager = QChatAnncMemberEditViewController(server: qchatServer, member: member)
          navigationController?.pushViewController(memberManager, animated: true)
        }
      } else {
        Router.shared.use(
          ContactUserInfoPageRouter,
          parameters: ["nav": navigationController as Any, "uid": member.accid as Any],
          closure: nil
        )
      }
    }
  }

  func didAddManagerMember() {
    let memberSelect = QChatMemberSelectController()
    memberSelect.limit = 1
    memberSelect.delegate = self
    memberSelect.serverId = qchatServer?.serverId
    memberSelect.completion = { [weak self] users in

      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        self?.view.makeToast(localizable("network_error"), duration: 2, position: .center)
        return
      }

      var acccIds = [String]()
      users.forEach { user in
        if let accid = user.accid {
          acccIds.append(accid)
        }
      }
      self?.viewmodel.addManagerMember(self?.qchatServer?.serverId, self?.qchatServer?.announce?.roleId?.uint64Value, acccIds) { error in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(localizable("failed_operation"))
          }
        } else {
          self?.didReloadTableData()

          self?.viewmodel.removeMemberRole(self?.qchatServer?.serverId, self?.qchatServer?.announce?.channelId?.uint64Value, acccIds.first)
        }
      }
    }
    navigationController?.pushViewController(memberSelect, animated: true)
  }

  func didAddNormalMember() {
    Router.shared.register(ContactSelectedUsersRouter) { [weak self] param in
      print("param\(param)")
      // 判断网络状态
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        self?.view.makeToast(localizable("network_error"), duration: 2, position: .center)
        return
      }

      if self?.viewmodel.hasPermission == false {
        self?.view.makeToast(localizable("no_permession"), duration: 2, position: .center)
        return
      }
      if let userIds = param["accids"] as? [String] {
        print("userIds:\(userIds)")
        guard let serverId = self?.qchatServer?.serverId else { return }

        self?.viewmodel
          .inviteMembersToServer(serverId: serverId, accids: userIds) { [weak self] error, failedIds in

            if error == nil {
              if let fIds = failedIds, fIds.count == userIds.count {
                self?.view.makeToast(localizable("failed_operation"))
                return
              } else {
                DispatchQueue.main.async {
                  self?.reloadNormalData()
                }
              }
            } else {
              if error?.code == errorCode_NoPermission {
                self?.view.makeToast(localizable("no_permession"), duration: 2, position: .center)
              } else {
                self?.view.makeToast(error?.localizedDescription, duration: 2, position: .center)
              }
            }
          }
      }
    }

    var param = [String: Any]()
    param["nav"] = navigationController
    if viewmodel.allMemberMark.count > 0 {
      param["filters"] = viewmodel.allMemberMark
    }

    Router.shared
      .use(ContactUserSelectRouter,
           parameters: param) { obj, routerState, str in
        print("obj:\(obj) routerState:\(routerState) str:\(str)")
      }
  }

  func reloadNormalData() {
    if isRefresh == true {
      NELog.infoLog(className(), desc: "current is refresh")
      return
    }
    isRefresh = true
    viewmodel.reloadNormalMember(qchatServer?.serverId, qchatServer?.announce?.roleId?.uint64Value, qchatServer?.owner) { [weak self] error in
      self?.isRefresh = false
      if error == nil {
        self?.didReloadTableData()
      }
    }
  }

  public func didClickRemove(index: Int) {
    let user = getMemeber(index: index)
    var name = ""
    if let n = user.nick, n.count > 0 {
      name = n
    } else if let accid = user.accid {
      name = accid
    }

    weak var weakSelf = self
    let message = String(format: localizable("confirm_delete_text"), name) + localizable("qchat_member") + localizable("question_mark")

    let alertVC = UIAlertController.reconfimAlertView(
      title: localizable("removeMember"),
      message: message
    ) {
      if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
        weakSelf?.view.makeToast(localizable("network_error"))
        return
      }

      if weakSelf?.isManager == true {
        weakSelf?.viewmodel.removeManagerMember(weakSelf?.qchatServer?.serverId, weakSelf?.qchatServer?.announce?.roleId?.uint64Value, [user.accid ?? ""]) { error in
          if let err = error as NSError? {
            switch err.code {
            case errorCode_NetWorkError:
              weakSelf?.showToast(localizable("network_error"))
            case errorCode_NoPermission:
              weakSelf?.showToast(localizable("no_permession"))
            default:
              weakSelf?.showToast(err.localizedDescription)
            }
          } else {
            weakSelf?.viewmodel.removeMemberRole(weakSelf?.qchatServer?.serverId, weakSelf?.qchatServer?.announce?.roleId?.uint64Value, user.accid)
          }
        }
      } else {
        if weakSelf?.viewmodel.hasPermission == false {
          weakSelf?.showToast(localizable("no_permession"))
          return
        }

        weakSelf?.viewmodel.removeNormalMeber(weakSelf?.qchatServer?.serverId, [user.accid ?? ""]) { error in
          if let err = error {
            weakSelf?.view.makeToast(err.localizedDescription)
          }
        }
      }
    }
    present(alertVC, animated: true, completion: nil)
  }

  public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
    var param = GetExistingServerRoleMembersByAccidsParam()
    param.serverId = qchatServer?.serverId
    param.accids = accid
    param.roleId = qchatServer?.announce?.roleId?.uint64Value

    viewmodel.repo.getExistingServerRoleMembersByAccids(param) { [weak self] error, accids in
      var dic = [String: String]()
      var retAccids = [String]()
      accids.forEach { aid in
        dic[aid] = aid
      }
      accid?.forEach { aid in
        if dic[aid] != nil {
          retAccids.append(aid)
        }
      }
      if let owner = self?.qchatServer?.owner {
        retAccids.append(owner)
      }
      filterMembers(retAccids)
    }
  }

  public func didNeedRefreshUI() {
    didReloadTableData()
  }

  public func didNeedBack() {
    navigationController?.popViewController(animated: true)
  }

  public func didReloadTableData() {
    checkEmptyView()
    tableView.reloadData()
  }

  // 判断数据是否为空，为空时显示 empty view，不为空隐藏 empty view
  func checkEmptyView() {
    if getDataCount() == 0 {
      emptyView.isHidden = false
    } else {
      emptyView.isHidden = true
    }
  }

  func getDataCount() -> Int {
    if isManager {
      return viewmodel.managerMembers.count
    }
    return viewmodel.normalMembers.count
  }
}
