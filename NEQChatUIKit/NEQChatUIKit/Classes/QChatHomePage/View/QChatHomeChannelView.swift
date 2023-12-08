
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NECoreQChatKit
import NIMSDK
import UIKit

class QChatHomeChannelView: UIView, QChatChannelViewModelDelegate {
  typealias CallBack = (_ server: QChatServer?) -> Void
  typealias SelectedChannelBlock = (_ channel: ChatChannel?, _ isVisitor: Bool?) -> Void
  public var channelViewModel = QChatChannelViewModel()
  public var channelArray = [ChatChannel]()

  public var setUpBlock: CallBack?
  public var addChannelBlock: CallBack?
  public var selectedChannelBlock: SelectedChannelBlock?
  public var hasMore = true
  public var nextTimeTag: TimeInterval = 0

  public var viewmodel: QChatHomeViewModel?

  public var qchatServerModel: QChatServer? {
    didSet {
      hasMore = true
      nextTimeTag = 0
      self.titleLabel.text = qchatServerModel?.name
      self.titleLabel.isHidden = false
      self.divideLineView.isHidden = false
      self.subTitleLabel.isHidden = false
      requestData(timeTag: 0)
      print("set up btn : ", setUpBtn)
      refreshVisitorUI()
      // 先隐藏掉添加创建话题按钮，查询完权限之后根据权限有无决定是否显示添加话题按钮
      addChannelBtn.isHidden = true
      checkManagerChannelPermission()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    channelViewModel.delegate = self
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ rect: CGRect) {
    addCorner(conrners: [.topLeft, .topRight], radius: 8)
  }

  func setupSubviews() {
    backgroundColor = .white

    addSubview(titleLabel)
    addSubview(setUpBtn)
    addSubview(divideLineView)
    addSubview(addChannelBtn)
    addSubview(subTitleLabel)
    addSubview(tableView)
    addSubview(emptyView)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
      titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -35),

    ])

    NSLayoutConstraint.activate([
      setUpBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      setUpBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      divideLineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
      divideLineView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
      divideLineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
      divideLineView.heightAnchor.constraint(equalToConstant: 1),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.topAnchor.constraint(equalTo: divideLineView.bottomAnchor, constant: 16),
      subTitleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 18),
    ])

    NSLayoutConstraint.activate([
      addChannelBtn.centerYAnchor.constraint(equalTo: subTitleLabel.centerYAnchor),
      addChannelBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
    ])

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 8),
      tableView.leftAnchor.constraint(equalTo: leftAnchor),
      tableView.rightAnchor.constraint(equalTo: rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      emptyView.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 8),
      emptyView.leftAnchor.constraint(equalTo: leftAnchor),
      emptyView.rightAnchor.constraint(equalTo: rightAnchor),
      emptyView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @objc func updateChannelList() {
    requestData(timeTag: 0)
  }

  public func channelChange(noticeInfo: NIMQChatSystemNotification) {
    switch noticeInfo.type {
    case .channelRemove, .channelCreate, .channelUpdate:
      if noticeInfo.serverId == qchatServerModel?.serverId {
        requestData(timeTag: 0)
      }
    case .updateChannelCategoryBlackWhiteRole:
      if noticeInfo.serverId == qchatServerModel?.serverId,
         (noticeInfo.toAccids?.contains(QChatKitClient.instance.imAccid())) != nil {
        requestData(timeTag: 0)
      }

    default:
      print("")
    }
  }

  // MARK: lazy method

  private lazy var titleLabel: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.textColor = UIColor.ne_darkText
    title.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
    return title
  }()

  private lazy var setUpBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "home_setupServer"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "home_setupServer"), for: .highlighted)
    button.addTarget(self, action: #selector(setupBtnClick), for: .touchUpInside)
    return button
  }()

  private lazy var divideLineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()

  private lazy var subTitleLabel: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = localizable("message_channel")
    title.textColor = PlaceholderTextColor
    title.font = DefaultTextFont(14)
    return title
  }()

  private lazy var addChannelBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage.ne_imageNamed(name: "home_addChannel"), for: .normal)
    button.setImage(UIImage.ne_imageNamed(name: "home_addChannel"), for: .highlighted)
    button.addTarget(self, action: #selector(addChannelBtnClick), for: .touchUpInside)
    return button
  }()

  lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatHomeChannelCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(QChatHomeChannelCell.self))"
    )
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    let mjfooter = MJRefreshBackNormalFooter(
      refreshingTarget: self,
      refreshingAction: #selector(loadMoreData)
    )
    mjfooter.stateLabel?.isHidden = true
    tableView.mj_footer = mjfooter
    return tableView
  }()

  private lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      image: UIImage.ne_imageNamed(name: "channel_noMoreData"),
      content: localizable("server_nochannel"),
      frame: tableView.bounds
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  func didNeedRefreshData() {
    tableView.reloadData()
  }

  public func refreshVisitorUI() {
    if qchatServerModel?.isVisitorMode == true {
      setUpBtn.isHidden = true
    } else {
      setUpBtn.isHidden = false
    }
  }

  func didCheckPermission() {
    checkManagerChannelPermission()
  }
}

