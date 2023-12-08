
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreKit
import NECoreQChatKit
import UIKit
// import NEKeyboardManagerSwift

public class QChatJoinOtherServiceController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource, UITextFieldDelegate {
  private let tag = "JoinOtherServiceController"
  public var serversArray = [QChatServer]()
  public var viewmodel = QChatJoinServerViewModel()
  public var channelViewModel = QChatChannelViewModel()
  public var isAnnouncement = false // 是否是公告频道, 默认false，非公共频道
  public weak var rootController: UIViewController?

  override public func viewDidLoad() {
    super.viewDidLoad()
    viewmodel.isAnnouncement = isAnnouncement
    initializeConfig()
    setupSubviews()
  }

  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NEKeyboardManager.shared.enableAutoToolbar = true
  }

  func initializeConfig() {
    title = isAnnouncement ? localizable("qchat_join_public_server") : localizable("qchat_join_otherServer")
    searchTextField.placeholder = isAnnouncement ? localizable("search_public_serverId") : localizable("search_serverId")
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
  }

  func setupSubviews() {
    view.addSubview(searchTextField)
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      searchTextField.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: CGFloat(kNavigationHeight) + KStatusBarHeight + 20
      ),
      searchTextField.leftAnchor.constraint(
        equalTo: view.leftAnchor,
        constant: kScreenInterval
      ),
      searchTextField.rightAnchor.constraint(
        equalTo: view.rightAnchor,
        constant: -kScreenInterval
      ),
      searchTextField.heightAnchor.constraint(equalToConstant: 32),
    ])

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  // MARK: lazyMethod

  private lazy var searchTextField: SearchTextField = {
    let textField = SearchTextField()

    let image = UIImage(named: "otherService_search_icon",
                        in: Bundle(for: type(of: self)),
                        compatibleWith: nil)
    let leftImageView = UIImageView(image: image)
    textField.contentMode = .center
    textField.leftView = leftImageView
    textField.leftViewMode = .always
    textField.placeholder = localizable("search_serverId")
    textField.font = DefaultTextFont(14)
    textField.textColor = TextNormalColor
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = HexRGB(0xEFF1F4)
    textField.clearButtonMode = .whileEditing
    textField.delegate = self
    textField.addTarget(self, action: #selector(searchTextFieldChange), for: .editingDidEnd)
    textField.keyboardType = .numberPad
    return textField
  }()

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatSearchServerCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(QChatSearchServerCell.self))"
    )
    tableView.rowHeight = 60
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      image: UIImage.ne_imageNamed(name: "searchServer_noMoreData"),
      content: localizable("no_serverId"),
      frame: tableView.bounds
    )
    return view
  }()

  @objc func searchTextFieldChange(textfield: SearchTextField) {
    // 选择高亮文本在进行搜索
    //         let textRange = textfield.markedTextRange
    //         if textRange == nil || ((textRange?.isEmpty) == nil) {
    //             print("111")
    //         }

    if !NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      showToast(localizable("network_error"))
      return
    }

    guard let content = textfield.text else {
      return
    }
    // 空字符串判断
    if content.isBlank {
      emptyView.removeFromSuperview()
      return
    }

    guard let serverId = UInt64(content) else {
      tableView.addSubview(emptyView)
      return
    }
    let param = QChatGetServersParam(serverIds: [NSNumber(value: serverId)])
    viewmodel.getServers(parameter: param) { error, serversArray in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK getServers " + (error?.localizedDescription ?? "no error")
      )
      if error == nil {
        self.serversArray = serversArray
        if self.serversArray.isEmpty {
          self.tableView.addSubview(self.emptyView)
        } else {
          self.emptyView.removeFromSuperview()
        }
        self.tableView.reloadData()
      } else {
        NELog.errorLog(ModuleName + " " + self.tag, desc: "❌getServers failed,error = \(error!)")
      }
    }
  }

  // MARK: UITableViewDelegate  UITableViewDataSource

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    serversArray.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(QChatSearchServerCell.self))",
      for: indexPath
    ) as! QChatSearchServerCell
    cell.serverModel = serversArray[indexPath.row]
    cell.joinServerCallBack = {
      let successView =
        QChatInviteMemberView(frame: CGRect(x: (kScreenWidth - 176) / 2, y: KStatusBarHeight,
                                            width: 176, height: 55))
      successView.showSuccessView()
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let server = serversArray[indexPath.row]
    guard let serverId = server.serverId else { return }

    weak var weakSelf = self

    if isAnnouncement == false {
      if let homeController = rootController as? QChatHomeViewController {
        homeController.setCurrentServer(server: server)
        DispatchQueue.main.async {
          weakSelf?.navigationController?.dismiss(animated: false)
        }
      }
      return
    }

    let param = QChatGetChannelsByPageParam(timeTag: 0, serverId: serverId)
    channelViewModel.getChannelsByPage(parameter: param) { error, result in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK getChannelsByPage " + (error?.localizedDescription ?? "no error")
      )
      if error == nil {
        guard let dataArray = result?.channels else { return }

        if weakSelf?.isAnnouncement == true {
          // 公告频道跳转逻辑
          let chatVC = QChatViewController(channel: nil, server: server)
          weak var weakSelf = self
          weakSelf?.rootController?.navigationController?.pushViewController(chatVC, animated: true)
          DispatchQueue.main.async {
            weakSelf?.navigationController?.dismiss(animated: false)
          }
        }

      } else {
        print("getChannelsByPage failed,error = \(error!)")
      }
    }
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    // 将当前文本字段的文本和正在输入的新字符合并
    let currentText = textField.text ?? ""
    let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)

    // 检查字符数是否超过限制
    let maxLength = 19
    return updatedText.count <= maxLength
  }
}

// MARK: private Method

extension QChatJoinOtherServiceController {
  func showAlert() {
    let alertCtrl = UIAlertController(
      title: localizable("cant_join"),
      message: localizable("blocked_from_server_cant_join"),
      preferredStyle: .alert
    )
    let okAction = UIAlertAction(title: localizable("know"), style: .default, handler: nil)
    alertCtrl.addAction(okAction)
    present(alertCtrl, animated: true, completion: nil)
  }
}

// MARK: SearchTextField

// class SearchTextField:UITextField {
//
//    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
//        var rect = super.leftViewRect(forBounds: bounds)
//        rect.origin.x += 10
//        return rect
//    }
//
//    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
//        var rect = super.placeholderRect(forBounds: bounds)
//        rect.origin.x += 1
//        return rect
//    }
//
//    override func editingRect(forBounds bounds: CGRect) -> CGRect {
//
//        var rect = super.editingRect(forBounds: bounds)
//        rect.origin.x += 5
//        return rect
//
//    }
//
//    override func textRect(forBounds bounds: CGRect) -> CGRect {
//        var rect = super.textRect(forBounds: bounds)
//        rect.origin.x += 5
//        return rect
//    }
// }
