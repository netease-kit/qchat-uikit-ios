
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

typealias UpdateChannelSuccess = (_ channel: ChatChannel?) -> Void

public class QChatChannelSettingVC: QChatTableViewController, QChatTextEditCellDelegate {
  var viewModel: QChatUpdateChannelViewModel?
  var didUpdateChannel: UpdateChannelSuccess?
  var didDeleteChannel: UpdateChannelSuccess?

  var sections: [String]?
  var cells = [String]()
  private let className = "QChatChannelSettingVC"

  override public func viewDidLoad() {
    super.viewDidLoad()
    loadData()
    commonUI()
  }

  func loadData() {
    sections = [
      localizable("channel_name"),
      localizable("channel_topic"),
      localizable("authority"),
      localizable("list"),
      "",
    ]

    let listName = viewModel?.channel?
      .visibleType == .isPublic ? localizable("black_list") : localizable("white_list")

    cells = [
      viewModel?.channel?.name ?? "",
      viewModel?.channel?.topic ?? "",
      localizable("authority_setting"),
      listName,
      localizable("delete_channel"),
    ]
  }

  func commonUI() {
    title = localizable("channel_setting")
    view.backgroundColor = .ne_lightBackgroundColor
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: localizable("save"),
      style: .plain,
      target: self,
      action: #selector(save)
    )
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: localizable("close"),
      style: .plain,
      target: self,
      action: #selector(close)
    )
    navigationItem.rightBarButtonItem?.tintColor = .ne_blueText

    navigationView.setBackButtonTitle(localizable("close"))
    navigationView.addBackButtonTarget(target: self, selector: #selector(close))
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(save))
    navigationView.backgroundColor = .ne_lightBackgroundColor

    addLeftSwipeDismissGesture()

    tableView.rowHeight = 50
    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatCenterTextCell.self,
      forCellReuseIdentifier: "\(QChatCenterTextCell.self)"
    )
    tableView.register(
      QChatSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)"
    )
  }

//    MARK: deletgate

  func numberOfSections(in tableView: UITableView) -> Int {
    sections?.count ?? 0
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    1
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch indexPath.section {
    case 0:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
        .union(CornerType.bottomLeft).union(CornerType.bottomRight)
      cell.textFied.text = cells[indexPath.section]
      cell.textFied.tag = 20
      cell.limit = 50
      cell.delegate = self
      return cell
    case 1:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
        .union(CornerType.bottomLeft).union(CornerType.bottomRight)
      cell.textFied.text = cells[indexPath.section]
      cell.textFied.tag = 21
      cell.limit = 64
      cell.delegate = self
      return cell
    case 2, 3:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextArrowCell.self)",
        for: indexPath
      ) as! QChatTextArrowCell
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
        .union(CornerType.bottomLeft).union(CornerType.bottomRight)
      cell.dividerLine.isHidden = true
      cell.titleLabel.text = cells[indexPath.section]
      return cell
    case 4:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatCenterTextCell.self)",
        for: indexPath
      ) as! QChatCenterTextCell
      cell.cornerType = CornerType.topLeft.union(CornerType.topRight)
        .union(CornerType.bottomLeft).union(CornerType.bottomRight)
      cell.titleLabel.text = cells[indexPath.section]
      cell.line.isHidden = true
      return cell
    default:
      return UITableViewCell()
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let head = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as! QChatSectionView
    head.titleLabel.text = sections?[section]
    return head
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 2:
      // authority
      enterAuthoritySettingVC()
    case 3:
      // name list
      enterListVC()
    case 4:
//            delete
      deleteChannel()
    default:
      break
    }
  }

//    MARK: private method

  private func enterAuthoritySettingVC() {
    navigationController?.pushViewController(
      QChatChannelAuthoritySettingVC(channel: viewModel?.channel),
      animated: true
    )
  }

  private func enterListVC() {
    let listVC = QChatWhiteBlackListVC()
    listVC.channel = viewModel?.channel
    listVC.type = viewModel?.channel?.visibleType == .isPublic ? .black : .white
    navigationController?.pushViewController(listVC, animated: true)
  }

  private func deleteChannel() {
    let message: String?
    if let name = viewModel?.channel?.name {
      message = String(format: localizable("confirm_delete_text"), name) + localizable("question_mark")
    } else {
      message = localizable("confirm_delete_text") + localizable("question_mark")
    }
    let alertVC = UIAlertController.reconfimAlertView(
      title: localizable("delete_channel"),
      message: message
    ) {
      self.viewModel?.deleteChannel(completion: { [weak self] error in
        NELog.infoLog(
          ModuleName + " " + (self?.className ?? "QChatChannelSettingVC"),
          desc: "CALLBACK deleteChannel " + (error?.localizedDescription ?? "no error")
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
        } else {
          self?.view.makeToast(
            localizable("delete_channel_suscess"),
            duration: 1,
            position: .center,
            completion: { didTap in
              // 通知上级页面
              NotificationCenter.default.post(
                name: NotificationName.deleteChannel,
                object: self?.viewModel?.channel
              )
              self?.didDeleteChannel?(self?.viewModel?.channel)
              self?.close()
            }
          )
        }
      })
    }
    present(alertVC, animated: true, completion: nil)
  }

//    MARK: QChatTextEditCellDelegate

  func textDidChange(_ textField: UITextField) {
    if let _ = textField.markedTextRange {
      return
    }
    if textField.tag == 20 {
      if textField.text?.count == 0 {
        navigationItem.rightBarButtonItem?.tintColor = .ne_greyText
      } else {
        navigationItem.rightBarButtonItem?.tintColor = .ne_blueText
      }
      viewModel?.channelTmp?.name = textField.text
    } else if textField.tag == 21 {
      viewModel?.channelTmp?.topic = textField.text
    }
  }

//    MARK: event

  @objc func save() {
    viewModel?.updateChannelInfo(completion: { [weak self] error, channel in
      NELog.infoLog(
        ModuleName + " " + (self?.className ?? "QChatChannelSettingVC"),
        desc: "CALLBACK updateChannelInfo " + (error?.localizedDescription ?? "no error")
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
        return
      }
      self?.showToastInWindow(localizable("update_channel_suscess"))
      self?.didUpdateChannel?(channel)
      NotificationCenter.default.post(
        name: NotificationName.updateChannel,
        object: channel
      )
      // 通知上级页面
      self?.close()
    })
  }

  @objc func close() {
    navigationController?.dismiss(animated: true, completion: nil)
  }
}
