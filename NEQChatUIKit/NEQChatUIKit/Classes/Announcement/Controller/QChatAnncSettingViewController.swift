
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

public protocol QChatAnncSettingViewControllerDelegate: NSObjectProtocol {
  func didEmotionEnableChanged(_ enable: Bool)
  func didChannelNameChanged(_ name: String?)
}

public class QChatAnncSettingViewController: NEBaseTableViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, SettingModelDelegate, QChatAnncNameEditViewControllerDelegate {
  var viewModel = QChatSettingViewModel()
  var server: QChatServer?
  public weak var delegate: QChatAnncSettingViewControllerDelegate?
  public var isAdministrator: Bool = true
  var sectionTitle = [String]()
  var sectionData = [QChatSettingSectionModel]()
  public var cellClassDic = [
    QChatSettingCellType.SettingArrowCell.rawValue: QChatTextArrowCell.self,
    QChatSettingCellType.SettingSwitchCell.rawValue: QChatSwitchCell.self,
    QChatSettingCellType.SettingDestructiveCell.rawValue: QChatDestructiveCell.self,
  ]

  lazy var headerView: QChatHeaderCameraView = {
    let header = QChatHeaderCameraView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.isUserInteractionEnabled = true
    header.clipsToBounds = true
    header.backgroundColor = .white
    header.cameraBtn.setImage(coreLoader.loadImage("camera"), for: .normal)
    header.cameraBtn.addTarget(self, action: #selector(cameraClick), for: .touchUpInside)
    header.layer.cornerRadius = 8
    header.configure(iconUrl: server?.icon, name: server?.name, uid: server?.serverId ?? 0)

    return header
  }()

  // 链接 label 的背景视图
  lazy var linkView: UIView = {
    let linkView = UIView()
    linkView.translatesAutoresizingMaskIntoConstraints = false
    linkView.backgroundColor = .white
    linkView.layer.cornerRadius = 8
    return linkView
  }()

  public init(server: QChatServer?, isAdministrator: Bool = true) {
    super.init(nibName: nil, bundle: nil)
    self.server = server
    self.isAdministrator = isAdministrator
    viewModel = QChatSettingViewModel(server: server)
    viewModel.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = false
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    loadData(isAdministrator)
    viewModel.getManagerNumber { [weak self] count in
      self?.viewModel.managerCount = count + 1
      self?.viewModel.getServerMemberNumber { serverMemberCount in
        self?.viewModel.subscriberCount = serverMemberCount - count - 1
      }
    }
  }

  func loadData(_ isAdministrator: Bool) {
    self.isAdministrator = isAdministrator
    sectionTitle = [""]
    sectionData.removeAll()
    headerView.cameraBtn.isHidden = true
    if isAdministrator {
      headerView.cameraBtn.isHidden = false
      sectionTitle.insert(localizable("message_manage"), at: 0)
      sectionTitle.insert(localizable("member_info"), at: 0)
      sectionData.append(viewModel.getSestionMemberInfo())
      sectionData.append(viewModel.getSectionMessageManage(isAdministrator))
    }
    sectionTitle.insert(localizable("channel_info"), at: 0)
    sectionData.insert(viewModel.getSestionChannelInfo(), at: 0)
    sectionData.append(viewModel.getSectionLeave())
  }

  func setupUI() {
    title = localizable("notice_setting")
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      headerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant + 22),
      headerView.heightAnchor.constraint(equalToConstant: 92),
    ])

    addLinkView()
    setupTable()
  }

  override public func setupTable() {
    tableView.bounces = false
    tableView.delegate = self
    tableView.dataSource = self
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }

    cellClassDic.forEach { (key: Int, value: QChatCornerCell.Type) in
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: linkView.bottomAnchor, constant: 0),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func addLinkView() {
    // 链接标题 label
    let linkTitle = UILabel()
    linkTitle.textColor = .ne_greyText
    linkTitle.font = UIFont.systemFont(ofSize: 12.0)
    linkTitle.translatesAutoresizingMaskIntoConstraints = false
    linkTitle.textAlignment = .left
    view.addSubview(linkTitle)
    NSLayoutConstraint.activate([
      linkTitle.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 33),
      linkTitle.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16.0),
    ])
    linkTitle.text = localizable("shared_link")

    // 复制按钮
    let copyButton = ExpandButton()
    copyButton.translatesAutoresizingMaskIntoConstraints = false
    copyButton.backgroundColor = .white
    copyButton.setImage(UIImage.ne_imageNamed(name: "copy"), for: .normal)
    copyButton.addTarget(self, action: #selector(copyButtonClick), for: .touchUpInside)
    linkView.addSubview(copyButton)
    NSLayoutConstraint.activate([
      copyButton.rightAnchor.constraint(equalTo: linkView.rightAnchor, constant: -16),
      copyButton.centerYAnchor.constraint(equalTo: linkView.centerYAnchor),
      copyButton.widthAnchor.constraint(equalToConstant: 16),
      copyButton.heightAnchor.constraint(equalToConstant: 16),
    ])

    // 链接 label
    let link = UILabel()
    link.translatesAutoresizingMaskIntoConstraints = false
    link.font = .systemFont(ofSize: 12)
    link.textColor = .ne_darkText
    link.text = "\(server?.serverId ?? 0)"

    linkView.addSubview(link)
    NSLayoutConstraint.activate([
      link.leftAnchor.constraint(equalTo: linkView.leftAnchor, constant: 16),
      link.rightAnchor.constraint(equalTo: copyButton.leftAnchor, constant: -12),
      link.centerYAnchor.constraint(equalTo: linkView.centerYAnchor),
    ])

    view.addSubview(linkView)
    NSLayoutConstraint.activate([
      linkView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
      linkView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      linkView.topAnchor.constraint(equalTo: linkTitle.bottomAnchor, constant: 8),
      linkView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  // MARK: action

  @objc func cameraClick() {
    viewModel.checkManageChannelPermission { [self] hasPermission in
      if hasPermission {
        showBottomAlert(self)
      } else {
        showToast(localizable("no_permession"))
      }
    }
  }

  @objc func copyButtonClick() {
    UIPasteboard.general.string = "\(server?.serverId ?? 0)"
    showToast(localizable("copy_seccess"))
  }

  func leaveServer() {
    if let serverid = server?.serverId {
      view.makeToastActivity(.center)
      viewModel.repo.leaveServer(serverid) { [weak self] error in
        self?.view.hideToastActivity()
        if let err = error as NSError? {
          NELog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: "leave server error : \(err)")
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
        } else {
          self?.navigationController?.popToRootViewController(animated: true)
        }
      }
    }
  }

  func deleteServer() {
    if let serverid = server?.serverId {
      view.makeToastActivity(.center)
      QChatServerProvider.shared.deleteServer(serverid) { [weak self] error in
        print("delete result : ", error as Any)
        self?.view.hideToastActivity()
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
          self?.navigationController?.popToRootViewController(animated: true)
        }
      }
    }
  }

  // MARK: QChatAnncNameEditViewControllerDelegate

  public func updatedChannelName(name: String?) {
    server?.name = name
    headerView.configure(iconUrl: server?.icon, name: server?.name, uid: server?.serverId ?? 0)
    delegate?.didChannelNameChanged(name)
  }

  // MARK: SettingModelDelegate

  // 点击频道名称
  public func didClickChannelName() {
    let editVC = QChatAnncNameEditViewController(server: server, type: .ChannelName)
    editVC.delegate = self
    navigationController?.pushViewController(editVC, animated: true)
  }

  // 点击频道说明
  public func didClickChannelDesc() {
    let editVC = QChatAnncNameEditViewController(server: server, type: .ChannelDesc)
    editVC.delegate = self
    navigationController?.pushViewController(editVC, animated: true)
  }

  // 点击管理员管理
  public func didClickAdministrator() {
    let controller = QChatAnncManagerViewController()
    controller.isManager = true
    controller.qchatServer = server
    navigationController?.pushViewController(controller, animated: true)
  }

  // 点击订阅者管理
  public func didClickSubscriber() {
    let controller = QChatAnncManagerViewController()
    controller.isManager = false
    controller.qchatServer = server
    navigationController?.pushViewController(controller, animated: true)
  }

  // 点击历史记录
  public func didClickHistory() {
    print("didClickHistory")
  }

  public func didClickEmotionReplyEnable(_ isOpen: Bool) {
    delegate?.didEmotionEnableChanged(isOpen)
  }

  // 点击解散/退出频道
  public func didClickLeave(_ isOwner: Bool) {
    weak var weakSelf = self
    if viewModel.isMyServer() {
      showAlert(message: String(format: localizable("sure_dismiss_channel"), server?.name ?? "")) {
        weakSelf?.deleteServer()
      }
    } else {
      showAlert(message: String(format: localizable("sure_leave_channel"), server?.name ?? "")) {
        weakSelf?.leaveServer()
      }
    }
  }

  public func didRefresh() {
    tableView.reloadData()
  }

  public func didReloadData(_ isAdmin: Bool) {
    loadData(isAdmin)
    tableView.reloadData()
  }

  public func didUpdateServerInfo(_ server: QChatServer?) {
    self.server = server
    headerView.configure(iconUrl: server?.icon, name: server?.name, uid: server?.serverId ?? 0)
  }

  public func showToastInView(_ string: String) {
    showToast(string)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

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
      cell.configure(model: model)

      if let cell = cell as? QChatTextArrowCell {
        cell.detailLabel.textColor = .ne_greyText
      }

      if indexPath.row == sectionData[indexPath.section].cellModels.count - 1 {
        cell.dividerLine.isHidden = true
      } else {
        cell.dividerLine.isHidden = false
      }

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

  // UINavigationControllerDelegate
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController
                               .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    picker.dismiss(animated: true, completion: nil)
  }

  public func uploadHeadImage(image: UIImage) {
    viewModel.checkManageChannelPermission { [weak self] hasPermission in
      if hasPermission {
        self?.view.makeToastActivity(.center)
        if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
          let filePath = NSHomeDirectory().appending("/Documents/")
            .appending(QChatKitClient.instance.imAccid())
          let succcess = imageData.write(toFile: filePath, atomically: true)
          if succcess {
            NIMSDK.shared().resourceManager
              .upload(filePath, progress: nil) { [weak self] urlString, error in
                if let err = error as? NSError {
                  if err.code == 7 {
                    self?.showToast(localizable("network_error"))
                  } else {
                    self?.showToast(err.localizedDescription)
                  }
                } else {
                  self?.updateServer(iconUrl: urlString)
                }
                self?.view.hideToastActivity()
              }
          }
        }
      } else {
        self?.showToast(localizable("no_permession"))
      }
    }
  }

  func updateServer(iconUrl: String?) {
    guard (server?.serverId) != nil else {
      showToast(localizable("serverId_notbe_empty"))
      return
    }

    guard var serverParam = server?.convertUpdateServerParam() else { return }
    serverParam.icon = iconUrl

    viewModel.repo.updateServer(serverParam) { [weak self] error, _ in
      self?.view.hideToastActivity()
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
        // 显示设置的照片
        self?.headerView.configure(iconUrl: iconUrl,
                                   name: self?.server?.name,
                                   uid: self?.server?.serverId ?? 0)
        self?.server?.icon = iconUrl
      }
    }
  }
}
