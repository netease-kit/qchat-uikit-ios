
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECommonKit
import NECommonUIKit
import NECoreKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

@objcMembers
public class QChatViewController: NEBaseViewController, UINavigationControllerDelegate,
  QChatInputViewDelegate, QChatViewModelDelegate, UITableViewDataSource, UITableViewDelegate, NIMMediaManagerDelegate, QChatMessageOperationViewDelegate, QChatAnncSettingViewControllerDelegate {
  private var viewmodel: QChatViewModel?

  // 公告频道对应的 server，非公告频道时为 nil
  var server: QChatServer?
  public var isVisitorMode = false

  public var menuView: QChatInputView = .init()
  public var operationView: QChatMessageOperationView?

  var playAudioModel: QChatMessageFrame?
  var playAudioCell: QChatAudioTableViewCell?
  private var menuViewBottomConstraint: NSLayoutConstraint?
  private var tableViewBottomConstraint: NSLayoutConstraint?

  // 是否是公告频道拥有者/管理员
  public var isAdministrator = true

  public init(channel: ChatChannel?, server: QChatServer? = nil) {
    super.init(nibName: nil, bundle: nil)
    var channel = channel
    self.server = server
    if server != nil {
      channel = ChatChannel()
      channel?.serverId = server?.serverId
      channel?.channelId = server?.announce?.channelId?.uint64Value
    }

    viewmodel = QChatViewModel(channel: channel, server: server)
    viewmodel?.delegate = self
    NIMSDK.shared().mediaManager.add(self)
    if let mode = viewmodel?.repo.settingProvider.getHandSetMode() {
      NIMSDK.shared().mediaManager.switch(mode ? .receiver : .speaker)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewWillAppear(_ animated: Bool) {
    NEKeyboardManager.shared.enable = false
    NEKeyboardManager.shared.shouldResignOnTouchOutside = false
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    addObseve()
    loadData()
    setVisitorMode(isVisitor: isVisitorMode)

    // 如果是公告频道，则需要查是否为管理员
    if server != nil {
      viewmodel?.isAdmistrator(serverId: server?.serverId, accid: QChatKitClient.instance.imAccid(), completion: { [weak self] isAdmin in
        let isAdministrator = QChatKitClient.instance.imAccid() == self?.server?.owner || isAdmin
        self?.isAdministrator = isAdministrator
        self?.reloadMenuView(showInput: isAdministrator)
      })
    }
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    operationView?.removeFromSuperview()
    if NIMSDK.shared().mediaManager.isPlaying() {
      NIMSDK.shared().mediaManager.stopPlay()
      playAudioCell?.stopAnimation()
    }
  }

  // MARK: lazy Method

  private lazy var brokenNetworkView: NEBrokenNetworkView = .init(frame: CGRect(x: 0, y: topConstant, width: kScreenWidth, height: 36))

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .white
    tableView.keyboardDismissMode = .onDrag
    tableView.mj_header = MJRefreshNormalHeader(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    return tableView
  }()

  // 话题只读提示视图
  lazy var onlyReadView: UIView = {
    let tipLabel = UILabel(frame: CGRect(x: (kScreenWidth - 110) / 2, y: 16, width: 110, height: 22))
    tipLabel.text = localizable("channel_read_only")
    tipLabel.textColor = .ne_adminLabelTextColor
    tipLabel.textAlignment = .center

    let view = UIView(frame: CGRect(x: 0, y: kScreenHeight - 90, width: kScreenWidth, height: 90))
    view.backgroundColor = .ne_noInteractionColor
    view.isHidden = true
    view.addSubview(tipLabel)
    return view
  }()

  lazy var visitorBanner: QChatVisitorBannerView = {
    let view = QChatVisitorBannerView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  deinit {
    NELog.infoLog(ModuleName + " " + self.className(), desc: "✅ QChatViewController release")
    NIMSDK.shared().mediaManager.remove(self)
  }

  func commonUI() {
    title = viewmodel?.channel?.name
    if server != nil {
      // 公告频道
      title = server?.name
    }
    addLeftAction(UIImage.ne_imageNamed(name: "server_menu"), #selector(enterServerVC), self)
    addRightAction(
      UIImage.ne_imageNamed(name: "channel_member"),
      #selector(enterChannelMemberVC),
      self
    )
    navigationView.setBackButtonImage(UIImage.ne_imageNamed(name: "server_menu"))
    navigationView.addBackButtonTarget(target: self, selector: #selector(enterServerVC))
    navigationView.setMoreButtonImage(UIImage.ne_imageNamed(name: "channel_member"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(enterChannelMemberVC))
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false

    var tip = localizable("send_to")
    if let cName = viewmodel?.channel?.name {
      tip += cName
    } else if let serverName = server?.name {
      tip += serverName
    }
    menuView.textField.placeholder = tip

    menuView.translatesAutoresizingMaskIntoConstraints = false
    menuView.delegate = self
    view.addSubview(menuView)
    menuViewBottomConstraint = menuView.topAnchor.constraint(
      equalTo: view.bottomAnchor,
      constant: -100
    )
    NSLayoutConstraint.activate([
      menuView.leftAnchor.constraint(equalTo: view.leftAnchor),
      menuView.rightAnchor.constraint(equalTo: view.rightAnchor),
      menuView.heightAnchor.constraint(equalToConstant: 304),
    ])

    /*
     if #available(iOS 11.0, *) {
       self.menuViewBottomConstraint = menuView.bottomAnchor
         .constraint(equalTo: self.view.bottomAnchor)
       NSLayoutConstraint.activate([
         menuView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
         menuView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
         menuView.heightAnchor.constraint(equalToConstant: 100),
       ])
     } else {
       // Fallback on earlier versions
       menuViewBottomConstraint = menuView.bottomAnchor
         .constraint(equalTo: view.bottomAnchor)
       NSLayoutConstraint.activate([
         menuView.leftAnchor.constraint(equalTo: view.leftAnchor),
         menuView.rightAnchor.constraint(equalTo: view.rightAnchor),
         menuView.heightAnchor.constraint(equalToConstant: 100),
       ])
     } */
    menuViewBottomConstraint?.isActive = true

    view.addSubview(tableView)
    tableViewBottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
    tableViewBottomConstraint?.isActive = true

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: topConstant
      ),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
    ])

    tableView.register(
      QChatBaseTableViewCell.self,
      forCellReuseIdentifier: "\(QChatBaseTableViewCell.self)"
    )
    tableView.register(
      QChatTextTableViewCell.self,
      forCellReuseIdentifier: "\(QChatTextTableViewCell.self)"
    )
    tableView.register(
      QChatImageTableViewCell.self,
      forCellReuseIdentifier: "\(QChatImageTableViewCell.self)"
    )

    tableView.register(
      QChatAudioTableViewCell.self,
      forCellReuseIdentifier: "\(QChatAudioTableViewCell.self)"
    )

//    NEKeyboardManager.shared.keyboardDistanceFromTextField = 60
    NEKeyboardManager.shared.enable = true
    NEKeyboardManager.shared.enableAutoToolbar = false

    NEChatDetectNetworkTool.shareInstance.netWorkReachability { [weak self] status in
      if status == .notReachable, let networkView = self?.brokenNetworkView {
        self?.view.addSubview(networkView)
      } else {
        self?.brokenNetworkView.removeFromSuperview()
      }
    }
  }

  func reloadMenuView(showInput: Bool) {
    if showInput {
      menuView.isHidden = false
      onlyReadView.isHidden = true
      if onlyReadView.superview != nil {
        onlyReadView.removeFromSuperview()
      }
    } else {
      // 无发言权限(只读)
      menuView.isHidden = true
      onlyReadView.isHidden = false
      if onlyReadView.superview == nil {
        view.addSubview(onlyReadView)
      }
    }
  }

  //    MARK: event

  open func setVisitorMode(isVisitor: Bool) {
    menuView.isUserInteractionEnabled = !isVisitor
    if isVisitor {
      view.addSubview(visitorBanner)
      NSLayoutConstraint.activate([
        visitorBanner.bottomAnchor.constraint(equalTo: menuView.topAnchor),
        visitorBanner.leftAnchor.constraint(equalTo: view.leftAnchor),
        visitorBanner.rightAnchor.constraint(equalTo: view.rightAnchor),
        visitorBanner.heightAnchor.constraint(equalToConstant: 50),
      ])
      visitorBanner.joinButton.addTarget(self, action: #selector(visitorJoinServer(_:)), for: .touchUpInside)
    } else {
      visitorBanner.removeFromSuperview()
    }

    menuView.setVisitorModel(isVisitorMode: isVisitor)
  }

  open func visitorJoinServer(_ sender: UIButton) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    guard let sid = viewmodel?.channel?.serverId else {
      return
    }
    sender.isEnabled = false
    weak var weakSelf = self
    let param = QChatApplyServerJoinParam(serverId: sid)
    viewmodel?.applyServerJoin(parameter: param) { error in
      sender.isEnabled = true
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
        weakSelf?.tableView.reloadData()
        weakSelf?.setVisitorMode(isVisitor: false)
      }
    }
  }

  func enterChannelMemberVC() {
    // 公告频道
    if server != nil {
      let settingVC = QChatAnncSettingViewController(server: server, isAdministrator: isAdministrator)
      settingVC.delegate = self
      navigationController?.pushViewController(settingVC, animated: true)
      return
    }

    let memberVC = QChatChannelMembersVC()
    memberVC.channel = viewmodel?.channel
    memberVC.isVisitorMode = isVisitorMode
    navigationController?.pushViewController(memberVC, animated: true)
  }

  func enterServerVC() {
    navigationController?.popViewController(animated: true)
  }

  func loadData() {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      viewmodel?.getMessageHistory { [weak self] error in
        if let err = error {
          NELog.errorLog(ModuleName + " " + (self?.className() ?? ""), desc: "CALLBACK error:\(err)")
        } else {
          if let time = self?.viewmodel?.messages.first?.message?.timestamp {
            self?.viewmodel?.markMessageRead(time: time)
          }
          if let tempArray = self?.viewmodel?.messages, tempArray.count > 0 {
            self?.tableView.reloadData()
            self?.tableViewScrollToBottom(row: tempArray.count - 1, animated: false)
          } else {
            self?.loadMoreData(true)
          }
        }
      }
    } else {
      loadMoreData(true)
    }
  }

  func loadMoreData(_ isBottom: Bool = false) {
    viewmodel?.getMoreMessageHistory { [weak self] error in
      NELog.infoLog(
        ModuleName + " " + (self?.className() ?? ""),
        desc: "CALLBACK getMoreMessageHistory " + (error?.localizedDescription ?? "no error")
      )
      if let time = self?.viewmodel?.messages.last?.message?.timestamp {
        self?.viewmodel?.markMessageRead(time: time)
      }
      self?.tableView.reloadData()
      self?.tableView.mj_header?.endRefreshing()
      if isBottom == true, let count = self?.viewmodel?.messages.count, count > 0 {
        self?.tableViewScrollToBottom(row: count - 1, animated: false)
      }
    }
  }

  func addObseve() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onUpdateChannel),
      name: NotificationName.updateChannel,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onDeleteChannel),
      name: NotificationName.deleteChannel,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyBoardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyBoardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )

    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTap))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  func onUpdateChannel(noti: Notification) {
    // enter ChatVC
    guard let channel = noti.object as? ChatChannel else {
      return
    }
    viewmodel?.channel = channel
    title = channel.name
  }

  func onDeleteChannel(noti: Notification) {
    popToRootViewController()
  }

  func popToRootViewController() {
    // 移除所有弹窗
    dismiss(animated: true)
    navigationController?.popToRootViewController(animated: true)
  }

  open func viewTap(tap: UITapGestureRecognizer) {
    if let opeView = operationView,
       view.subviews.contains(opeView) {
      opeView.removeFromSuperview()
    } else {
      if menuView.textField.isFirstResponder {
        menuView.textField.resignFirstResponder()
      } else {
        layoutInputView(offset: 0)
      }
    }
  }

  // MARK: UIGestureRecognizerDelegate

  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldReceive touch: UITouch) -> Bool {
    guard let view = touch.view else {
      return true
    }

    // 表情回复按钮
    if view.bounds.size.width == 48 {
      return false
    }

    // 消息操作按钮
    if view.bounds.size.width == 30, view.bounds.size.height == 42 {
      return false
    }
    // 点击重发按钮
    // 点击撤回重新编辑按钮
    if view.isKind(of: UIButton.self) {
      return false
    }
    if view.isKind(of: UIImageView.self) {
      return false
    }
    return true
  }

  // MARK: 键盘通知相关操作

  func keyBoardWillShow(_ notification: Notification) {
    operationView?.removeFromSuperview()
    if menuView.currentType != .text {
      return
    }
    menuView.currentButton?.isSelected = false

    menuView.contentSubView?.isHidden = true
    let oldKeyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue

    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

    print("chat view key board size : ", keyboardRect)
    layoutInputView(offset: keyboardRect.size.height)
    weak var weakSelf = self
    UIView.animate(withDuration: 0.25, animations: {
      weakSelf?.view.layoutIfNeeded()
    })

    // 键盘已经弹出
    if oldKeyboardRect == keyboardRect {
      return
    }

    scrollTableViewToBottom()
  }

  func keyBoardWillHide(_ notification: Notification) {
    if menuView.currentType != .text {
      return
    }
    layoutInputView(offset: 0)
  }

  private func scrollTableViewToBottom(_ animated: Bool = true) {
    tableView.reloadData()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: { [weak self] in
      if let row = self?.tableView.numberOfRows(inSection: 0), row > 0 {
        self?.tableViewScrollToBottom(row: row - 1, animated: animated)
      }
    }))
  }

  // MARK: QChatmenuViewDelegate

  public func sendText(text: String?) {
    NELog.infoLog(ModuleName + " " + className(), desc: "sendText:\(text ?? "")")
    guard let content = text, content.count > 0 else {
      return
    }
    viewmodel?.sendTextMessage(text: content) { [weak self] error in
      NELog.infoLog(
        ModuleName + " " + (self?.className() ?? "QChatViewController"),
        desc: "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
      }
    }
  }

  public func willSelectItem(button: UIButton, index: Int) {
    operationView?.removeFromSuperview()
    if button.isSelected == true || button.tag - 5 == 2 {
      if index == 0 {
        layoutInputView(offset: 204)
        scrollTableViewToBottom()
      } else if index == 1 {
        layoutInputView(offset: 204)
        scrollTableViewToBottom()
      } else if index == 2 {
        showBottomAlert(self, false, false) { [weak self] in
          if NIMSDK.shared().mediaManager.isPlaying() {
            NIMSDK.shared().mediaManager.stopPlay()
            self?.playAudioCell?.stopAnimation()
            self?.playAudioModel?.isPlaying = false
          }
        }
      } else if index == 3 {
        layoutInputView(offset: 204)
        scrollTableViewToBottom()
      } else {
        showToast(localizable("open_soon"))
      }
    } else {
      layoutInputView(offset: 0)
    }
  }

  private func layoutInputView(offset: CGFloat) {
    if offset == 0 {
      menuView.contentSubView?.isHidden = true
      menuView.currentButton?.isSelected = false
    }
    UIView.animate(withDuration: 0.1, animations: { [weak self] in
      self?.menuViewBottomConstraint?.constant = -100 - offset
      self?.tableViewBottomConstraint?.constant = -100 - offset
    })
  }

  //    MARK: UIImagePickerControllerDelegate

  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController
                                      .InfoKey: Any]) {
    picker.dismiss(animated: true, completion: nil)
    guard let image = info[.originalImage] as? UIImage else {
      showToast(localizable("image_is_nil"))
      return
    }
    // 发送消息
    viewmodel?.sendImageMessage(image: image) { [weak self] error in
      NELog.infoLog(
        ModuleName + " " + (self?.className() ?? "QChatViewController"),
        desc: "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
      )
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
      }
    }
  }

  //    MARK: QChatViewModelDelegate

  public func onRecvMessages(_ messages: [NIMQChatMessage]) {
    operationView?.removeFromSuperview()
    scrollTableViewToBottom(false)
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        if let sid = viewmodel?.channel?.serverId, sid != systemNoti.serverId {
          continue
        }
        if systemNoti.type == .channelRemove {
          if systemNoti.channelId == viewmodel?.channel?.channelId,
             systemNoti.fromAccount != IMKitLoginManager.instance.currentAccount() {
            popToRootViewController()
          }
        } else if systemNoti.type == .serverRemove {
          if let sid = viewmodel?.channel?.serverId, sid == systemNoti.serverId {
            popToRootViewController()
          }
        } else if systemNoti.type == .serverMemberLeave {
          if systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
            popToRootViewController()
          }
        } else if systemNoti.type == .serverMemberKick,
                  let attach = systemNoti.attach as? NIMQChatKickServerMembersDoneAttachment {
          if attach.kickedAccids?.contains(QChatKitClient.instance.imAccid()) == true {
            // 被踢除
            popToRootViewController()
          }
        } else if systemNoti.type == .serverMemberApplyDone {
          if let sid = viewmodel?.channel?.serverId, sid == systemNoti.serverId, systemNoti.fromAccount == QChatKitClient.instance.imAccid() {
            isVisitorMode = false
            setVisitorMode(isVisitor: isVisitorMode)
          }
        } else if systemNoti.type == .channelUpdateWhiteBlackMember,
                  let attach = systemNoti.attach as? NIMQChatUpdateChannelBlackWhiteMemberAttachment {
          // 黑白名单变更
          if attach.updateBlackWhiteMembersInfo?.accids.contains(QChatKitClient.instance.imAccid()) == true {
            if attach.updateBlackWhiteMembersInfo?.type == .white, attach.updateBlackWhiteMembersInfo?.opeType == .remove {
              // 自己被移除白名单
              popToRootViewController()
            } else if attach.updateBlackWhiteMembersInfo?.type == .black, attach.updateBlackWhiteMembersInfo?.opeType == .add {
              // 自己被加入黑名单
              popToRootViewController()
            }
          }
        } else if systemNoti.type == .serverUpdate,
                  let updateAttach = systemNoti.attach as? NIMQChatUpdateServerAttachment {
          // 更新社区
          let newServer = QChatServer(server: updateAttach.server)
          if server?.announce?.emojiReplay != newServer.announce?.emojiReplay {
            tableView.reloadData()
          }
          server = newServer
          title = server?.name
        } else if systemNoti.type == .addServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatAddServerRoleMembersNotificationAttachment {
          // 添加社区身份组成员
          if systemNoti.serverId == server?.serverId, attach.roleId == server?.announce?.roleId?.uint64Value {
            // 添加管理员
            if attach.addServerRoleAccIds?.contains(QChatKitClient.instance.imAccid()) == true {
              // 自己被添加, 刷新页面
              isAdministrator = true
              reloadMenuView(showInput: isAdministrator)
            }
          }
        } else if systemNoti.type == .removeServerRoleMembers,
                  let attach = systemNoti.attach as? NIMQChatRemoveServerRoleMembersNotificationAttachment {
          // 移除社区身份组成员
          if systemNoti.serverId == server?.serverId, attach.roleId == server?.announce?.roleId?.uint64Value {
            // 移除管理员
            if attach.removeServerRoleAccIds?.contains(QChatKitClient.instance.imAccid()) == true {
              // 自己被移除, 刷新页面
              isAdministrator = false
              reloadMenuView(showInput: isAdministrator)
            }
          }
        }
      }
    }
  }

  public func send(_ message: NIMQChatMessage, progress: Float) {}

  public func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?) {
    if let e = error as NSError? {
      if e.code == errorCode_NoPermission {
        showSingleAlert(message: localizable("no_permession_to_send")) {}
      }
    }
    scrollTableViewToBottom(false)
  }

  public func willSend(_ message: NIMQChatMessage) {
    scrollTableViewToBottom(false)
  }

  public func onDeleteMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath]) {
    if atIndexs.isEmpty {
      return
    }
    dismiss(animated: true) // 清除弹框
    operationView?.removeFromSuperview()
    tableViewDeleteIndexs(atIndexs)
  }

  public func onRevokeMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath]) {
    dismiss(animated: true) // 清除弹框
    operationView?.removeFromSuperview()
    tableViewReloadIndexs(atIndexs)
  }

  public func onReloadMessage(_ message: NIMQChatMessage, atIndexs: [IndexPath]) {
    tableViewReloadIndexs(atIndexs)
  }

  // MARK: QChatAnncSettingViewControllerDelegate

  public func didEmotionEnableChanged(_ enable: Bool) {
    server?.announce?.emojiReplay = enable ? 1 : 0
    tableView.reloadData()
  }

  public func didChannelNameChanged(_ name: String?) {
    title = name
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel?.messages.count ?? 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let messageFrame = viewmodel?.messages[indexPath.row]
    if isVisitorMode {
      // 游客模式不能表情评论
      messageFrame?.enableQuickComment = false
    } else if server == nil {
      // 非公共频道默认开启表情评论
      messageFrame?.enableQuickComment = true
    } else {
      messageFrame?.enableQuickComment = (server?.announce?.emojiReplay ?? 0) == 1
    }

    var reuseIdentifier = "\(QChatBaseTableViewCell.self)"

    guard let msgFrame = messageFrame else {
      return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }

    if msgFrame.isRevoked {
      reuseIdentifier = "\(QChatTextTableViewCell.self)"
    } else {
      // 根据cell类型区分identify
      switch msgFrame.message?.messageType {
      case .text:
        reuseIdentifier = "\(QChatTextTableViewCell.self)"
      case .image:
        reuseIdentifier = "\(QChatImageTableViewCell.self)"
      case .audio:
        reuseIdentifier = "\(QChatAudioTableViewCell.self)"
      default:
        reuseIdentifier = "\(QChatBaseTableViewCell.self)"
      }
    }

    let cell = tableView.dequeueReusableCell(
      withIdentifier: reuseIdentifier,
      for: indexPath
    ) as! QChatBaseTableViewCell
    cell.messageFrame = messageFrame
    cell.delegate = self

    if let audioCell = cell as? QChatAudioTableViewCell {
      if let m = messageFrame {
        if NIMSDK.shared().mediaManager.isPlaying(),
           m.message?.messageId == playAudioModel?.message?.messageId {
          playAudioCell = audioCell
          playAudioCell?.startAnimation()
        }
        if m.isPlaying == false {
          audioCell.stopAnimation()
        }
      }
    }
    return cell
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    let messageFrame = viewmodel?.messages[indexPath.row]
    if indexPath.row == (viewmodel?.messages.count ?? 0) - 1 {
      return (messageFrame?.cellHeight ?? 0) + 10
    }
    return messageFrame?.cellHeight ?? 0
  }

  func tableViewScrollToBottom(row: Int, animated: Bool) {
    tableView.scrollToRow(
      at: IndexPath(row: row, section: 0),
      at: .bottom,
      animated: animated
    )
  }

  open func tableViewDeleteIndexs(_ indexs: [IndexPath]) {
    tableView.beginUpdates()
    tableView.deleteRows(at: indexs, with: .none)
    tableView.endUpdates()
  }

  open func tableViewReloadIndexs(_ indexs: [IndexPath]) {
    if #available(iOS 11.0, *) {
      tableView.performBatchUpdates { [weak self] in
        self?.tableView.reloadRows(at: indexs, with: .none)
      }
    } else {
      tableView.beginUpdates()
      tableView.reloadRows(at: indexs, with: .none)
      tableView.endUpdates()
    }
  }

  // MARK: UIScrollViewDelegate

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    operationView?.removeFromSuperview()
  }

  // record audio
  public func startRecord() {
    let dur = 60.0
    if NEAuthManager.hasAudioAuthoriztion() {
      NIMSDK.shared().mediaManager.record(forDuration: dur)
    } else {
      NEAuthManager.requestAudioAuthorization { [weak self] granted in
        if granted {
        } else {
          DispatchQueue.main.async {
            self?.showSingleAlert(message: commonLocalizable("jump_microphone_setting")) {}
          }
        }
      }
    }
  }

  public func moveOutView() {}

  public func moveInView() {}

  public func endRecord(insideView: Bool) {
    print("[record] stop:\(insideView)")
    if insideView {
      //            send
      NIMSDK.shared().mediaManager.stopRecord()
    } else {
      //            cancel
      NIMSDK.shared().mediaManager.cancelRecord()
    }
  }

  public func playAudio(_ filePath: String, progress value: Float) {}

  public func playAudioInterruptionEnd() {
    print(#function)
    playAudioCell?.stopAnimation()
    playAudioModel?.isPlaying = false
  }

  public func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playAudioCell?.stopAnimation()
    playAudioModel?.isPlaying = false
  }

  //    play
  public func playAudio(_ filePath: String, didBeganWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
      // stop
      playAudioCell?.stopAnimation()
      playAudioModel?.isPlaying = false
    }
  }

  public func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    // stop
    playAudioCell?.stopAnimation()
    playAudioModel?.isPlaying = false
  }

  public func stopPlayAudio(_ filePath: String, didCompletedWithError error: Error?) {
    playAudioCell?.stopAnimation()
    playAudioModel?.isPlaying = false
  }

  //    record
  public func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
    playAudioCell?.stopAnimation()
    playAudioModel?.isPlaying = false
    print("[record] sdk Began error:\(error)")
  }

  public func recordAudio(_ filePath: String?, didCompletedWithError error: Error?) {
    print("[record] sdk Completed error:\(error)")
    menuView.stopRecordAnimation()
    guard let fp = filePath else {
      showToast(error?.localizedDescription ?? "")
      return
    }

    let dur = recordDuration(filePath: fp)

    print("dur:\(dur)")
    if dur > 1 {
      viewmodel?.sendAudioMessage(path: fp) { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.className() ?? ""),
          desc: "CALLBACK sendAudioMessage " + (error?.localizedDescription ?? "no error")
        )
        if let e = error {
          self?.showToast(e.localizedDescription)
        } else {}
      }
    } else {
      showToast(coreLoader.localizable("record_too_short"))
    }
  }

  private func recordDuration(filePath: String) -> Float64 {
    let avAsset = AVURLAsset(url: URL(fileURLWithPath: filePath))
    return CMTimeGetSeconds(avAsset.duration)
  }

  public func textDelete(range: NSRange, text: String) -> Bool {
    true
  }

  public func textChanged(text: String) -> Bool {
    true
  }

  public func textFieldDidChange(_ textField: UITextView) {}

  public func textFieldDidEndEditing(_ textField: UITextView) {}

  public func textFieldDidBeginEditing(_ textField: UITextView) {}
}

