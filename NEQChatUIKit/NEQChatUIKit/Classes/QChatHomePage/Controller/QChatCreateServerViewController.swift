
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

public class QChatCreateServerViewController: NEBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public weak var rootController: UIViewController?
  public var serverViewModel = QChatCreateServerViewModel()

  override public func viewDidLoad() {
    super.viewDidLoad()
    initializeConfig()
    setupSubviews()
  }

  func initializeConfig() {
    title = localizable("qchat_add_Server")
    addLeftAction(localizable("close"), #selector(closeAction), self)
    navigationView.setBackButtonTitle(localizable("close"))
    navigationView.addBackButtonTarget(target: self, selector: #selector(closeAction))
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false

    addLeftSwipeDismissGesture()
  }

  func setupSubviews() {
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: KStatusBarHeight + CGFloat(kNavigationHeight) + 30
      ),
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      QChatCreateServerCell.self,
      forCellReuseIdentifier: "\(NSStringFromClass(QChatCreateServerCell.self))"
    )
    tableView.rowHeight = 60
    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
    return tableView
  }()

  @objc func closeAction(sender: UIButton) {
    navigationController?.dismiss(animated: true, completion: nil)
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    serverViewModel.dataArray.count
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(NSStringFromClass(QChatCreateServerCell.self))",
      for: indexPath
    ) as! QChatCreateServerCell
    let model = serverViewModel.dataArray[indexPath.row]
    cell.model = model
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      let mineCreateCtrl = QChatMineCreateServerController()
      navigationController?.pushViewController(mineCreateCtrl, animated: true)
    } else if indexPath.row == 1 {
      let otherCtrl = QChatJoinOtherServiceController()
      otherCtrl.rootController = rootController
      navigationController?.pushViewController(otherCtrl, animated: true)
    } else if indexPath.row == 2 {
      let createPublicServer = QChatMineCreateServerController()
      createPublicServer.isAnnouncement = true
      navigationController?.pushViewController(createPublicServer, animated: true)
    } else if indexPath.row == 3 {
      let joinPublicServer = QChatJoinOtherServiceController()
      joinPublicServer.rootController = rootController
      joinPublicServer.isAnnouncement = true
      navigationController?.pushViewController(joinPublicServer, animated: true)
    }
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    76
  }
}
