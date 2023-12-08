
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreIMKit
import NEQChatKit
import UIKit

public class QChatIdGroupViewController: NEBaseTableViewController, UITableViewDelegate,
  UITableViewDataSource, ViewModelDelegate {
  let viewModel = QChatIdGroupViewModel()
  var isOwner = false
  var serverid: UInt64?

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadMoreData()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    viewModel.delegate = self
    viewModel.serverId = serverid

    initializeConfig()
    loadData()
    setupUI()
    weak var weakSelf = self
    viewModel.checkPermission(serverid) { error, permission in
      weakSelf?.setupOperationPermissionUI()
    }
    viewModel.changeBlock = {
      weakSelf?.setupOperationPermissionUI()
    }
  }

  func initializeConfig() {
    title = localizable("qchat_id_group")
    addRightAction(UIImage.ne_imageNamed(name: "sign_add"), #selector(addClick), self)
    navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "sign_add"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(addClick))
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
    navigationView.moreButton.isHidden = true
  }

  func setupUI() {
    setupTable()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatIdGroupCell.self,
      forCellReuseIdentifier: "\(QChatIdGroupCell.self)"
    )
    tableView.register(
      QChatIdGroupTopCell.self,
      forCellReuseIdentifier: "\(QChatIdGroupTopCell.self)"
    )
    tableView.register(
      QChatIdGroupSortButtonCell.self,
      forCellReuseIdentifier: "\(QChatIdGroupSortButtonCell.self)"
    )
    let mjFooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjFooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjFooter
  }

  func loadData() {
    loadMoreData(false)
  }

  @objc func loadMoreData(_ refresh: Bool = true) {
    if let sid = serverid {
      viewModel.getRoles(sid, refresh, nil)
    } else {
      fatalError("serverid must not be nil")
    }
  }

  @objc func refreshData() {
    weak var weakSelf = self
    view.makeToastActivity(.center)
    print("refresh data")
    viewModel.getRoles(weakSelf?.serverid, true) {
      weakSelf?.view.hideToastActivity()
      weakSelf?.tableView.mj_footer?.state = .idle
      weakSelf?.tableView.mj_footer?.isHidden = false
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

  // MARK: UITableViewDelegate, UITableViewDataSource,ViewModelDelegate

  public func dataDidError(_ error: Error) {
    NELog.errorLog(ModuleName + " " + className(), desc: "error : \(error)")
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

  public func dataDidChange() {
    tableView.mj_footer?.endRefreshing()
    tableView.reloadData()
  }

  public func dataNoMore() {
    tableView.mj_footer?.endRefreshingWithNoMoreData()
    tableView.mj_footer?.isHidden = true
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    3
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return viewModel.topDatas.count
    } else if section == 1 {
//      if viewModel.hasManagerRolePermission == false {
//        return 0
//      }
      return viewModel.datas.count > 0 ? viewModel.sortBtnCellDatas.count : 0
    } else if section == 2 {
//      if viewModel.hasManagerRolePermission == false {
//        return 0
//      }
      return viewModel.datas.count
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let model = viewModel.topDatas[indexPath.row]
      let cell: QChatIdGroupTopCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatIdGroupTopCell.self)",
        for: indexPath
      ) as! QChatIdGroupTopCell
      cell.dividerLine.isHidden = true
      cell.configure(model)
      return cell
    } else if indexPath.section == 1 {
      let model = viewModel.sortBtnCellDatas[indexPath.row]
      let cell: QChatIdGroupSortButtonCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatIdGroupSortButtonCell.self)",
        for: indexPath
      ) as! QChatIdGroupSortButtonCell
      cell.titleLabel.text = model.idName
      cell.sortBtn.addTarget(self, action: #selector(toSort), for: .touchUpInside)
      print("hasManagerRolePermission:\(viewModel.hasManagerRolePermission)")
      cell.sortBtn.isHidden = !viewModel.hasManagerRolePermission
      cell.sortImage.isHidden = cell.sortBtn.isHidden
      cell.sortLabel.isHidden = cell.sortBtn.isHidden
      return cell
    } else if indexPath.section == 2 {
      let model = viewModel.datas[indexPath.row]
      let cell: QChatIdGroupCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatIdGroupCell.self)",
        for: indexPath
      ) as! QChatIdGroupCell
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 68
    } else if indexPath.section == 1 {
      return 30
    } else if indexPath.section == 2 {
      return 60
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if section == 1 {
      return 6
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    if section == 1 {
      let view = UIView(frame: CGRect.zero)
      view.backgroundColor = UIColor(hexString: "EFF1F4")
      return view
    }
    return nil
  }

  public func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
    0
  }

  public func tableView(_ tableView: UITableView,
                        viewForFooterInSection section: Int) -> UIView? {
    nil
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      return
    }

    if indexPath.section == 0 {
      let model = viewModel.topDatas[indexPath.row]
      toPermission(model)
    } else if indexPath.section == 2 {
      let model = viewModel.datas[indexPath.row]
      toPermission(model)
    }
  }

  // MARK: objc 方法

  @objc func addClick() {
    let create = QChatCreateGroupViewController()
    create.serverId = serverid
    weak var weakSelf = self
    create.completion = {
      weakSelf?.refreshData()
    }
    navigationController?.pushViewController(create, animated: true)
  }

  @objc func toSort() {
    let sort = QChatIdGroupSortController()
    sort.serverId = serverid
    sort.isOwer = isOwner
    weak var weakSelf = self
    sort.completion = {
      weakSelf?.refreshData()
    }
    navigationController?.pushViewController(sort, animated: true)
  }

  func toPermission(_ model: QChatIdGroupModel) {
    weak var weakSelf = self
    let permission = QChatPermissionViewController()
    permission.idGroup = model
    permission.completion = { role in
      print("update role : ", role.name as Any)

      let temModel = QChatIdGroupModel(role)
      model.idName = temModel.idName
      model.subTitle = temModel.subTitle
      model.role = role
      weakSelf?.tableView.reloadData()
    }
    navigationController?.pushViewController(permission, animated: true)
  }

  func setupOperationPermissionUI() {
    navigationView.moreButton.isHidden = !viewModel.hasManagerRolePermission
    tableView.reloadData()
  }
}