extension QChatHomeChannelView {
  @objc func setupBtnClick(sender: UIButton) {
    if setUpBlock != nil {
      setUpBlock!(qchatServerModel)
    }
  }

  @objc func addChannelBtnClick(sender: UIButton) {
    if addChannelBlock != nil {
      addChannelBlock!(qchatServerModel)
    }
  }

  @objc func loadMoreData() {
    requestData(timeTag: nextTimeTag)
    tableView.mj_footer?.endRefreshing()
  }

  func didReRequestData() {
    requestData(timeTag: 0)
  }

  public func requestData(timeTag: TimeInterval) {
    if timeTag != 0, !hasMore {
      // 上拉加载无多余数据，无需请求
      return
    }

    guard let serverId = qchatServerModel?.serverId else { return }
    channelViewModel.getChannelsByPage(serverId, timeTag) { [self] error, result in
      if error == nil {
        NELog.infoLog(className(), desc: "✅CALLBACK getChannelsByPage SUCCESS")
        var dataArray = [ChatChannel]()
        if let retArray = result?.channels {
          dataArray.append(contentsOf: retArray)
        }
        if timeTag == 0 {
          channelArray.removeAll()
          channelArray = dataArray
          if dataArray.isEmpty {
            emptyView.settingContent(content: localizable("server_nochannel"))
            emptyView.setEmptyImage(image: UIImage.ne_imageNamed(name: "channel_noMoreData"))
            emptyView.isHidden = false
          } else {
            emptyView.isHidden = true
          }

        } else {
          channelArray += dataArray
        }

        tableView.reloadData()
        if nextTimeTag != 0,
           channelArray.count > 0 {
          tableView.scrollToRow(at: IndexPath(row: channelArray.count - 1, section: 0), at: .bottom, animated: true)
        } else {
          tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        hasMore = result?.hasMore ?? false
        if let nextValue = result?.nextTimetag, nextValue > 0 {
          nextTimeTag = result?.nextTimetag ?? 0
        }
      } else {
        NELog.errorLog(className(), desc: "❌CALLBACK getChannelsByPage failed,error = \(error!)")
      }
    }
  }

  public func showEmptyServerView() {
    channelArray.removeAll()
    tableView.reloadData()
    titleLabel.isHidden = true
    setUpBtn.isHidden = true
    divideLineView.isHidden = true
    subTitleLabel.isHidden = true
    addChannelBtn.isHidden = true
    emptyView.isHidden = false
    emptyView.settingContent(content: localizable("add_favorite_service"))
    emptyView.setEmptyImage(image: UIImage.ne_imageNamed(name: "servers_noMore"))
  }

  public func dismissEmptyView() {
    titleLabel.isHidden = false
    if qchatServerModel?.isVisitorMode == false {
      setUpBtn.isHidden = false
      addChannelBtn.isHidden = false
    }
    divideLineView.isHidden = false
    subTitleLabel.isHidden = false
    emptyView.isHidden = true
  }
}

extension QChatHomeChannelView: UITableViewDataSource, UITableViewDelegate {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    channelArray.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(QChatHomeChannelCell.self))",
      for: indexPath
    ) as! QChatHomeChannelCell
    if indexPath.row < channelArray.count {
      let channel = channelArray[indexPath.row]
      cell.channelModel = channel
      if let sid = qchatServerModel?.serverId, let cid = channel.channelId,
         let unreadCount = viewmodel?.getChannelUnreadCount(sid, cid) {
        cell.redAngleView.isHidden = false
        if unreadCount <= 0 {
          cell.redAngleView.isHidden = true
        } else if unreadCount <= 99 {
          cell.redAngleView.text = "\(unreadCount)"
        } else {
          cell.redAngleView.text = "99+"
        }
      } else {
        cell.redAngleView.isHidden = true
      }
    }

    if let cid = channelArray[indexPath.row].channelId,
       let lastMsg = channelViewModel.lastMsgDic[cid], let name = lastMsg.message.senderName {
      if lastMsg.isRevoked == true {
        cell.setLastMessage(name + ":" + localizable("message_has_be_withdrawn"))
      } else {
        cell.setLastMessage(name + ":" + QChatUtil.getLastMsgContent(lastMsg.message))
      }
    } else {
      cell.setLastMessage(nil)
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if let block = selectedChannelBlock, channelArray.count > 0 {
      block(channelArray[indexPath.row], qchatServerModel?.isVisitorMode)
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    NELog.infoLog(className() + " heightForRowAt ", desc: "index row : \(indexPath.row) index section : \(indexPath.section)")
    if let cid = channelArray[indexPath.row].channelId, channelViewModel.lastMsgDic[cid] != nil {
      return 52.0
    }
    return 36
  }

  public func checkManagerChannelPermission() {
    if let sid = qchatServerModel?.serverId {
      weak var weakSelf = self
      channelViewModel.checkManageChannelPermission(severId: sid, channelId: 0) { error, enable in
        if error == nil {
          if let currentSid = weakSelf?.qchatServerModel?.serverId, currentSid == sid {
            weakSelf?.addChannelBtn.isHidden = !enable
          }
        }
      }
    }
  }
}