// MARK: ===============   QNEChatBaseCellDelegate   ================

extension QChatViewController: QChatBaseCellDelegate {
  func didSelectWithCell(cell: QChatBaseTableViewCell, type: QChatMessageClickType,
                         message: NIMQChatMessage) {
    if type == .message {
      didClickMessage(messgae: message)
      if let audioCell = cell as? QChatAudioTableViewCell? {
        if NIMSDK.shared().mediaManager.isPlaying() {
          playAudioCell?.stopAnimation()
          NIMSDK.shared().mediaManager.stopPlay()
          if playAudioModel != audioCell?.messageFrame {
            playAudioModel = audioCell?.messageFrame
            playAudioCell = audioCell
            if let object = message.messageObject as? NIMAudioObject, let path = object.path {
              NIMSDK.shared().mediaManager.play(path)
              playAudioCell?.startAnimation()
            }
          }
        } else {
          playAudioModel = audioCell?.messageFrame
          playAudioCell = audioCell
          if let object = message.messageObject as? NIMAudioObject, let path = object.path {
            NIMSDK.shared().mediaManager.play(path)
            playAudioCell?.startAnimation()
          }
        }
      }
    } else if type == .LongPressMessage {}
  }

  /// 头像单击手势
  func didClickHeader(_ message: NIMQChatMessage) {
    if QChatKitClient.instance.isMySelf(message.from) == true {
      Router.shared.use(
        MeSettingRouter,
        parameters: ["nav": navigationController as Any],
        closure: nil
      )
    } else {
      Router.shared.use(
        ContactUserInfoPageRouter,
        parameters: ["nav": navigationController as Any, "uid": message.from as Any],
        closure: nil
      )
    }
  }

