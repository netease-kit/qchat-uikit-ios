
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objc public enum QChatMenuType: Int {
  case text = 0
  case audio
  case emoji
  case image
  case addMore
}

@objc
public protocol QChatInputViewDelegate: NSObjectProtocol {
  func sendText(text: String?)
  func willSelectItem(button: UIButton, index: Int)
  func startRecord()
  func moveOutView()
  func moveInView()
  func endRecord(insideView: Bool)

  func textChanged(text: String) -> Bool
  func textFieldDidChange(_ textField: UITextView)
  func textFieldDidEndEditing(_ textField: UITextView)
  func textDelete(range: NSRange, text: String) -> Bool
  func textFieldDidBeginEditing(_ textField: UITextView)
}

@objcMembers
public class QChatInputView: UIView, QChatRecordViewDelegate, InputEmoticonContainerViewDelegate, UITextViewDelegate {
  public weak var delegate: QChatInputViewDelegate?
  public var currentType: QChatMenuType = .text
  public var contentSubView: UIView?
  private var recordView = QChatRecordView(frame: .zero)
  var contentView = UIView()
  public var currentButton: UIButton?
  public var contentHeight = 204.0
  public var menuHeight = 100.0
  private var greyView = UIView()

  public var buttons = [UIButton]()

  public lazy var emojiView: InputEmoticonContainerView = {
    let view =
      InputEmoticonContainerView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 200))
    //        view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    view.delegate = self
    return view
  }()

  public lazy var coverLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = UIColor(hexString: "#E4E4E5")
    label.textColor = UIColor(hexString: "#B3B7BC")
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isHidden = true
    label.text = "  \(localizable("qchat_visitor_chat_join_tip"))"
    label.font = UIFont.systemFont(ofSize: 16)
    label.clipsToBounds = true
    return label
  }()

//  var textField = UITextField()

  var textField = NETextView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    backgroundColor = UIColor(hexString: "#EFF1F3")
    textField.layer.cornerRadius = 8
    textField.font = UIFont.systemFont(ofSize: 16)
    textField.clipsToBounds = true
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.backgroundColor = .white
    textField.returnKeyType = .send
    textField.delegate = self
    textField.allowsEditingTextAttributes = true
    addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
      textField.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
      textField.heightAnchor.constraint(equalToConstant: 40),
    ])

    addSubview(coverLabel)
    NSLayoutConstraint.activate([
      coverLabel.leftAnchor.constraint(equalTo: textField.leftAnchor),
      coverLabel.topAnchor.constraint(equalTo: textField.topAnchor),
      coverLabel.rightAnchor.constraint(equalTo: textField.rightAnchor),
      coverLabel.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
    ])
    coverLabel.layer.cornerRadius = textField.layer.cornerRadius

    let imageNames = ["mic", "emoji", "photo", "add"]
    let imageNamesSelected = ["mic_selected", "emoji_selected", "photo", "add_selected"]
    var items = [UIButton]()
    for i in 0 ..< imageNames.count {
      let button = UIButton(type: .custom)
      button.setImage(UIImage.ne_imageNamed(name: imageNames[i]), for: .normal)
      button.setImage(UIImage.ne_imageNamed(name: imageNamesSelected[i]), for: .selected)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(buttonEvent), for: .touchUpInside)
      button.tag = i + 5
      items.append(button)
      buttons.append(button)
    }
    let stackView = UIStackView(arrangedSubviews: items)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.distribution = .fillEqually
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor),
      stackView.rightAnchor.constraint(equalTo: rightAnchor),
      stackView.heightAnchor.constraint(equalToConstant: 54),
      stackView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 0),
    ])

    greyView.translatesAutoresizingMaskIntoConstraints = false
    greyView.backgroundColor = UIColor(hexString: "#EFF1F3")
    greyView.isHidden = true
    addSubview(greyView)
    NSLayoutConstraint.activate([
      greyView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      greyView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      greyView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      greyView.heightAnchor.constraint(equalToConstant: 100),
    ])

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leftAnchor.constraint(equalTo: leftAnchor),
      contentView.rightAnchor.constraint(equalTo: rightAnchor),
      contentView.heightAnchor.constraint(equalToConstant: contentHeight),
      contentView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 0),
    ])

    recordView.isHidden = true
    recordView.translatesAutoresizingMaskIntoConstraints = false
    recordView.delegate = self
    recordView.backgroundColor = UIColor.ne_backgroundColor
    contentView.addSubview(recordView)
    NSLayoutConstraint.activate([
      recordView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      recordView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      recordView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      recordView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
    ])

    contentView.addSubview(emojiView)
  }

