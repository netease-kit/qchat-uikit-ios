
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

@objc public enum QChatChannelChangeType: Int {
  case ChannelName = 0
  case ChannelDesc
}

public protocol QChatAnncNameEditViewControllerDelegate: NSObjectProtocol {
  func updatedChannelName(name: String?)
}

@objcMembers
open class QChatAnncNameEditViewController: NEBaseViewController, UITextViewDelegate, NIMQChatMessageManagerDelegate {
  var server: QChatServer?
  public var type = QChatChannelChangeType.ChannelName
  public var repo = QChatRepo.shared
  public var textLimit = 50
  public weak var delegate: QChatAnncNameEditViewControllerDelegate?

  public var backViewHeightConstraint: NSLayoutConstraint?

  public let backView = UIView()

  public lazy var countLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_emptyTitleColor
    label.font = NEConstant.defaultTextFont(12.0)
    label.isUserInteractionEnabled = false
    return label
  }()

  public lazy var textView: UITextView = {
    let text = UITextView()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = .ne_darkText
    text.font = NEConstant.defaultTextFont(14.0)
    text.delegate = self
    return text
  }()

  public lazy var clearButton: UIButton = {
    let text = UIButton()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.setImage(coreLoader.loadImage("clear_btn"), for: .normal)
    text.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    return text
  }()

  init(server: QChatServer?, type: QChatChannelChangeType) {
    super.init(nibName: nil, bundle: nil)
    self.server = server
    self.type = type
    NIMSDK.shared().qchatMessageManager.add(self)
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NIMSDK.shared().qchatMessageManager.remove(self)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    var name = ""
    if type == .ChannelName, let n = server?.name {
      title = localizable("notice_name")
      name = n
    } else if type == .ChannelDesc {
      title = localizable("channel_description")
      name = server?.topic ?? ""
      textLimit = 64
      backViewHeightConstraint?.constant = 96
    }
    figureTextCount(name)
  }

  open func setupUI() {
    view.backgroundColor = .ne_lightBackgroundColor
    navigationView.backgroundColor = .ne_lightBackgroundColor
    navigationController?.navigationBar.backgroundColor = .ne_lightBackgroundColor
    addRightAction(localizable("save"), #selector(saveName), self)
    navigationView.setMoreButtonTitle(localizable("save"))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))

    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.layer.cornerRadius = 8.0
    view.addSubview(backView)
    backViewHeightConstraint = backView.heightAnchor.constraint(equalToConstant: CGFloat(textLimit + 25))
    NSLayoutConstraint.activate([
      backView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
      backView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      backView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + NEConstant.navigationAndStatusHeight),
      backViewHeightConstraint!,
    ])

    backView.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 8),
      textView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -32),
      textView.topAnchor.constraint(equalTo: backView.topAnchor),
      textView.bottomAnchor.constraint(equalTo: backView.bottomAnchor),
    ])

    backView.addSubview(clearButton)
    NSLayoutConstraint.activate([
      clearButton.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      clearButton.centerYAnchor.constraint(equalTo: textView.textInputView.centerYAnchor),
      clearButton.widthAnchor.constraint(equalToConstant: 16),
      clearButton.heightAnchor.constraint(equalToConstant: 16),
    ])

    backView.addSubview(countLabel)
    NSLayoutConstraint.activate([
      countLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -8),
      countLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -8.0),
    ])

    getEditChannelAuthStatus { [weak self] allow in
      if !allow {
        self?.hideSubmit()
      }
    }
  }

  func getEditChannelAuthStatus(_ completion: @escaping (Bool) -> Void) {
    if server?.owner == QChatKitClient.instance.imAccid() {
      completion(true)
      return
    }

    guard let serverId = server?.serverId,
          let channelId = server?.announce?.channelId?.uint64Value else {
      return
    }

    repo.checkPermission(serverId: serverId, channelId: channelId, permissionType: .manageChannel) { [weak self] error, allow in
      if let err = error as NSError? {
        switch err.code {
        case errorCode_NetWorkError:
          self?.showToast(localizable("network_error"))
        case errorCode_NoPermission:
          self?.showToast(localizable("no_permession"))
        default:
          self?.showToast(err.localizedDescription)
        }
        completion(false)
      } else {
        completion(allow)
      }
    }
  }

  open func disableSubmit() {
    rightNavBtn.setTitleColor(.ne_disableBlueText, for: .normal)
    rightNavBtn.isEnabled = false
    navigationView.moreButton.setTitleColor(.ne_disableBlueText, for: .normal)
    navigationView.moreButton.isEnabled = false
  }

  open func enableSubmit() {
    rightNavBtn.setTitleColor(.ne_blueText, for: .normal)
    rightNavBtn.isEnabled = true
    navigationView.moreButton.setTitleColor(.ne_blueText, for: .normal)
    navigationView.moreButton.isEnabled = true
  }

  open func hideSubmit() {
    rightNavBtn.isHidden = true
    navigationView.moreButton.isHidden = true
    textView.isEditable = false
    clearButton.isHidden = true
  }

  open func showSubmit() {
    rightNavBtn.isHidden = false
    navigationView.moreButton.isHidden = false
    textView.isEditable = true
    clearButton.isHidden = false
  }

  open func saveName() {
    guard let sid = server?.serverId else {
      showToast(localizable("team_not_exist"))
      return
    }

    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    guard var serverParam = server?.convertUpdateServerParam() else { return }

    if type == .ChannelDesc {
      // 修改频道说明
      if var customDic = NECommonUtil.getDictionaryFromJSONString(server?.custom ?? "") as? [String: AnyObject] {
        customDic["topic"] = textView.text as AnyObject
        serverParam.custom = NECommonUtil.getJSONStringFromDictionary(customDic)
      }
    } else {
      // 修改频道名称
      serverParam.name = textView.text
    }

    textView.resignFirstResponder()
    view.makeToastActivity(.center)
    QChatRepo.shared.updateServer(serverParam) { [weak self] error, _ in
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
        if self?.type == .ChannelName {
          self?.delegate?.updatedChannelName(name: self?.textView.text)
        }
        self?.navigationController?.popViewController(animated: true)
      }
    }
  }

  func clearText() {
    figureTextCount("")
  }

  func figureTextCount(_ text: String) {
    textView.text = text
    countLabel.text = "\(text.utf16.count)/\(textLimit)"
    clearButton.isHidden = text.utf16.count <= 0
    if type == .ChannelDesc {
      return
    }

    if let text = textView.text,
       !text.isEmpty {
      let trimText = text.trimmingCharacters(in: .whitespaces)
      if trimText.isEmpty {
        // 不支持全空格
        disableSubmit()
        return
      }
    }

    if text.isEmpty {
      disableSubmit()
    } else {
      enableSubmit()
    }
  }

  // MARK: UITextViewDelegate

  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if !text.isEmpty {
      let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
      if newText.utf16.count > textLimit {
        return false
      }
    }
    return true
  }

  public func textViewDidChange(_ textView: UITextView) {
    if let _ = textView.markedTextRange {
      return
    }
    figureTextCount(textView.text)
  }

  // MARK: NIMQChatMessageManagerDelegate

  public func onRecvSystemNotification(_ result: NIMQChatReceiveSystemNotificationResult) {
    if let systemNotis = result.systemNotifications {
      for systemNoti in systemNotis {
        guard systemNoti.serverId == server?.serverId else {
          continue
        }
        if systemNoti.type == .removeServerRoleMembers,
           let attach = systemNoti.attach as? NIMQChatRemoveServerRoleMembersNotificationAttachment {
          // 移除社区身份组成员
          if systemNoti.serverId == server?.serverId, attach.roleId == server?.announce?.roleId?.uint64Value {
            // 移除管理员
            if attach.removeServerRoleAccIds?.contains(QChatKitClient.instance.imAccid()) == true {
              // 自己被移除
              navigationController?.popViewController(animated: true)
            }
          }
        } else if systemNoti.type == .memberRoleAuthUpdate,
                  let attach = systemNoti.attach as? NIMQChatUpdateMemberRoleAuthNotificationAttachment {
          // 更新个人定制权限
          if attach.accId == QChatKitClient.instance.imAccid() {
            // 自己的定制权限变更
            for updateAuth in attach.updateAuths {
              if updateAuth.type == .manageChannel {
                // 编辑公告频道信息权限
                if updateAuth.status == .deny {
                  hideSubmit()
                } else {
                  showSubmit()
                }
              }
            }
          }
        }
      }
    }
  }
}
