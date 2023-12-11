
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import MJRefresh
import NECommonKit
import NECommonUIKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

@objc
@objcMembers
open class QChatHomeViewController: UIViewController, ViewModelDelegate {
  public var serverViewModel = QChatHomeViewModel()
  public var serverListArray = [QChatServer]()
//  fileprivate var selectIndex = 0
  private let className = "QChatHomeViewController"

  private var serverID: UInt64 = 0

  public var visitorServer: QChatServer? {
    didSet {}
  }

  public var recordServer: QChatServer? // 记录断网时候点击的cell

  public var noticeServerSet = Set<UInt64>()

  public var delegate: QChatServerDelegate? {
    didSet {
      serverViewModel.serverDelgate = delegate
    }
  }

  public var serverContentView: UIView = {
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = .clear
    return content
  }()

  // 游客banner view
  public var visitorBannerView: QChatVisitorBannerView = {
    let view = QChatVisitorBannerView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = true
    if serverID > 0 {
      createDefaultChannel(serverId: serverID)
      serverID = 0
    }
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.isHidden = false
  }

  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    weak var weakSelf = self
    NEChatDetectNetworkTool.shareInstance.netWorkReachability { status in
      if status == .notReachable, let networkView = weakSelf?.brokenNetworkView {
        weakSelf?.qChatBgView.addSubview(networkView)
      } else {
        if let record = weakSelf?.recordServer {
          DispatchQueue.main.async {
            weakSelf?.qChatBgView.qchatServerModel = record
            weakSelf?.recordServer = nil
          }
        }
        weakSelf?.brokenNetworkView.removeFromSuperview()
      }
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    edgesForExtendedLayout = .bottom
    serverViewModel.delegate = self
    qChatBgView.viewmodel = serverViewModel
    weak var weakSelf = self
    serverViewModel.updateServerList = {
      weakSelf?.tableView.reloadData()
    }

    serverViewModel.clearVisitorCache()
    initializeConfig()
    addSubviews()
    requestData(timeTag: 0)
    addObserve()
  }

  public func setCurrentServer(server: QChatServer) {
    weak var weakSelf = self

    serverViewModel.checkJoinServer(server: server) { error, isJoined in
      if let err = error {
        weakSelf?.showToast(err.localizedDescription)
      } else {
        if isJoined {
          weakSelf?.qChatBgView.qchatServerModel = server
          weakSelf?.serverViewModel.currentServerId = server.serverId
          weakSelf?.visitorBannerView.isHidden = true
          weakSelf?.tableView.reloadData()
        } else {
          if weakSelf?.serverID != nil {
            weakSelf?.serverViewModel.clearVisitorCache()
          }
          if let sid = server.serverId {
            weakSelf?.serverViewModel.enterAsVisitor(sid) { error in
              if error == nil {
                server.isVisitorMode = true
                weakSelf?.serverViewModel.visitorServerCache.append(sid)
                if let cache = weakSelf?.serverViewModel.visitorServerCache {
                  weakSelf?.serverViewModel.writeVisitorCacheFile(cache)
                }
                weakSelf?.qChatBgView.qchatServerModel = server
                if let visitorSid = weakSelf?.visitorServer?.serverId, let sid = weakSelf?.serverListArray.first?.serverId, visitorSid == sid {
                  weakSelf?.serverListArray.remove(at: 0)
                }
                weakSelf?.serverListArray.insert(server, at: 0)
                weakSelf?.serverViewModel.currentServerId = sid
                weakSelf?.visitorServer = server
                weakSelf?.tableView.reloadData()
                weakSelf?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                weakSelf?.visitorBannerView.isHidden = false
              }
            }
          }
        }
      }
    }
  }

  func initializeConfig() {
    QChatSystemMessageProvider.shared.addDelegate(delegate: self)
  }

