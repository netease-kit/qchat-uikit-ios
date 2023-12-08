
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import UIKit

public enum EditType: Int {
  case nickName = 0
  case cellphone
  case email
  case specialSign
}

class InputPersonInfoController: NEBaseViewController, UITextFieldDelegate {
  typealias ResultCallBack = (String) -> Void
  public var contentText: String? {
    didSet {
      textField.text = contentText
    }
  }

  public var callBack: ResultCallBack?
  private var limitNumberCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setupSubviews()
    initialConfig()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: { [weak self] in
      self?.textField.becomeFirstResponder()
    }))
  }

  func setupSubviews() {
    view.addSubview(textfieldBgView)
    NSLayoutConstraint.activate([
      textfieldBgView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0),
      textfieldBgView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      textfieldBgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12 + topConstant),
      textfieldBgView.heightAnchor.constraint(equalToConstant: 50),
    ])

    textfieldBgView.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: textfieldBgView.leftAnchor, constant: 16),
      textField.rightAnchor.constraint(equalTo: textfieldBgView.rightAnchor, constant: -12),
      textField.topAnchor.constraint(equalTo: textfieldBgView.topAnchor, constant: 0),
      textField.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  func initialConfig() {
    view.backgroundColor = .ne_lightBackgroundColor
    addRightAction(NSLocalizedString("save", comment: ""), #selector(saveName), self)
    navigationView.setMoreButtonTitle(NSLocalizedString("save", comment: ""))
    navigationView.addMoreButtonTarget(target: self, selector: #selector(saveName))
    navigationView.backgroundColor = .ne_lightBackgroundColor
  }

  @objc func saveName() {
    if let block = callBack {
      block(textField.text ?? "")
    }
  }

  func configTitle(editType: EditType) {
    switch editType {
    case .nickName:
      title = NSLocalizedString("nickname", comment: "")
      limitNumberCount = 30
    case .cellphone:
      title = NSLocalizedString("phone", comment: "")
      limitNumberCount = 11
      textField.keyboardType = .phonePad
    case .email:
      title = NSLocalizedString("email", comment: "")
      limitNumberCount = 30
      textField.keyboardType = .emailAddress
    case .specialSign:
      title = NSLocalizedString("individuality_sign", comment: "")
      limitNumberCount = 50
    }
  }

  // MARK: lazy Method

  lazy var textField: UITextField = {
    let text = UITextField()
    text.translatesAutoresizingMaskIntoConstraints = false
    text.textColor = UIColor(hexString: "0x333333")
    text.font = UIFont.systemFont(ofSize: 14)
    text.delegate = self
    text.clearButtonMode = .always
    text.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    return text
  }()

  lazy var textfieldBgView: UIView = {
    let backView = UIView()
    backView.backgroundColor = .white
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    backView.translatesAutoresizingMaskIntoConstraints = false
    return backView
  }()

  @objc
  func textFieldChange() {
    guard let _ = textField.markedTextRange else {
      if let text = textField.text,
         text.count > limitNumberCount {
        textField.text = String(text.prefix(limitNumberCount))
        showToast(String(format: NSLocalizedString("text_count_limit", comment: ""), limitNumberCount))
      }
      return
    }
  }
}
