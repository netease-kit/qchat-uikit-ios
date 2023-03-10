
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatKit
import NECoreIMKit
public typealias DidSelectedAtRow = (_ index: Int, _ model: ChatTeamMemberInfoModel?) -> Void

@objcMembers
public class SelectUserViewController: ChatBaseViewController, UITableViewDelegate,
  UITableViewDataSource {
  public var tableView = UITableView(frame: .zero, style: .plain)
  public var sessionId: String
  public var viewModel = TeamMemberSelectVM()
  public var selectedBlock: DidSelectedAtRow?
  var teamInfo: ChatTeamInfoModel?
  private var showSelf = true // 是否展示自己
  private let className = "SelectUserViewController"

  init(sessionId: String, showSelf: Bool = true) {
    self.sessionId = sessionId
    self.showSelf = showSelf
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData()
  }

  func commonUI() {
    let btn = UIButton(type: .custom)
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setImage(UIImage.ne_imageNamed(name: "arrowDown"), for: .normal)
    btn.addTarget(self, action: #selector(btnEvent), for: .touchUpInside)
    view.addSubview(btn)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        btn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
        btn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        btn.widthAnchor.constraint(equalToConstant: 50),
        btn.heightAnchor.constraint(equalToConstant: 50),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        btn.topAnchor.constraint(equalTo: view.topAnchor),
        btn.widthAnchor.constraint(equalToConstant: 50),
        btn.heightAnchor.constraint(equalToConstant: 50),
      ])
    }

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("user_select")
    label.font = UIFont.systemFont(ofSize: 16)
    label.textAlignment = .center
    label.textColor = UIColor.darkGray
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.topAnchor.constraint(equalTo: view.topAnchor),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
      label.heightAnchor.constraint(equalToConstant: 50),
    ])

    tableView.delegate = self
    tableView.dataSource = self
    tableView.sectionHeaderHeight = 0
    tableView.sectionFooterHeight = 0
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(
      ChatTeamMemberCell.self,
      forCellReuseIdentifier: "\(ChatTeamMemberCell.self)"
    )
    tableView.separatorStyle = .none
    tableView.rowHeight = 62
    tableView.tableFooterView = UIView()
    view.addSubview(tableView)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        tableView.topAnchor.constraint(equalTo: label.bottomAnchor),
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        tableView.bottomAnchor
          .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }
  }

  func loadData() {
    viewModel.fetchTeamMembers(sessionId: sessionId) { [weak self] error, team in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "SelectUserViewController"),
        desc: "CALLBACK fetchTeamMembers " + (error?.localizedDescription ?? "no error")
      )
      if error != nil {
        self?.view.makeToast(error?.localizedDescription)
        return
      }

      // 人员选择页面移除自己
      if !(self?.showSelf ?? true),
         let users = team?.users {
        for (index, user) in users.enumerated() {
          if user.nimUser?.userId == IMKitLoginManager.instance.currentAccount() {
            team?.users.remove(at: index)
          }
        }
      }
      self?.teamInfo = team
      self?.tableView.reloadData()
    }
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let count = teamInfo?.users.count {
      return count + 1
    }
    return 0
  }

  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(ChatTeamMemberCell.self)",
      for: indexPath
    ) as! ChatTeamMemberCell
    if indexPath.row == 0 {
      cell.headerView.image = UIImage.ne_imageNamed(name: "chat_team")
      cell.nameLabel.text = chatLocalizable("user_select_all")
    } else {
      if let model = teamInfo?.users[indexPath.row - 1] {
        cell.configure(model)
      }
    }
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      if let block = selectedBlock {
        block(indexPath.row, nil)
      }
      dismiss(animated: true, completion: nil)
      return
    }
    if let block = selectedBlock {
      block(indexPath.row, teamInfo?.users[indexPath.row - 1])
    }
    dismiss(animated: true, completion: nil)
  }

  func btnEvent(button: UIButton) {
    dismiss(animated: true, completion: nil)
  }
}
