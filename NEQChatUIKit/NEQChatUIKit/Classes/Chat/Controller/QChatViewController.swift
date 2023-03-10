
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NIMSDK
import MJRefresh
import NECommonUIKit
import NECommonKit
import NECoreKit

@objcMembers
public class QChatViewController: NEBaseViewController, UINavigationControllerDelegate,
  QChatInputViewDelegate, QChatViewModelDelegate, UITableViewDataSource, UITableViewDelegate, NIMMediaManagerDelegate {
  private let tag = "QChatViewController"
  private var viewmodel: QChatViewModel?
  private var menuViewBottomConstraint: NSLayoutConstraint?
  private var tableViewBottomConstraint: NSLayoutConstraint?
  public var menuView: QChatInputView = .init()
  weak var playAudioCell: QChatAudioTableViewCell?

  public init(channel: ChatChannel?) {
    super.init(nibName: nil, bundle: nil)
    viewmodel = QChatViewModel(channel: channel)
    viewmodel?.delegate = self
    NIMSDK.shared().mediaManager.add(self)
    if let mode = viewmodel?.repo.settingProvider.getHandSetMode() {
      NIMSDK.shared().mediaManager.setNeedProximityMonitor(mode)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    addObseve()
    loadData()
    print("current view frame :", view.frame)
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if NIMSDK.shared().mediaManager.isPlaying() {
      NIMSDK.shared().mediaManager.stopPlay()
      playAudioCell?.stopAnimation()
    }
  }

  // MARK: lazy Method

  private lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: kNavigationHeight + KStatusBarHeight,
                                        width: kScreenWidth, height: 36))
    return view
  }()

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

  deinit {
    NELog.infoLog(ModuleName + " " + self.tag, desc: "✅ QChatViewController release")
    NIMSDK.shared().mediaManager.remove(self)
  }

  func commonUI() {
    title = viewmodel?.channel?.name
    addLeftAction(UIImage.ne_imageNamed(name: "server_menu"), #selector(enterServerVC), self)
    addRightAction(
      UIImage.ne_imageNamed(name: "channel_member"),
      #selector(enterChannelMemberVC),
      self
    )

    var tip = localizable("send_to")
    if let cName = viewmodel?.channel?.name {
      tip += cName
    }
    menuView.textField.placeholder = tip as NSString

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

    if #available(iOS 10, *) {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: kNavigationHeight + KStatusBarHeight
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(
          equalTo: view.topAnchor,
          constant: 0
        ),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      ])
    }

    tableView.register(QChatAudioTableViewCell.self, forCellReuseIdentifier: "\(QChatAudioTableViewCell.self)")

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
      QChatTimeTableViewCell.self,
      forCellReuseIdentifier: "\(QChatTimeTableViewCell.self)"
    )
    //        IQKeyboardManager.shared.enable = false

