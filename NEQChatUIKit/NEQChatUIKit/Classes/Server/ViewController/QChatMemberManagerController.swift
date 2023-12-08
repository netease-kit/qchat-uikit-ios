
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreQChatKit
import NEQChatKit
import UIKit

typealias MemberCountChange = (Int) -> Void

public class QChatMemberManagerController: NEBaseTableViewController, UITableViewDelegate,
  UITableViewDataSource, ViewModelDelegate, QChatMemberSelectControllerDelegate {
  let viewmodel = QChatMemberManagerViewModel()

  var memberCount = 0 {
    didSet {
      countChangeBlock?(memberCount)
    }
  }

  var serverId: UInt64?

  var roleId: UInt64?

  var countChangeBlock: MemberCountChange?

  // 是否是管理员管理页面
  // true: 管理员管理, false: 订阅者管理, nil: 成员管理
  var isAdministrator: Bool?

  init(serverId: UInt64? = nil, roleId: UInt64? = nil, isAdministrator: Bool? = nil) {
    super.init(nibName: nil, bundle: nil)
    self.serverId = serverId
    self.roleId = roleId
    self.isAdministrator = isAdministrator
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    viewmodel.delegate = self
    loadMoreData()
    setupUI()
  }

  func setupUI() {
    title = localizable("qchat_manager_member")
    if isAdministrator != nil {
      title = isAdministrator == true ? localizable("administrator_manage") : localizable("subscriber_manage")
    }
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    view.backgroundColor = .white
    setupTable()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatMemberManagerCell.self,
      forCellReuseIdentifier: "\(QChatMemberManagerCell.self)"
    )
    tableView.register(
      QChatPlainTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatPlainTextArrowCell.self)"
    )

    let mjfooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjfooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjfooter
  }

  @objc func loadMoreData(_ refresh: Bool = false) {
    if let rid = roleId, let sid = serverId {
      viewmodel.getData(sid, rid, refresh)
    } else {
      print("serverId or roleId is nil")
    }
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

  // MARK: UITableViewDelegate, UITableViewDataSource,ViewModelDelegate,QChatMemberSelectControllerDelegate

  public func filterMembers(accid: [String]?, _ filterMembers: @escaping ([String]?) -> Void) {
    var param = GetExistingServerRoleMembersByAccidsParam()
    param.serverId = serverId
    param.accids = accid
    param.roleId = roleId
    print("param existing accid : ", accid as Any)
    viewmodel.repo.getExistingServerRoleMembersByAccids(param) { error, accids in
      NELog.infoLog(ModuleName + " " + self.className(), desc: #function + ", accids:\(accids)")
//      print("getExistingServerRoleMembersByAccids : ", accids)
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
      print("filter members : ", retAccids)
      filterMembers(retAccids)
    }
  }

  public func dataDidChange() {
    memberCount = viewmodel.datas.count
    view.hideToastActivity()
    tableView.mj_footer?.endRefreshing()
    tableView.reloadData()
  }

  public func dataNoMore() {
    view.hideToastActivity()
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer?.isHidden = true
  }

  public func dataDidError(_ error: Error) {
    view.hideToastActivity()
    if let err = error as NSError? {
      switch err.code {
      case errorCode_NetWorkError:
        showToast(localizable("network_error"))
      case errorCode_NoPermission:
        showToast(localizable("no_permession"))
      default:
        showToast(err.localizedDescription)
      }
    }
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    if section == 1 {
      return viewmodel.datas.count
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
      cell.titleLabel.text = localizable("add_member")
      cell.detailLabel.text = isAdministrator != nil ? nil : "\(memberCount)"
      cell.dividerLine.isHidden = false
      return cell
    }

    if indexPath.section == 1 {
      let cell: QChatMemberManagerCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatMemberManagerCell.self)",
        for: indexPath
      ) as! QChatMemberManagerCell
      let user = viewmodel.datas[indexPath.row]
      cell.user = user
      return cell
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
    weak var weakSelf = self
    if indexPath.section == 0 {
      let memberSelect = QChatMemberSelectController()
      memberSelect.delegate = self
      memberSelect.serverId = serverId
      memberSelect.completion = { users in
        print("member manager select: ", users)
        weakSelf?.view.makeToastActivity(.center)
        weakSelf?.viewmodel
          .addMembers(users, weakSelf?.serverId, weakSelf?.roleId) { successCount in
            NELog.infoLog(ModuleName + " " + (weakSelf?.className() ?? "QChatMemberManagerController"), desc: "✅ CALLBACK SUCCESS")
            weakSelf?.view.hideToastActivity()
            weakSelf?.showToast(localizable("qchat_add_success"))
            weakSelf?.memberCount += successCount
          }
      }
      navigationController?.pushViewController(memberSelect, animated: true)
    } else {
      let user = viewmodel.datas[indexPath.row]
      showAlert(title: localizable("removeMember"), message: String(format: localizable("confirm_delete_text"), user.nickName ?? "") + localizable("qchat_member") + localizable("question_mark")) {
        if let rid = weakSelf?.roleId, let sid = weakSelf?.serverId {
          weakSelf?.view.makeToastActivity(.center)
          weakSelf?.viewmodel.remove(user, sid, rid) { failedCount in
            NELog.infoLog(ModuleName + " " + self.className(), desc: #function + ", serverId:\(sid)")
            weakSelf?.view.hideToastActivity()
            if failedCount > 0 {
              weakSelf?.loadMoreData(true)
            } else {
              weakSelf?.viewmodel.datas.remove(at: indexPath.row)
              weakSelf?.memberCount -= 1
              weakSelf?.tableView.reloadData()
            }
          }
        }
      }
    }
  }
}
