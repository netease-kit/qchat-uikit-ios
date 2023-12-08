
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreQChatKit
import NEQChatKit
import UIKit

@objcMembers
public class QChatAnncMemberEditViewController: NEBaseTableViewController, UITableViewDataSource,
  UITableViewDelegate, QChatAnncEditMemberViewModelDelegate {
  var member: ServerMemeber?
  var server: QChatServer?
  var viewModel = QChatAnncEditMemberViewModel(server: nil, member: nil)
  var sectionTitle = [localizable("authority_list"), ""]
  var sectionData = [QChatSettingSectionModel]()
  public var cellClassDic = [
    QChatSettingCellType.SettingSwitchCell.rawValue: QChatSwitchCell.self,
    QChatSettingCellType.SettingDestructiveCell.rawValue: QChatDestructiveCell.self,
  ]

  public lazy var headerView: QChatHeaderView = {
    let header = QChatHeaderView()
    header.translatesAutoresizingMaskIntoConstraints = false
    header.configure(iconUrl: member?.avatar, name: member?.nick, uid: UInt64(member?.accid ?? "") ?? 0)
    return header
  }()

  init(server: QChatServer?, member: ServerMemeber?) {
    super.init(nibName: nil, bundle: nil)
    self.server = server
    self.member = member
    viewModel = QChatAnncEditMemberViewModel(server: server, member: member)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    viewModel.delegate = self
    sectionData.append(viewModel.getSetionAuthority())
    sectionData.append(viewModel.getSectionLeave())
    setupUI()
  }

  func setupUI() {
    title = localizable("qchat_edit") + " " + (member?.nick ?? "")
    view.backgroundColor = .ne_lightBackgroundColor
    addLeftAction(UIImage.ne_imageNamed(name: "backArrow"), #selector(back), self)
    addRightAction(localizable("save"), #selector(saveBtnClick(_:)), self)
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveBtnClick(_:)))
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      headerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 22),
      headerView.heightAnchor.constraint(equalToConstant: 92),
    ])

    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .clear

    cellClassDic.forEach { (key: Int, value: QChatCornerCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func back() {
    navigationController?.popViewController(animated: true)
  }

  // MARK: objc 方法

  func saveBtnClick(_ btn: ExpandButton) {
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { [weak self] status in
      if status == .notReachable || status == .unknown {
        self?.view.hideAllToasts()
        self?.showToast(localizable("network_error"))
        return
      }
      self?.viewModel.saveAdminAuthStatus { [weak self] error in
        if let error = error {
          if error.code == errorCode_NetWorkError {
            self?.showToast(localizable("network_error"))
          } else if error.code == errorCode_NoPermission {
            self?.showToast(localizable("save_failed"))
          } else {
            self?.showToast(error.localizedDescription)
          }
        } else {
          self?.showToastInWindow(localizable("update_channel_suscess"))
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  // MARK: QChatAnncEditMemberViewModelDelegate

  public func didClickRemoveAdmin() {
    showAlert(message: String(format: localizable("sure_remove_admin"), member?.nick ?? member?.accid ?? "")) { [weak self] in
      self?.viewModel.removeAdmin { success in
        if success {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  public func didRefresh() {
    tableView.reloadData()
  }

  public func showErrorToast(_ error: NSError) {
    if error.code == errorCode_NetWorkError {
      showToast(localizable("network_error"))
    } else if error.code == errorCode_NoPermission {
      showToast(localizable("no_permission"))
    } else {
      showToast(error.localizedDescription)
    }
  }

  public func showToastInView(_ string: String) {
    showToast(string)
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  public func numberOfSections(in tableView: UITableView) -> Int {
    sectionData.count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sectionData[section].cellModels.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(withIdentifier: "\(model.type)") as? QChatCornerCell {
      cell.dividerLine.isHidden = indexPath.row == sectionData[indexPath.section].cellModels.count - 1
      cell.configure(model: model)
      return cell
    }

    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == sectionData.count - 1 {
      return 40
    }
    return 48
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    let header = QChatTableHeaderView()
    header.titleLabel.text = sectionTitle[section]
    return header
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if section == sectionData.count - 1 {
      return 24
    }
    return 38
  }
}