  /// 消息单击手势
  func didClickMessage(messgae: NIMQChatMessage) {
    operationView?.removeFromSuperview()
    if messgae.messageType == .image {
      var imageUrl = ""
      let imageObject = messgae.messageObject as! NIMImageObject
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) == true {
        imageUrl = path
      } else if let url = imageObject.url {
        imageUrl = url
      }
      let showController = PhotoBrowserController(urls: viewmodel?.getUrls() ?? [imageUrl], url: imageUrl)
      showController.modalPresentationStyle = .overFullScreen
      present(showController, animated: false, completion: nil)

    } else if messgae.messageType == .audio {}
  }

  /// 消息长按手势
  func didLongPress(_ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?) {
    addOperationView(showOperation: true,
                     showMoreButton: true,
                     cell,
                     messageFrame)
  }

  public func didTapReeditButton(_ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?) {
    // 公告频道失去发消息权限
    if !isAdministrator {
      showToast(localizable("no_permession"))
      return
    }

    // 超出重新编辑期限
    if let msgTime = messageFrame?.message?.timestamp {
      let currenTime = Date().timeIntervalSince1970
      if currenTime - msgTime >= 2 * 60 {
        showToast(localizable("editable_time_expired"))
        if let indexPath = tableView.indexPath(for: cell) {
          tableView.reloadRows(at: [indexPath], with: .none)
        } else {
          tableView.reloadData()
        }
        return
      }
    }

    if messageFrame?.isRevoked == true,
       messageFrame?.message?.messageType == .text,
       let text = messageFrame?.revokeText {
      menuView.textField.attributedText = NEEmotionTool.getAttWithStr(str: text, font: DefaultTextFont(16))
      menuView.textField.becomeFirstResponder()
    }
  }

  // 点击快捷评论区中的表情
  func didClickEmojiComment(_ type: Int, _ cell: UITableViewCell, _ messageFrame: QChatMessageFrame?) {
    if isVisitorMode {
      return
    }

    if server == nil || server?.announce?.emojiReplay == 1 {
      viewmodel?.operationModel = messageFrame

      if type == -1 {
        // 点击添加表情按钮
        addOperationView(showAllEmoji: true,
                         showOperation: false,
                         showMoreButton: false,
                         cell,
                         messageFrame)
      } else {
        // 点击已经存在的表情评论
        clickEmoji(Int64(type), messageFrame)
      }
    } else {
      showToast(localizable("comment_not_support"))
    }
  }

  public func didSelectedItem(item: QChatOperationItem) {
    switch item.type {
    case .copy:
      copyMessage()
    case .recall:
      revokeMessage()
    case .delete:
      deleteMessage()
    default:
      print("didSelectedItem: default")
    }
  }

  // 点击操作菜单中的表情
  public func didSelectedEmoji(emoji: NIMInputEmoticon) {
    if server == nil || server?.announce?.emojiReplay == 1 {
      if let emojiID = emoji.emoticonID,
         let emojiId = Int64(emojiID.replacingOccurrences(of: "emoticon_emoji_", with: "")) {
        // 表情类型不能为 0
        let type = emojiId + 1
        clickEmoji(type, viewmodel?.operationModel)
      }
    } else {
      showToast(localizable("comment_not_support"))
    }
  }

  /// 添加操作菜单视图
  /// - Parameters:
  ///   - showAllEmoji: 是否显示所有表情
  func addOperationView(showAllEmoji: Bool = false,
                        showOperation: Bool = true,
                        showMoreButton: Bool = true,
                        _ cell: UITableViewCell,
                        _ messageFrame: QChatMessageFrame?) {
    if isVisitorMode {
      return
    }
    if messageFrame?.isRevoked == true || messageFrame?.message?.deliveryState == .delivering {
      return
    }

    // 移除现有的操作视图
    operationView?.removeFromSuperview()

    // 底部收起
    menuView.textField.resignFirstResponder()
    layoutInputView(offset: 0)

    viewmodel?.operationModel = messageFrame

    var showEmoji = true

    if (server != nil && server?.announce?.emojiReplay == 0) || isVisitorMode {
      // 无表情评论权限
      showEmoji = false
    }

    if messageFrame?.message?.deliveryState == .failed {
      // 发送失败的消息不展示表情评论入口
      showEmoji = false
    }

    // 获取当前cell的操作类型
    guard let items = QChatMessageHelper.avalibleOperationsForMessage(messageFrame,
                                                                      enableEdit: isAdministrator,
                                                                      isAnnouncement: server != nil && messageFrame?.message?.isOutgoingMsg == false) else {
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: { [self] in
      // 操作菜单的宽高
      let frameW = showEmoji ? 350.0 : (items.count <= 5 ? Double(items.count) * 67.5 - 37.5 + 50.0 : 5 * 67.5 - 37.5 + 50.0)
      let emojiCollectionH = showEmoji ? 56.0 : 0.0
      let frameH = showAllEmoji ? 310 : emojiCollectionH + 18.0 + 58.0 * ceil(Double(items.count) / 5.0)

      var underMessage = true
      if let index = tableView.indexPath(for: cell) {
        let rectInTableView = tableView.rectForRow(at: index)
        let rectInView = tableView.convert(rectInTableView, to: tableView.superview)
        let midY = kScreenHeight / 2 // 屏高中线
        var operationY = rectInView.origin.y + rectInView.size.height
        if operationY > midY {
          // 显示在消息上方
          underMessage = false
          operationY = rectInView.origin.y - frameH
          if messageFrame?.showTime == true,
             let timeHeight = messageFrame?.timeFrame.height {
            operationY += timeHeight + qChat_margin
          }
        } else {
          operationY += qChat_margin
        }

        // 边界处理
        if operationY <= 0 {
          operationY = midY
        }

        var frameX = qChat_margin
        if let msg = messageFrame?.message,
           msg.isOutgoingMsg {
          frameX = kScreenWidth - frameW - qChat_margin
        }
        let frame = CGRect(x: frameX, y: operationY, width: frameW, height: frameH)
        operationView = QChatMessageOperationView(frame: frame, showEmoji: showEmoji)
        operationView?.delegate = self
        operationView?.items = items
        operationView?.oldFrameHeight = frameH
        operationView?.viewUnderMessage = underMessage
        operationView?.showMoreButton = showMoreButton
        if showOperation {
          operationView?.showOperation()
        } else {
          operationView?.showAllEmoji()
        }

        view.addSubview(operationView!)
      }
    }))
  }

  /// 点击表情之后的操作（添加/移除评论）
  public func clickEmoji(_ type: Int64, _ messageFrame: QChatMessageFrame?) {
    guard let message = messageFrame?.message else { return }
    if viewmodel?.hasQuickComment(type: type) == true {
      viewmodel?.deleteQuickComment(type: type, to: message, completion: { [weak self] error in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          default:
            self?.showToast(err.localizedDescription)
          }
        }
      })
    } else {
      // 超出限制表情评论数量
      if let quickComments = viewmodel?.operationModel?.quickComments,
         quickComments.count > emojiCommentLimit {
        showToast(localizable("comment_limit_expired"))
        return
      }

      viewmodel?.addQuickComment(type: type, to: message, completion: { [weak self] error in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          default:
            self?.showToast(err.localizedDescription)
          }
        }
      })
    }
  }

  public func copyMessage() {
    if let text = viewmodel?.operationModel?.message?.text {
      let pasteboard = UIPasteboard.general
      pasteboard.string = text
      view.makeToast(localizable("copy_success"), duration: 2, position: .center)
    }
  }

  public func revokeMessage() {
    showAlert(message: localizable("message_revoke_confirm")) { [weak self] in
      self?.viewmodel?.revokeMessage { error, updateResult in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_TimeOut:
            self?.showToast(localizable("ravokable_time_expired"))
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
        }
      }
    }
  }

  public func deleteMessage() {
    showAlert(message: localizable("message_delete_confirm")) { [weak self] in
      self?.viewmodel?.deleteMessage { error, updateResult in
        if let err = error as NSError? {
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
        }
      }
    }
  }
}
