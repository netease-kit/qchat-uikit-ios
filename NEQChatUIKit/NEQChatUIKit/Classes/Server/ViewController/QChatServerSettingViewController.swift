
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

typealias SaveSuccessBlock = (_ server: QChatServer?) -> Void

public class QChatServerSettingViewController: NEBaseTableViewController, UITableViewDelegate,
  UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate {
  let viewModel = QChatSettingViewModel()
  var server: QChatServer?
  var permissions = [QChatSettingModel]()

  var headerImageUrl: String?

  var headerImage: NEUserHeaderView?

  lazy var serverNameInput: UITextField = getInput()

  lazy var serverThemeInput: UITextField = getInput()

  var topicInput: UITextField?

  private let className = "QChatServerSettingViewController"

  lazy var headerBackView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  lazy var serverName: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.textColor = .ne_darkText
    return label
  }()

  public init(server: QChatServer?) {
    super.init(nibName: nil, bundle: nil)
    self.server = server
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
    initializeConfig()
    setupUI()
    viewModel.server = server
    permissions = viewModel.getSetionAuthority().cellModels
    weak var weakSelf = self
    viewModel.didGoBack = {
      weakSelf?.navigationController?.popToRootViewController(animated: true)
    }
  }

  func initializeConfig() {
    addRightAction(localizable("save"), #selector(saveClick), self)
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveClick))
    navigationView.backgroundColor = .ne_lightBackgroundColor
  }

  func setupUI() {
    title = localizable("qchat_setting")
    view.backgroundColor = .ne_lightBackgroundColor

    view.addSubview(headerBackView)
    NSLayoutConstraint.activate([
      headerBackView.leftAnchor.constraint(equalTo: view.leftAnchor),
      headerBackView.rightAnchor.constraint(equalTo: view.rightAnchor),
      headerBackView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      headerBackView.heightAnchor.constraint(equalToConstant: 334),
    ])

    let cornerView = UIView()
    cornerView.translatesAutoresizingMaskIntoConstraints = false
    headerBackView.addSubview(cornerView)
    NSLayoutConstraint.activate([
      cornerView.topAnchor.constraint(equalTo: headerBackView.topAnchor, constant: 22),
      cornerView.leftAnchor.constraint(equalTo: headerBackView.leftAnchor, constant: 20),
      cornerView.rightAnchor.constraint(equalTo: headerBackView.rightAnchor, constant: -20),
      cornerView.heightAnchor.constraint(equalToConstant: 98),
    ])
    cornerView.clipsToBounds = true
    cornerView.layer.cornerRadius = 8
    cornerView.backgroundColor = .white

    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    cornerView.addSubview(header)
    NSLayoutConstraint.activate([
      header.widthAnchor.constraint(equalToConstant: 60),
      header.heightAnchor.constraint(equalToConstant: 60),
      header.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 16),
      header.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 16),
    ])
    header.isUserInteractionEnabled = true
    header.clipsToBounds = true
    header.backgroundColor = UIColor.colorWithNumber(number: server?.serverId)
    header.layer.cornerRadius = 30
    headerImage = header
    if let icon = server?.icon {
      header.sd_setImage(with: URL(string: icon), completed: nil)
    } else {
      if let name = server?.name {
        header.setTitle(name)
      }
    }

    let cameraBtn = ExpandButton()
    cornerView.addSubview(cameraBtn)
    cameraBtn.translatesAutoresizingMaskIntoConstraints = false
    cameraBtn.backgroundColor = .ne_backcolor
    NSLayoutConstraint.activate([
      cameraBtn.leftAnchor.constraint(equalTo: cornerView.leftAnchor, constant: 58),
      cameraBtn.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 58),
      cameraBtn.widthAnchor.constraint(equalToConstant: 26),
      cameraBtn.heightAnchor.constraint(equalToConstant: 26),
    ])
    cameraBtn.layer.cornerRadius = 12
    cameraBtn.clipsToBounds = true
    cameraBtn.layer.borderColor = UIColor.white.cgColor
    cameraBtn.layer.borderWidth = 2
    cameraBtn.addTarget(self, action: #selector(cameraClick), for: .touchUpInside)

    let camera = UIImageView()
    camera.translatesAutoresizingMaskIntoConstraints = false
    cornerView.addSubview(camera)
    camera.backgroundColor = .clear
    camera.image = coreLoader.loadImage("camera")
    NSLayoutConstraint.activate([
      camera.centerXAnchor.constraint(equalTo: cameraBtn.centerXAnchor),
      camera.centerYAnchor.constraint(equalTo: cameraBtn.centerYAnchor, constant: -2),
    ])

    serverName.text = server?.name
    cornerView.addSubview(serverName)
    NSLayoutConstraint.activate([
      serverName.leftAnchor.constraint(equalTo: header.rightAnchor, constant: 16),
      serverName.rightAnchor.constraint(equalTo: cornerView.rightAnchor, constant: -16),
      serverName.topAnchor.constraint(equalTo: cornerView.topAnchor, constant: 30),
    ])

    let account = UILabel()
    account.translatesAutoresizingMaskIntoConstraints = false
    account.textColor = UIColor.ne_emptyTitleColor
    account.font = UIFont.systemFont(ofSize: 12)
    cornerView.addSubview(account)
    NSLayoutConstraint.activate([
      account.leftAnchor.constraint(equalTo: serverName.leftAnchor),
      account.rightAnchor.constraint(equalTo: serverName.rightAnchor),
      account.topAnchor.constraint(equalTo: serverName.bottomAnchor, constant: 6),
    ])
    account.text = "ID: \(server?.serverId ?? 0)"

    addInputView(headerBackView, cornerView)
    setupTable()
  }

  override public func setupTable() {
    tableView.bounces = false
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatDestructiveCell.self,
      forCellReuseIdentifier: "\(QChatDestructiveCell.self)"
    )
    tableView.delegate = self
    tableView.dataSource = self
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: headerBackView.bottomAnchor, constant: 0),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func addInputView(_ back: UIView, _ topView: UIView) {
    let serverNameLabel = getTagLabel()
    back.addSubview(serverNameLabel)
    NSLayoutConstraint.activate([
      serverNameLabel.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 33),
      serverNameLabel.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 16.0),
    ])
    serverNameLabel.text = localizable("qchat_server_name")

    back.addSubview(serverNameInput)
    NSLayoutConstraint.activate([
      serverNameInput.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 20),
      serverNameInput.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -20),
      serverNameInput.topAnchor.constraint(equalTo: topView.bottomAnchor, constant: 38),
      serverNameInput.heightAnchor.constraint(equalToConstant: 50),
    ])
    serverNameInput.placeholder = localizable("enter_name")
    serverNameInput.tag = 50
    if let name = server?.name {
      serverNameInput.text = name
    }

    let serverThemeLabel = getTagLabel()
    back.addSubview(serverThemeLabel)
    NSLayoutConstraint.activate([
      serverThemeLabel.leftAnchor.constraint(equalTo: serverNameLabel.leftAnchor),
      serverThemeLabel.topAnchor.constraint(
        equalTo: serverNameInput.bottomAnchor,
        constant: 16
      ),
    ])
    serverThemeLabel.text = localizable("qchat_server_theme")

    back.addSubview(serverThemeInput)
    NSLayoutConstraint.activate([
      serverThemeInput.leftAnchor.constraint(equalTo: back.leftAnchor, constant: 20),
      serverThemeInput.rightAnchor.constraint(equalTo: back.rightAnchor, constant: -20),
      serverThemeInput.topAnchor.constraint(
        equalTo: serverNameInput.bottomAnchor,
        constant: 38
      ),
      serverThemeInput.heightAnchor.constraint(equalToConstant: 50),
    ])
    serverThemeInput.placeholder = localizable("qchat_please_input_topic")
    if let custom = server?.custom, let dic = getDictionaryFromJSONString(custom),
       let topic = dic["topic"] as? String, topic.count > 0 {
      serverThemeInput.text = topic
    }
    serverThemeInput.tag = 64

    let permissionLabel = getTagLabel()
    back.addSubview(permissionLabel)
    NSLayoutConstraint.activate([
      permissionLabel.leftAnchor.constraint(equalTo: serverThemeLabel.leftAnchor),
      permissionLabel.topAnchor.constraint(
        equalTo: serverThemeInput.bottomAnchor,
        constant: 16
      ),
    ])
    permissionLabel.text = localizable("qchat_permission")
  }

  func getTagLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor(hexString: "666666")
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .left
    return label
  }

  func getInput() -> UITextField {
    let textField = UITextField()
    textField.backgroundColor = .white
    textField.clipsToBounds = true
    textField.layer.cornerRadius = 8
    textField.font = UIFont.systemFont(ofSize: 16.0)
    textField.translatesAutoresizingMaskIntoConstraints = false
    let leftSpace = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
    textField.leftView = leftSpace
    textField.leftViewMode = .always
    textField.delegate = self
    return textField
  }

  // MARK: action

  @objc func cameraClick() {
    // print("camera click")
    showBottomAlert(self)
  }

  @objc func saveClick() {
    print("save click")

    var name = ""

    if let currentName = serverNameInput.text, currentName.trimmingCharacters(in: .whitespaces).count > 0 {
      name = currentName
    } else if let originServerName = server?.name, originServerName.count > 0 {
      name = originServerName
    }

    if name.count <= 0 {
      showToast(localizable("qchat_not_empty_servername"))
      return
    }

    guard let _ = server?.serverId else {
      showToast(localizable("serverId_notbe_empty"))
      return
    }

    guard var serverParam = server?.convertUpdateServerParam() else { return }
    serverParam.name = name
    serverParam.icon = headerImageUrl

    if let topic = serverThemeInput.text, topic.count > 0 {
      serverParam.custom = getJSONStringFromDictionary(["topic": topic])
    }
    weak var weakSelf = self

    view.makeToastActivity(.center)
    print("update param : ", serverParam)
    viewModel.repo.updateServer(serverParam) { error, newServer in
      print("update finish : ", error as Any)
      weakSelf?.view.hideToastActivity()
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
        weakSelf?.server = newServer
        weakSelf?.navigationController?.popViewController(animated: true)
      }
      weakSelf?.headerImage?.configHeadData(headUrl: weakSelf?.server?.icon,
                                            name: weakSelf?.server?.name ?? "",
                                            uid: "\(weakSelf?.server?.serverId ?? 0)")
      weakSelf?.serverNameInput.text = weakSelf?.server?.name
      weakSelf?.serverThemeInput.text = weakSelf?.server?.topic
    }
  }

  func leaveServer() {
    if let serverid = server?.serverId {
      view.makeToastActivity(.center)
      viewModel.repo.leaveServer(serverid) { [weak self] error in
        self?.view.hideToastActivity()
        if let err = error as NSError? {
          NELog.errorLog(ModuleName + " " + (self?.className ?? ""), desc: "leave server error : \(err)")
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
        } else {
          self?.navigationController?.popViewController(animated: true)
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
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
  }

  // MARK: UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate

  public func textFieldDidChangeSelection(_ textField: UITextField) {
    guard let _ = textField.markedTextRange else {
      if let text = textField.text,
         text.count > textField.tag {
        textField.text = String(text.prefix(textField.tag))
      }
      return
    }
  }

  public func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    print("count section : ", section)
    if section == 0 {
      return permissions.count
    } else if section == 1 {
      return 1
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let textCell: QChatTextArrowCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextArrowCell.self)",
        for: indexPath
      ) as! QChatTextArrowCell
      let model = permissions[indexPath.row]
      textCell.titleLabel.text = model.title
      textCell.backgroundColor = .clear
      textCell.cornerType = model.cornerType
      if indexPath.row != permissions.count - 1 {
        textCell.dividerLine.isHidden = false
      }
      return textCell
    } else if indexPath.section == 1 {
      let destructiveCell: QChatDestructiveCell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatDestructiveCell.self)",
        for: indexPath
      ) as! QChatDestructiveCell

      destructiveCell.redTextLabel
        .text = isMyServer() ? localizable("qchat_delete_server") :
        localizable("qchat_leave_server")
      destructiveCell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      return destructiveCell
    }

    return UITableViewCell()
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let memberCtrl = QChatMemberListViewController()
        memberCtrl.serverId = server?.serverId
        navigationController?.pushViewController(memberCtrl, animated: true)
      } else if indexPath.row == 1 {
        let idGroupController = QChatIdGroupViewController()
        idGroupController.serverid = server?.serverId
        if let owner = server?.owner, owner == QChatKitClient.instance.imAccid() {
          idGroupController.isOwner = true
        }
        navigationController?.pushViewController(idGroupController, animated: true)
      }

    } else if indexPath.section == 1 {
      print("click delete")
      weak var weakSelf = self
      if isMyServer() == true {
        showAlert(message: localizable("sure_delete_server")) {
          weakSelf?.deleteServer()
        }
      } else {
        showAlert(message: localizable("sure_exit_server")) {
          weakSelf?.leaveServer()
        }
      }
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 48
    } else if indexPath.section == 1 {
      return 40
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    if section == 1 {
      return UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 24))
    }
    return nil
  }

  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    if section == 1 {
      return 24
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
    0
  }

  func isMyServer() -> Bool {
    if let owner = server?.owner {
      let accid = QChatKitClient.instance.imAccid()
      if owner == accid {
        return true
      }
    }
    return false
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
    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
      let filePath = NSHomeDirectory().appending("/Documents/")
        .appending(QChatKitClient.instance.imAccid())
      let succcess = imageData.write(toFile: filePath, atomically: true)
      weak var weakSelf = self
      if succcess {
        NIMSDK.shared().resourceManager
          .upload(filePath, progress: nil) { urlString, error in
            if error == nil {
              // 显示设置的照片
              weakSelf?.headerImage?.image = image
              weakSelf?.headerImageUrl = urlString
              weakSelf?.headerImage?.titleLabel.isHidden = true
              print("upload image success")
            } else {
              print("upload image failed,error = \(error!)")
            }
            weakSelf?.view.hideToastActivity()
          }
      }
    }
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let text = textField.text {
      let newText = (text as NSString).replacingCharacters(in: range, with: string)
      if newText.utf16.count > textField.tag {
        return false
      }
    }
    return true
  }
}