  func addSubviews() {
    view.backgroundColor = .ne_lightBackgroundColor
    view.addSubview(addServiceBtn)
    view.addSubview(qChatBgView)
    view.addSubview(serverContentView)

    serverContentView.addSubview(tableView)

    view.addSubview(visitorBannerView)

    NSLayoutConstraint.activate([
      addServiceBtn.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
      addServiceBtn.widthAnchor.constraint(equalToConstant: 42),
      addServiceBtn.heightAnchor.constraint(equalToConstant: 42),
      addServiceBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 46),
    ])
    NSLayoutConstraint.activate([
      qChatBgView.leftAnchor.constraint(equalTo: addServiceBtn.rightAnchor, constant: 12),
      qChatBgView.topAnchor.constraint(equalTo: addServiceBtn.topAnchor),
      qChatBgView.rightAnchor.constraint(equalTo: view.rightAnchor),
      qChatBgView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      serverContentView.topAnchor.constraint(equalTo: addServiceBtn.bottomAnchor, constant: 7),
      serverContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      serverContentView.rightAnchor.constraint(equalTo: qChatBgView.leftAnchor),
      serverContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: serverContentView.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: serverContentView.rightAnchor),
      tableView.topAnchor.constraint(equalTo: serverContentView.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: serverContentView.bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      visitorBannerView.leftAnchor.constraint(equalTo: view.leftAnchor),
      visitorBannerView.rightAnchor.constraint(equalTo: view.rightAnchor),
      visitorBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      visitorBannerView.heightAnchor.constraint(equalToConstant: 50),
    ])
    visitorBannerView.joinButton.addTarget(self, action: #selector(visitorJoinServer(_:)), for: .touchUpInside)
  }

  func requestData(timeTag: TimeInterval, _ currentSid: UInt64? = nil) {
    let param = GetServersByPageParam(timeTag: timeTag, limit: 50)
    weak var weakSelf = self
    serverViewModel.getServerList(parameter: param) { error, servers in
      NELog.infoLog(
        ModuleName + " " + self.className,
        desc: "CALLBACK getServerList " + (error?.localizedDescription ?? "no error")
      )
      if error == nil {
        guard let dataArray = servers else { return }
        if timeTag == 0 {
          if currentSid != nil {
            weakSelf?.serverViewModel.currentServerId = nil
          }
          self.serverListArray.removeAll()
          self.serverListArray = dataArray
          if let visitor = weakSelf?.visitorServer {
            weakSelf?.serverListArray.insert(visitor, at: 0)
          }
          if let first = weakSelf?.serverViewModel.findFirstNormalServer(self.serverListArray) {
            if weakSelf?.serverViewModel.currentServerId == nil {
              self.qChatBgView.qchatServerModel = first
              weakSelf?.serverViewModel.currentServerId = first.serverId
            }
            self.qChatBgView.dismissEmptyView()
          } else {
            // 社区列表为空
            self.qChatBgView.showEmptyServerView()
          }
        } else {
          self.serverListArray += dataArray
          if self.serverViewModel.currentServerId == nil {
            if let first = weakSelf?.serverViewModel.findFirstNormalServer(self.serverListArray) {
              self.qChatBgView.qchatServerModel = first
              weakSelf?.serverViewModel.currentServerId = first.serverId
            }
          }
        }

        // 未读数入口
        weakSelf?.serverViewModel.getUnread(dataArray)

        self.tableView.reloadData()

      } else {
        print("getServerList failed,error = \(error!)")
      }
    }
  }

