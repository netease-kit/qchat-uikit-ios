
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

struct Channel {
  var sectionName = ""
  var contentName = ""
}

public class QChatChannelViewController: QChatTableViewController, QChatTextEditCellDelegate,
  QChatChannelTypeVCDelegate {
  var viewModel: QChatChannelViewModel?
  var dataList = [Channel]()
  var textFld: UITextField?
  // 防重点击创建话题
  var isCreatedChannel = false
  private let className = "QChatChannelViewController"

  public init(serverId: UInt64) {
    viewModel = QChatChannelViewModel(serverId: serverId)
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
    title = localizable("create_channel")
    view.backgroundColor = .ne_lightBackgroundColor
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: localizable("create"),
      style: .plain,
      target: self,
      action: #selector(createChannel)
    )
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: localizable("cancel"),
      style: .plain,
      target: self,
      action: #selector(cancelEvent)
    )
    navigationItem.rightBarButtonItem?.tintColor = .ne_greyText

    navigationView.setMoreButtonTitle(localizable("create"))
    navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
    navigationView.addMoreButtonTarget(target: self, selector: #selector(createChannel))
    navigationView.setBackButtonTitle(localizable("cancel"))
    navigationView.addBackButtonTarget(target: self, selector: #selector(cancelEvent))
    navigationView.backgroundColor = .ne_lightBackgroundColor

    addLeftSwipeDismissGesture()

    tableView.backgroundColor = .clear

    tableView.register(
      QChatTextEditCell.self,
      forCellReuseIdentifier: "\(QChatTextEditCell.self)"
    )
    tableView.register(
      QChatTextArrowCell.self,
      forCellReuseIdentifier: "\(QChatTextArrowCell.self)"
    )
    tableView.register(
      QChatSectionView.self,
      forHeaderFooterViewReuseIdentifier: "\(QChatSectionView.self)"
    )
  }

  func loadData() {
    dataList
      .append(Channel(sectionName: localizable("channel_name"),
                      contentName: localizable("input_channel_name")))
    dataList.append(Channel(
      sectionName: localizable("channel_topic"),
      contentName: localizable("input_channel_topic")
    ))
    dataList
      .append(Channel(sectionName: localizable("channel_type"),
                      contentName: localizable("public")))
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    dataList.count
  }

  override public func tableView(_ tableView: UITableView,
                                 numberOfRowsInSection section: Int) -> Int {
    1
  }

  override public func tableView(_ tableView: UITableView,
                                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      cell.textFied.placeholder = dataList[indexPath.section].contentName
      cell.delegate = self
      cell.textFied.tag = 11
      cell.limit = 50
      return cell
    } else if indexPath.section == 1 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextEditCell.self)",
        for: indexPath
      ) as! QChatTextEditCell
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      cell.textFied.placeholder = dataList[indexPath.section].contentName
      cell.delegate = self
      cell.textFied.tag = 12
      cell.limit = 64
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "\(QChatTextArrowCell.self)",
        for: indexPath
      ) as! QChatTextArrowCell
      cell.titleLabel.text = dataList[indexPath.section].contentName
      cell.cornerType = CornerType.bottomLeft.union(CornerType.bottomRight)
        .union(CornerType.topLeft).union(CornerType.topRight)
      cell.dividerLine.isHidden = true
      return cell
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let sectionView = tableView
      .dequeueReusableHeaderFooterView(
        withIdentifier: "\(QChatSectionView.self)"
      ) as! QChatSectionView
    sectionView.titleLabel.text = dataList[section].sectionName
    return sectionView
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 2 {
      // select channel type
      let vc = QChatChannelTypeVC()
      vc.delegate = self
      vc.isPrivate = viewModel?.isPrivate ?? false
      navigationController?.pushViewController(vc, animated: true)
    }
  }

//    MARK: event

  @objc func createChannel() {
    guard let name = viewModel?.name, name.count > 0 else {
      view.hideAllToasts()
      view.makeToast(localizable("channelName_cannot_be_empty"), duration: 2, position: .center)
      return
    }

    let text = name.trimmingCharacters(in: .whitespaces)
    if text.isEmpty {
      view.hideAllToasts()
      view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
      if let textField = textFld {
        textField.text = text
        viewModel?.name = text
      }
      return
    }
    if !isCreatedChannel {
      isCreatedChannel = true
      viewModel?.createChannel { [weak self] error, channel in
        if let err = error {
          NELog.errorLog(
            ModuleName + " " + (self?.className ?? "QChatChannelViewController"),
            desc: "error:\(err.localizedDescription) channel:\(String(describing: channel))"
          )
          self?.view.hideAllToasts()
          switch err.code {
          case errorCode_NetWorkError:
            self?.showToast(localizable("network_error"))
          case errorCode_NoPermission:
            self?.showToast(localizable("no_permession"))
          default:
            self?.showToast(err.localizedDescription)
          }
          self?.isCreatedChannel = false
        } else {
          // success to chatVC
          self?.navigationController?.dismiss(animated: true, completion: {
            NotificationCenter.default.post(
              name: NotificationName.createChannel,
              object: channel
            )
          })
        }
      }
    }
  }

  @objc func cancelEvent() {
    print(#function)
    dismiss(animated: true, completion: nil)
  }

//    MARK: QChatTextEditCellDelegate

  func textDidChange(_ textField: UITextField) {
    if let _ = textField.markedTextRange {
      return
    }
    print("textFieldDidChangeSelection textField:\(textField.text)")
    textFld = textField
    if textField.tag == 11 {
      if textField.text?.count == 0 {
        navigationItem.rightBarButtonItem?.tintColor = .ne_greyText
        navigationView.moreButton.setTitleColor(.ne_greyText, for: .normal)
      } else {
        navigationItem.rightBarButtonItem?.tintColor = .ne_blueText
        navigationView.moreButton.setTitleColor(.ne_blueText, for: .normal)
      }
      viewModel?.name = textField.text
    } else if textField.tag == 12 {
      viewModel?.topic = textField.text
    }
  }

//    MARK: QChatChannelTypeVCDelegate

  func didSelected(type: Int) {
    viewModel?.isPrivate = type == 0 ? false : true
    if dataList.count >= 3 {
      dataList.removeLast()
      dataList.append(Channel(
        sectionName: localizable("channel_type"),
        contentName: type == 0 ? localizable("public") : localizable("private")
      ))
      tableView.reloadData()
    }
  }
}
