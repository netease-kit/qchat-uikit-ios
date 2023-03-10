
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NIMSDK
import NECommonKit

public class MineCreateServerController: NEBaseViewController, UINavigationControllerDelegate,
  UITextFieldDelegate {
  private let tag = "MineCreateServerController"
  public var serverViewModel = CreateServerViewModel()
  var headImageUrl: String?
  let nameLimit = 50

  override public func viewDidLoad() {
    super.viewDidLoad()
    initializeConfig()
    setupSubviews()
  }

  func initializeConfig() {
    title = localizable("qchat_mine_add")
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
    serverViewModel.createServer(parameter: param) { error, result in
      if error != nil {
        NELog.errorLog(ModuleName + " " + self.tag, desc: "❌createServer failed,error = \(error!)")
      } else {
        // 创建服务器成功后，默认创建好两个频道
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
    if let text = textField.text,
       text.count > nameLimit {
      textField.text = String(text.prefix(nameLimit))
      view.hideAllToasts()
      view.makeToast(localizable("serverName_limit"), duration: 2, position: .center)
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
        .appending(IMKitEngine.instance.imAccid)
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
}