  func addObserve() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onCreateServer),
      name: NotificationName.createServer,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onCreateChannel),
      name: NotificationName.createChannel,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onCreateAnnouncement),
      name: NotificationName.createAnnouncement,
      object: nil
    )
  }

  // MARK: lazy method

  private lazy var addServiceBtn: UIButton = {
    let btn = UIButton()
    btn.setBackgroundImage(UIImage.ne_imageNamed(name: "addService_icon"), for: .normal)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.addTarget(self, action: #selector(addServiceBtnClick), for: .touchUpInside)
    return btn
  }()

  private lazy var qChatBgView: QChatHomeChannelView = {
    let view = QChatHomeChannelView()
    view.translatesAutoresizingMaskIntoConstraints = false
    weak var weakSelf = self
    view.viewmodel = serverViewModel
    view.setUpBlock = { server in
      let setting = QChatServerSettingViewController(server: server)
      setting.hidesBottomBarWhenPushed = true
      weakSelf?.navigationController?.pushViewController(setting, animated: true)
    }

    view.addChannelBlock = { server in
      guard let serverId = server?.serverId, serverId > 0 else {
        print("error: serverId:\(server?.serverId ?? 0)")
        return
      }
      let nav =
        QChatNavigationController(
          rootViewController: QChatChannelViewController(serverId: serverId)
        )
      nav.modalPresentationStyle = .fullScreen
      weakSelf?.present(nav, animated: true, completion: nil)
    }

    view.selectedChannelBlock = { [weak self] channel, isVisitorMode in
      weakSelf?.enterChatVC(channel: channel, isVisitorMode ?? false)
    }
    return view
  }()

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatHomeServerCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(QChatHomeServerCell.self))"
    )
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    tableView.backgroundColor = .clear
    let mjfooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjfooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjfooter
    return tableView
  }()

  private lazy var brokenNetworkView: NEBrokenNetworkView = {
    let view =
      NEBrokenNetworkView(frame: CGRect(x: 0, y: 38, width: qChatBgView.width, height: 33))
    return view
  }()
}

extension QChatHomeViewController {
  @objc func addServiceBtnClick(sender: UIButton) {
    let create = QChatCreateServerViewController()
    create.rootController = self
    let nav = UINavigationController(rootViewController: create)
    nav.modalPresentationStyle = .fullScreen
    present(nav, animated: true, completion: nil)
  }

  @objc func loadMoreData() {
    if let time = serverListArray.last?.createTime {
      requestData(timeTag: time)
    }
    tableView.mj_footer?.endRefreshing()
  }
}

// MARK: tableviewDelegate dataSource

extension QChatHomeViewController: UITableViewDelegate, UITableViewDataSource {
  public func dataDidChange() {
    qChatBgView.tableView.reloadData()
  }

  public func dataDidError(_ error: Error) {}

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    serverListArray.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(QChatHomeServerCell.self))",
      for: indexPath
    ) as! QChatHomeServerCell

    let model = serverListArray[indexPath.row]
    if let sid = model.serverId {
      let count = ObserverUnreadInfoResultHelper.shared.getUnreadCountForServer(serverId: sid)
      model.unreadCount = count

      if let currentSid = serverViewModel.currentServerId, currentSid == sid {
        cell.showSelectState(isShow: true)
      } else {
        cell.showSelectState(isShow: false)
      }
    }
    cell.serverModel = model

    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let serverModel = serverListArray[indexPath.row]

    if serverModel.announce != nil {
      // 公告频道
      let chatVC = QChatViewController(channel: nil, server: serverModel)
      chatVC.isVisitorMode = false
      navigationController?.pushViewController(chatVC, animated: true)
      recordServer = nil
      return
    }
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      recordServer = serverModel
    }
    qChatBgView.qchatServerModel = serverModel
    serverViewModel.currentServerId = serverModel.serverId
    visitorBannerView.isHidden = !serverModel.isVisitorMode
    tableView.reloadData()
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    50
  }