//  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//    guard let text = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
//      return true
//    }
//    textField.text = ""
//    delegate?.sendText(text: text)
//    textField.resignFirstResponder()
//    return true
//  }

  func buttonEvent(button: UIButton) {
    button.isSelected = !button.isSelected
    if button.tag - 5 != 2, button != currentButton {
      currentButton?.isSelected = false
      currentButton = button
    }

    switch button.tag - 5 {
    case 0:
      addRecordView()
    case 1:
      addEmojiView()
    case 3:
      addMoreActionView()
    default:
      print("default")
    }
    delegate?.willSelectItem(button: button, index: button.tag - 5)
  }

  func addRecordView() {
    currentType = .audio
    textField.resignFirstResponder()
    contentSubView?.isHidden = true
    contentSubView = recordView
    contentSubView?.isHidden = false
  }

  func addEmojiView() {
    currentType = .emoji
    textField.resignFirstResponder()
    contentSubView?.isHidden = true
    contentSubView = emojiView
    contentSubView?.isHidden = false
  }

  func addMoreActionView() {
    currentType = .addMore
    contentSubView?.isHidden = true
    textField.resignFirstResponder()
  }

  public func startRecord() {
    greyView.isHidden = false
    delegate?.startRecord()
  }

  public func moveOutView() {
    delegate?.moveOutView()
  }

  public func moveInView() {
    delegate?.moveInView()
  }

  public func endRecord(insideView: Bool) {
    greyView.isHidden = true
    delegate?.endRecord(insideView: insideView)
  }

  public func stopRecordAnimation() {
    greyView.isHidden = true
    recordView.stopRecordAnimation()
  }

  public func selectedEmoticon(emoticonID: String, emotCatalogID: String, description: String) {
    if emoticonID.isEmpty { // 删除键
      //            doButtonDeleteText()
      textField.deleteBackward()
      print("delete ward")
    } else {
      if let font = textField.font {
        let attribute = NEEmotionTool.getAttWithStr(
          str: description,
          font: font,
          CGPoint(x: 0, y: -4)
        )
        print("attribute : ", attribute)
        let mutaAttribute = NSMutableAttributedString()
        if let origin = textField.attributedText {
          mutaAttribute.append(origin)
        }
        attribute.enumerateAttribute(
          NSAttributedString.Key.attachment,
          in: NSMakeRange(0, attribute.length)
        ) { value, range, stop in
          if let neAttachment = value as? NEEmotionAttachment {
            print("ne attachment bounds ", neAttachment.bounds)
          }
        }
        mutaAttribute.append(attribute)
        mutaAttribute.addAttribute(
          NSAttributedString.Key.font,
          value: font,
          range: NSMakeRange(0, mutaAttribute.length)
        )
        textField.attributedText = mutaAttribute
        textField.scrollRangeToVisible(NSMakeRange(textField.attributedText.length, 1))
        //                [_textView scrollRangeToVisible:NSMakeRange(_textView.text.length, 1)];
      }
    }
  }

  public func didPressSend(sender: UIButton) {
    guard let text = getRealSendText(textField.attributedText) else {
      return
    }
    delegate?.sendText(text: text)
    textField.text = ""
//      atCache?.clean()
  }

  func getRealSendText(_ attribute: NSAttributedString) -> String? {
    let muta = NSMutableString()

    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: NSAttributedString.EnumerationOptions(rawValue: 0)
    ) { dics, range, stop in

      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment,
         let des = neAttachment.emotion?.tag {
        muta.append(des)
      } else {
        let sub = attribute.attributedSubstring(from: range).string
        muta.append(sub)
      }
    }
    return muta as String
  }

  public func textViewDidChange(_ textView: UITextView) {
    delegate?.textFieldDidChange(textField)
  }

  public func textViewDidEndEditing(_ textView: UITextView) {
    delegate?.textFieldDidEndEditing(textView)
  }

  public func textViewDidBeginEditing(_ textView: UITextView) {
    delegate?.textFieldDidBeginEditing(textView)
  }

  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    currentType = .text
    return true
  }

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    currentType = .text
    return true
  }

  public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                       replacementText text: String) -> Bool {
    if text == "\n" {
      guard let text = getRealSendText(textField.attributedText)?
        .trimmingCharacters(in: CharacterSet.whitespaces) else {
        return true
      }
      delegate?.sendText(text: text)
      textField.text = ""
      //            textView.resignFirstResponder()
      return false
    }

    print("range:\(range) string:\(text)")
    if text.count == 0 {
      if let delegate = delegate {
        return delegate.textDelete(range: range, text: text)
      }
    } else {
      delegate?.textChanged(text: text)
    }

    return true
  }

  public func setVisitorModel(isVisitorMode: Bool) {
    buttons.forEach { button in
      button.alpha = isVisitorMode ? 0.5 : 1.0
    }
    coverLabel.isHidden = !isVisitorMode
  }

//    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//      guard let text = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
//        return true
//      }
//      textField.text = ""
//      delegate?.sendText(text: text)
//      return true
//    }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                        replacementString string: String) -> Bool {
    print("range:\(range) string:\(string)")
    if string.count == 0 {
      if let delegate = delegate {
        return delegate.textDelete(range: range, text: string)
      }
    } else {
      delegate?.textChanged(text: string)
    }
    return true
  }
}
