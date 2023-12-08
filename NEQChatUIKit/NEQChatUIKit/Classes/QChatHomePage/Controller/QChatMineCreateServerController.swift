
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreQChatKit
import NEQChatKit
import NIMSDK
import UIKit

public class QChatMineCreateServerController: NEBaseViewController, UINavigationControllerDelegate,
  UITextFieldDelegate {
  private let tag = "QChatMineCreateServerController"
  public var serverViewModel = QChatMineCreateViewModel()
  var headImageUrl: String?
  let nameLimit = 50
  var isAnnouncement = false

  override public func viewDidLoad() {
    super.viewDidLoad()
    initializeConfig()
    setupSubviews()
  }

  func initializeConfig() {
    title = isAnnouncement ? localizable("qchat_create_public_server") : localizable("qchat_mine_add")
    textField.placeholder = isAnnouncement ? localizable("enter_noticeName") : localizable("enter_serverName")
    navigationView.backgroundColor = .white
    navigationView.titleBarBottomLine.isHidden = false
  }

  func setupSubviews() {
    view.addSubview(uploadBgView)
    uploadBgView.addSubview(cameraImageView)
    uploadBgView.addSubview(uploadDesLabel)
    view.addSubview(selectHeadImage)
    view.addSubview(textField)
    view.addSubview(bottomBtn)

    NSLayoutConstraint.activate([
      uploadBgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      uploadBgView.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: CGFloat(kNavigationHeight) + KStatusBarHeight + 40
      ),
      uploadBgView.widthAnchor.constraint(equalToConstant: 80),
      uploadBgView.heightAnchor.constraint(equalToConstant: 80),
    ])

    NSLayoutConstraint.activate([
      selectHeadImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      selectHeadImage.topAnchor.constraint(
        equalTo: view.topAnchor,
        constant: CGFloat(kNavigationHeight) + KStatusBarHeight + 40
      ),
      selectHeadImage.widthAnchor.constraint(equalToConstant: 80),
      selectHeadImage.heightAnchor.constraint(equalToConstant: 80),
    ])
    NSLayoutConstraint.activate([
      cameraImageView.centerXAnchor.constraint(equalTo: uploadBgView.centerXAnchor),
      cameraImageView.topAnchor.constraint(equalTo: uploadBgView.topAnchor, constant: 18),
    ])

    NSLayoutConstraint.activate([
      uploadDesLabel.centerXAnchor.constraint(equalTo: uploadBgView.centerXAnchor),
      uploadDesLabel.topAnchor.constraint(equalTo: cameraImageView.bottomAnchor, constant: 9),
    ])

    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: kScreenInterval),
      textField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -kScreenInterval),
      textField.topAnchor.constraint(equalTo: uploadBgView.bottomAnchor, constant: 40),
      textField.heightAnchor.constraint(equalToConstant: 40),
    ])

    NSLayoutConstraint.activate([
      bottomBtn.leftAnchor.constraint(equalTo: view.leftAnchor, constant: kScreenInterval),
      bottomBtn.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -kScreenInterval),
      bottomBtn.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 40),
      bottomBtn.heightAnchor.constraint(equalToConstant: 40),
    ])
  }

  // MARK: lazyMethod

  private lazy var uploadBgView: UIButton = {
    let button = UIButton()
    button.setBackgroundImage(UIImage.ne_imageNamed(name: "uploadPic_bg_icon"), for: .normal)
    button.setBackgroundImage(
      UIImage.ne_imageNamed(name: "uploadPic_bg_icon"),
      for: .highlighted
    )
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(uploadBgViewClick), for: .touchUpInside)
    return button

  }()

  private lazy var selectHeadImage: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 40
    imageView.clipsToBounds = true
    return imageView
  }()

  private lazy var cameraImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "upload_camera"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var uploadDesLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("upload_headImage")
    label.textColor = HexRGB(0x656A72)
    label.font = DefaultTextFont(12)
    return label
  }()

  private lazy var textField: UITextField = {
    let textField = UITextField()
    textField.placeholder = localizable("enter_serverName")
    textField.font = DefaultTextFont(16)
    textField.textColor = TextNormalColor
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.layer.cornerRadius = 8
    textField.backgroundColor = HexRGB(0xEFF1F4)
    textField.delegate = self
    textField.addTarget(self, action: #selector(textContentChanged), for: .editingChanged)
    textField.clearButtonMode = .whileEditing
    let right = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 1))
    textField.rightView = right
    textField.rightViewMode = .unlessEditing
    textField.leftView = UIView(frame: right.frame)
    textField.leftViewMode = .always
    return textField
  }()

  private lazy var bottomBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("create"), for: .normal)
    button.setTitleColor(UIColor.white, for: .normal)
    button.titleLabel?.font = DefaultTextFont(16)
    button.backgroundColor = HexRGBAlpha(0x337EFF, 0.5)
    button.layer.cornerRadius = 8
    button.addTarget(self, action: #selector(createServerBtnClick), for: .touchUpInside)
    return button
  }()

  @objc func createServerBtnClick(sender: UIButton) {
    NELog.infoLog(ModuleName + " " + tag, desc: "createServerBtn clicked")
    guard let serverName = textField.text, serverName.count > 0 else { return }

    if serverName.trimmingCharacters(in: .whitespaces).isEmpty {
      view.hideAllToasts()
      view.makeToast(localizable("space_not_support"), duration: 2, position: .center)
      textField.text = ""
      bottomBtn.isEnabled = false
      bottomBtn.backgroundColor = HexRGBAlpha(0x337EFF, 0.5)
      return
    }

    if NEChatDetectNetworkTool.shareInstance.isNetworkRecahability() {
      sender.isEnabled = false
    } else {
      showToast(localizable("network_error"))
      return
    }

    var param = CreateServerParam(name: serverName, icon: headImageUrl ?? "")
    param.applyMode = .autoEnter
    param.inviteMode = .autoEnter
    if isAnnouncement {
      serverViewModel.createAnncServer(parameter: &param) { [weak self] error, server in
        sender.isEnabled = true
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
          NotificationCenter.default.post(
            name: NotificationName.createAnnouncement,
            object: server
          )
          self?.navigationController?.dismiss(animated: true, completion: nil)
        }
      }
    } else {
      serverViewModel.createServer(parameter: param) { error, result in
        sender.isEnabled = true
        if error != nil {
          NELog.errorLog(ModuleName + " " + self.tag, desc: "❌createServer failed,error = \(error!)")
        } else {
          // 创建社区成功后，默认创建好两个话题
          if let serverId = result?.server?.serverId {
            NELog.infoLog(ModuleName + " " + self.tag, desc: "✅createServer success, serverId: \(serverId)")
            NotificationCenter.default.post(
              name: NotificationName.createServer,
              object: serverId
            )
            self.navigationController?.dismiss(animated: true, completion: nil)
          } else {
            print("serverId is nil")
            return
          }
        }
      }
    }

    // 应对wifi切换4G请求没有回调的处理结果
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      sender.isEnabled = true
    }
  }

  // Upload the picture
  @objc func uploadBgViewClick(sender: UIButton) {
    showBottomAlert(self)
  }

  @objc func textContentChanged() {
    if let _ = textField.markedTextRange {
      return
    }

    if textField.text?.count != 0 {
      bottomBtn.isEnabled = true
      bottomBtn.backgroundColor = HexRGB(0x337EFF)
    } else {
      bottomBtn.isEnabled = false
      bottomBtn.backgroundColor = HexRGBAlpha(0x337EFF, 0.5)
    }
  }

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController
                               .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    dismiss(animated: true, completion: nil)
  }

  public func uploadHeadImage(image: UIImage) {
    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData? {
      let filePath = NSHomeDirectory().appending("/Documents/")
        .appending(QChatKitClient.instance.imAccid())
      let succcess = imageData.write(toFile: filePath, atomically: true)

      if succcess {
        NIMSDK.shared().resourceManager
          .upload(filePath, progress: nil) { urlString, error in
            if error == nil {
              // 显示设置的照片
              self.selectHeadImage.image = image
              self.headImageUrl = urlString
              print("upload image success")
            } else {
              print("upload image failed,error = \(error!)")
            }
            self.view.hideToastActivity()
          }
      }
    }
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let text = textField.text {
      let newText = (text as NSString).replacingCharacters(in: range, with: string)
      if newText.utf16.count > nameLimit {
        return false
      }
    }
    return true
  }
}