//    MARK: action

  @objc func onCreateServer(noti: Notification) {
    guard let serverId: UInt64 = noti.object as? UInt64 else {
      return
    }
    serverID = serverId
  }

  func createDefaultChannel(serverId: UInt64) {
    NELog.infoLog(ModuleName + " " + className, desc: "noti create server id:\(serverId), controller: \(self)")

    weak var weakSelf = self
    let viewModel = QChatChannelViewModel(serverId: serverId)
    viewModel.name = localizable("second_channel")
    let className = className()
    viewModel.createChannel { error, channel in
      if let err = error {
        NELog.errorLog(
          ModuleName + " " + className,
          desc: "createChannel second_channel failed，error = \(err)"
        )
      } else {
        NELog.infoLog(ModuleName + " " + className, desc: "✅CALLBACK second_channel create success, serverId: \(serverId)")
        viewModel.name = localizable("first_channel")

        viewModel.createChannel { error, channel in
          if let err = error {
            NELog.errorLog(
              ModuleName + " " + className,
              desc: "createChannel first_channel failed，error = \(err)"
            )
          } else {
            NELog.infoLog(ModuleName + " " + className, desc: "✅CALLBACK first_channel create success, serverId: \(serverId)")
            weakSelf?.enterChatVC(channel: channel)
          }
        }
      }
    }
  }

  @objc func onCreateAnnouncement(noti: NSNotification) {
    guard let server = noti.object as? QChatServer else {
      return
    }
    let chatVC = QChatViewController(channel: nil, server: server)
    navigationController?.pushViewController(chatVC, animated: true)
  }

  @objc func onCreateChannel(noti: Notification) {
    // enter ChatVC
    guard let channel = noti.object as? ChatChannel else {
      return
    }
    enterChatVC(channel: channel)
  }

  private func enterChatVC(channel: ChatChannel?, _ isVisitorMode: Bool = false) {
    NELog.infoLog(ModuleName + " " + className(), desc: "[enterChatVC], navigationController:\(String(describing: navigationController))")

    let chatVC = QChatViewController(channel: channel)
    chatVC.isVisitorMode = isVisitorMode
    navigationController?.pushViewController(chatVC, animated: true)
  }

  func filterVisitorNoti(noti: NIMQChatSystemNotification) {
    guard let server = visitorServer, let sid = server.serverId else {
      return
    }
    if noti.type == .serverMemberLeave || noti.type == .serverMemberInviteDone || noti.type == .serverMemberApplyDone, sid == noti.serverId {
      serverViewModel.deleteVisitorCache()
      visitorServer?.isVisitorMode = false
//      qChatBgView.refreshVisitorUI()

      visitorServer = nil
      serverViewModel.channelDataDic.removeValue(forKey: noti.serverId)
      visitorBannerView.isHidden = true
    }
  }

  @objc open func visitorJoinServer(_ sender: UIButton) {
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      showToast(commonLocalizable("network_error"))
      return
    }
    guard let sid = visitorServer?.serverId else {
      return
    }
    sender.isEnabled = false
    let param = QChatApplyServerJoinParam(serverId: sid)
    serverViewModel.applyServerJoin(parameter: param) { [weak self] error in
      sender.isEnabled = true
      self?.visitorServer = nil
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

extension QChatHomeViewController: NIMQChatMessageManagerDelegate {
  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    let imAccid = QChatKitClient.instance.imAccid()
    result.systemNotifications?.forEach { systemNotification in
      filterVisitorNoti(noti: systemNotification)
      switch systemNotification.type {
      case .channelCreate, .channelRemove, .updateChannelCategoryBlackWhiteRole,
           .channelUpdate:
        self.channelChange(notificationInfo: systemNotification)
      case .serverMemberKick, .serverMemberInviteDone:
        if systemNotification.fromAccount != imAccid,
           (systemNotification.toAccids?.contains(imAccid)) !=
           nil {
          if systemNotification.type == .serverMemberKick {
            dealServerData(systemNotification: systemNotification)
          }
          self.requestData(timeTag: 0)
        }
      case .serverMemberApplyDone, .serverCreate, .serverRemove, .serverMemberLeave:

        if systemNotification.type == .serverRemove {
          dealServerData(systemNotification: systemNotification)
          self.requestData(timeTag: 0)
        } else {
          if systemNotification.fromAccount == imAccid {
            if systemNotification.type == .serverMemberLeave {
              dealServerData(systemNotification: systemNotification)
              self.requestData(timeTag: 0)
            } else if systemNotification.type == .serverCreate {
              guard let attach = systemNotification.attach as? NIMQChatUpdateServerAttachment, let imServer = attach.server else {
                return
              }

              let server = QChatServer(server: imServer)

              if server.announce == nil {
                requestData(timeTag: 0, systemNotification.serverId)
              } else {
                if let sid = server.serverId {
                  noticeServerSet.insert(sid)
                }
              }
            } else {
              var sid: UInt64?
              if systemNotification.type == .serverMemberApplyDone {
                sid = systemNotification.serverId
              }
              self.requestData(timeTag: 0, sid)
            }
          }
        }

      case .serverUpdate:

        guard let attach = systemNotification.attach as? NIMQChatUpdateServerAttachment, let imServer = attach.server else {
          return
        }

        let server = QChatServer(server: imServer)

        if systemNotification.fromAccount == QChatKitClient.instance.imAccid() {
          print("update server from self")
          if server.announce != nil {
            print("update get server : ", server)
            if let sid = server.serverId, noticeServerSet.contains(sid) == true {
              if serverListArray.count > 0 {
                serverListArray.insert(server, at: 0)
              } else {
                serverListArray.append(server)
              }
              noticeServerSet.remove(sid)
              tableView.reloadData()
            } else {
              reloadUpdateCell(targetServerId: systemNotification.serverId)
            }
          } else {
            reloadUpdateCell(targetServerId: systemNotification.serverId)
          }
        } else {
          reloadUpdateCell(targetServerId: systemNotification.serverId)
        }
      default:
        print("systemNotification.type not case")
      }
    }
  }

  func dealServerData(systemNotification: NIMQChatSystemNotification) {
    serverViewModel.channelDataDic.removeValue(forKey: systemNotification.serverId)
    if serverViewModel.currentServerId == systemNotification.serverId {
      if let findServer = findNextFocusServer(systemNotification.serverId) {
        serverViewModel.currentServerId = findServer.serverId
        qChatBgView.qchatServerModel = findServer
      } else {
        serverViewModel.currentServerId = nil
      }
    }
    let unreadCount = ObserverUnreadInfoResultHelper.shared.getUnreadCountForServer(serverId: systemNotification.serverId)
    if unreadCount > 0 {
      ObserverUnreadInfoResultHelper.shared.clearUnreadCountForServer(serverId: systemNotification.serverId)
      serverViewModel.serverDelgate?.serverUnReadTotalCountChange?(count: ObserverUnreadInfoResultHelper.shared.getTotalUnreadCountForServer())
    }
  }

  private func reloadUpdateCell(targetServerId: UInt64) {
    let param = QChatGetServersParam(serverIds: [NSNumber(value: targetServerId)])
    weak var weakSelf = self
    serverViewModel.getServers(parameter: param) { error, result in
      NELog.infoLog(
        ModuleName + " " + self.className,
        desc: "CALLBACK getServers " + (error?.localizedDescription ?? "no error")
      )
      if let server = result?.servers.first, let dataServer = weakSelf?.serverViewModel.dataDic[targetServerId] {
        dataServer.copyFromModel(server: server)
        weakSelf?.tableView.reloadData()
        if weakSelf?.serverViewModel.currentServerId == server.serverId {
          weakSelf?.qChatBgView.qchatServerModel = server
        }
      }
    }
  }

  private func indexOfServer(_ sid: UInt64?) -> Int {
    // 遍历 data array
    for (index, server) in serverListArray.enumerated() {
      if server.serverId == sid {
        return index
      }
    }
    return -1
  }

  private func findNextFocusServer(_ sid: UInt64) -> QChatServer? {
    var findServer: QChatServer?
    let index = indexOfServer(sid)
    if index != 0, serverListArray.count > index - 1 {
      var currentIndex = index - 1
      while currentIndex > 0 {
        let server = serverListArray[currentIndex]
        if server.isVisitorMode == false, server.announce == nil {
          findServer = server
          break
        }
        currentIndex -= 1
      }
    } else if serverListArray.count > index + 1 {
      var currentIndex = index + 1
      while currentIndex < serverListArray.count {
        let server = serverListArray[currentIndex]
        if server.isVisitorMode == false, server.announce == nil {
          findServer = server
          break
        }
        currentIndex += 1
      }
    }
    return findServer
  }

  private func channelChange(notificationInfo: NIMQChatSystemNotification) {
    qChatBgView.channelChange(noticeInfo: notificationInfo)
  }
}