//    NEKeyboardManager.shared.keyboardDistanceFromTextField = 60
    NEKeyboardManager.shared.enable = true
    NEKeyboardManager.shared.enableAutoToolbar = false

    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable, let networkView = weakSelf?.brokenNetworkView {
        weakSelf?.view.addSubview(networkView)
      } else {
        weakSelf?.brokenNetworkView.removeFromSuperview()
      }
    }
  }

  //    MARK: event

  func enterChannelMemberVC() {
    let memberVC = QChatChannelMembersVC()
    memberVC.channel = viewmodel?.channel
    navigationController?.pushViewController(memberVC, animated: true)
  }

  func enterServerVC() {
    navigationController?.popViewController(animated: true)
  }

  func loadData() {
    weak var weakSelf = self
    viewmodel?.getMessageHistory { error, messages in

      if let err = error {
        NELog.errorLog(ModuleName + " " + self.tag, desc: "❌getMessageHistory error, error:\(err)")
      } else {
        if let tempArray = weakSelf?.viewmodel?.messages, tempArray.count > 0 {
          weakSelf?.tableView.reloadData()
          weakSelf?.tableView.scrollToRow(
            at: IndexPath(row: tempArray.count - 1, section: 0),
            at: .bottom,
            animated: false
          )
          if let time = messages?.first?.message?.timestamp {
            weakSelf?.viewmodel?.markMessageRead(time: time)
          }
        } else {
          weakSelf?.loadMoreData(true)
        }
      }
    }
  }

    @objc func loadMoreData(_ isBottom: Bool = false) {
    weak var weakSelf = self
    viewmodel?.getMoreMessageHistory { error, messageFrames in
      NELog.infoLog(
        ModuleName + " " + self.tag,
        desc: "CALLBACK getMoreMessageHistory " + (error?.localizedDescription ?? "no error")
      )
      weakSelf?.tableView.reloadData()
      weakSelf?.tableView.mj_header?.endRefreshing()
      if isBottom == true, let count = weakSelf?.viewmodel?.messages.count, count > 0 {
        weakSelf?.tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: false)
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
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillShow(_:)),
                                           name: UIResponder.keyboardWillShowNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyBoardWillHide(_:)),
                                           name: UIResponder.keyboardWillHideNotification,
                                           object: nil)
  }

  func onUpdateChannel(noti: Notification) {
    // enter ChatVC
    guard let channel = noti.object as? ChatChannel else {
      return
    }
    viewmodel?.channel = channel
    title = viewmodel?.channel?.name
  }

  func onDeleteChannel(noti: Notification) {
    navigationController?.popToRootViewController(animated: true)
  }

  // MARK: 键盘通知相关操作

  func keyBoardWillShow(_ notification: Notification) {
    let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as!
      NSValue).cgRectValue
    layoutInputView(offset: keyboardRect.size.height)
    UIView.animate(withDuration: 0.25, animations: {
      self.view.layoutIfNeeded()
    })
    scrollTableViewToBottom()
  }

  func keyBoardWillHide(_ notification: Notification) {
    layoutInputView(offset: 0)
  }

  private func scrollTableViewToBottom() {
    if let model = viewmodel?.messages,
       model.count > 0 {
      let indexPath = IndexPath(row: model.count - 1, section: 0)
      weak var weakSelf = self
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: DispatchWorkItem(block: {
        weakSelf?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
      }))
    }
  }

  // MARK: QChatmenuViewDelegate

  public func sendText(text: String?) {
    NELog.infoLog(ModuleName + " " + tag, desc: "sendText:\(text ?? "")")
    guard let content = text, content.count > 0 else {
      return
    }
    viewmodel?.sendTextMessage(text: content) { [weak self] error in
      NELog.infoLog(
        ModuleName + " " + (self?.tag ?? "QChatViewController"),
        desc: "CALLBACK sendTextMessage " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
      } else {}
    }
  }

  public func willSelectItem(button: UIButton, index: Int) {
    if index == 0 {
      layoutInputView(offset: 204)
    } else if index == 1 {
      layoutInputView(offset: 204)
    } else if index == 2 {
      showBottomAlert(self, false)
        
    } else {
      showToast(localizable("open_soon"))
    }
  }

  private func layoutInputView(offset: CGFloat) {
    weak var weakSelf = self
    UIView.animate(withDuration: 0.1, animations: {
      weakSelf?.menuViewBottomConstraint?.constant = -100 - offset
      weakSelf?.tableViewBottomConstraint?.constant = -100 - offset
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
        ModuleName + " " + (self?.tag ?? "QChatViewController"),
        desc: "CALLBACK sendImageMessage " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
      }
    }
  }

  //    MARK: QChatViewModelDelegate

  public func onRecvMessages(_ messages: [NIMQChatMessage]) {
    viewmodel?.downloadAudioAttachment(messages)
    tableView.reloadData()
    if let messageCount = viewmodel?.messages.count, messageCount > 1 {
      tableView.scrollToRow(
        at: IndexPath(row: messageCount - 1, section: 0),
        at: .bottom,
        animated: false
      )
      if let time = viewmodel?.messages.last?.message?.timestamp {
        viewmodel?.markMessageRead(time: time)
      }
    }
  }

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        if systemNoti.type == .channelRemove,
           systemNoti.fromAccount != IMKitLoginManager.instance.currentAccount() {
          showToastInWindow(localizable("channel_deleted"))
          navigationController?.popToRootViewController(animated: true)
        }
      }
    }
  }

  public func send(_ message: NIMQChatMessage, progress: Float) {}

  public func send(_ message: NIMQChatMessage, didCompleteWithError error: Error?) {
    if let e = error as NSError? {
      if e.code == 403 {
        showAlert(message: localizable("no_permession_to_send")) {}
      }
    }
    tableView.reloadData()
    if let messageCount = viewmodel?.messages.count, messageCount > 1 {
      tableView.scrollToRow(
        at: IndexPath(row: messageCount - 1, section: 0),
        at: .bottom,
        animated: false
      )
    }
  }

  public func willSend(_ message: NIMQChatMessage) {
    tableView.reloadData()
    if let messageCount = viewmodel?.messages.count, messageCount > 1 {
      tableView.scrollToRow(
        at: IndexPath(row: messageCount - 1, section: 0),
        at: .bottom,
        animated: false
      )
    }
  }

  // MARK: UITableViewDataSource, UITableViewDelegate

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewmodel?.messages.count ?? 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let messageFrame = viewmodel?.messages[indexPath.row]
    var reuseIdentifier = "\(QChatBaseTableViewCell.self)"

    guard let msgFrame = messageFrame else {
      return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }

    if msgFrame.showTime {
      reuseIdentifier = "\(QChatTimeTableViewCell.self)"
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

    if msgFrame.showTime {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: reuseIdentifier,
        for: indexPath
      ) as! QChatTimeTableViewCell
      cell.messageFrame = messageFrame
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: reuseIdentifier,
        for: indexPath
      ) as! QChatBaseTableViewCell
      cell.messageFrame = messageFrame
      cell.delegate = self
      return cell
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    let messageFrame = viewmodel?.messages[indexPath.row]
    if indexPath.row == (viewmodel?.messages.count ?? 0) - 1 {
      return (messageFrame?.cellHeight ?? 0) + 10
    }
    return messageFrame?.cellHeight ?? 0
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
  }

  public func playAudioInterruptionBegin() {
    print(#function)
    // stop play
    playAudioCell?.stopAnimation()
  }

  //    play
  public func playAudio(_ filePath: String, didBeganWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
      // stop
      playAudioCell?.stopAnimation()
    }
  }

  public func playAudio(_ filePath: String, didCompletedWithError error: Error?) {
    print(#function + "\(error)")
    if let e = error {
      showToast(e.localizedDescription)
    }
    // stop
    playAudioCell?.stopAnimation()
  }

  //    record
  public func recordAudio(_ filePath: String?, didBeganWithError error: Error?) {
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
      viewmodel?.sendAudioMessage(path: fp) { error in
        NELog.infoLog(
          ModuleName + " " + self.tag,
          desc: "CALLBACK sendAudioMessage " + (error?.localizedDescription ?? "no error")
        )
        if let e = error {
          self.showToast(e.localizedDescription)
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

// MARK: ===============   QChatBaseCellDelegate   ================

extension QChatViewController: QChatBaseCellDelegate {
  func didSelectWithCell(cell: QChatBaseTableViewCell, type: QChatMessageClickType,
                         message: NIMQChatMessage) {
    if type == .message {
      didClickMessage(messgae: message)
      if let audioCell = cell as? QChatAudioTableViewCell? {
        playAudioCell?.stopAnimation()
        playAudioCell = audioCell
        if let object = message.messageObject as? NIMAudioObject, let path = object.path {
//            let manager = FileManager.default
//            if manager.fileExists(atPath: path) {
//                print("file path exit")
//            }else {
//                print("file path not exit")
//            }
          NIMSDK.shared().mediaManager.play(path)
          playAudioCell?.startAnimation()
        }
      }
    } else if type == .LongPressMessage {}
  }

  func didClickHeader(_ message: NIMQChatMessage) {
    if IMKitEngine.instance.isMySelf(message.from) == true {
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

  // click action
  func didClickMessage(messgae: NIMQChatMessage) {
    if messgae.messageType == .image {
      let imageObject = messgae.messageObject as! NIMImageObject
      if let path = imageObject.path, FileManager.default.fileExists(atPath: path) == true {
        let showController = PhotoBrowserController(urls: [path], url: path)
        showController.modalPresentationStyle = .overFullScreen
        present(showController, animated: false, completion: nil)
      } else if let imageUrl = imageObject.url {
        let showController = PhotoBrowserController(urls: [imageUrl], url: imageUrl)
        showController.modalPresentationStyle = .overFullScreen
        present(showController, animated: false, completion: nil)
      }

    } else if messgae.messageType == .audio {}
  }
}
