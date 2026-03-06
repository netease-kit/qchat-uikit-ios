
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

// MARK: - @ 功能常量（对标 NEChatUIKit 的 NEBaseChatInputView）
public let qchat_yxAtMsg = "yxAitMsg"
public let qchat_atSegmentsKey = "segments"
public let qchat_atTextKey = "text"

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

  /// 输入 "@" 后触发，通知 Controller 弹出成员选择界面
  @objc optional func shouldShowAtMemberSelect()
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

  // @mention 追踪属性
  /// 已插入的 @mention 文本范围缓存（兼容旧接口保留，实际删除逻辑依赖颜色检测）
  public var atRangeCache = [String: NSRange]()
  /// 已 @ 的用户 accid 列表（有序）
  public var nickAccidList = [String]()
  /// 已 @ 的用户显示名（含"@"前缀）到 accid 的映射
  public var nickAccidDic = [String: String]()
  /// 输入 "@" 时记录的光标位置（"@" 字符将被插入的 index），modal 弹出后 selectedRange 会归零，需提前缓存
  private var atTriggerLocation: Int = -1

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
    super.init(coder: coder)
  }

  func commonUI() {
    backgroundColor = .ne_backgroundColor
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
    greyView.backgroundColor = .ne_backgroundColor
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
      clearAtCache()
      return false
    }

    if text.count == 0 {
      // 删除操作：参考 NEBaseChatInputView 的 checkRemoveAtMessage，通过颜色检测整段原子删除
      if checkRemoveAtMessage(range: range) {
        return false
      }
      if let delegate = delegate {
        return delegate.textDelete(range: range, text: text)
      }
    } else {
      // 输入 "@" 时，先缓存 "@" 将要出现的位置（range.location），再通知 Controller 弹出成员选择界面。
      // modal 弹出后 textView 会失焦，selectedRange 归零，所以必须在此处提前记录。
      if text == "@" {
        // range.location 是 "@" 即将插入的位置。
        // 注意：shouldChangeTextIn 返回 true 后，系统在同一 runloop 内插入 "@"。
        // 但若此处同步调用 delegate（弹出 modal），iOS 可能在 modal present 动画开始前就
        // 让 UITextView 失焦，导致字符插入时机不确定。
        // 解决方案：自己手动把 "@" 插入文本（返回 false 阻止系统插入），再弹出 modal。
        // 这样 atPos 处的 "@" 一定存在，addToAtUsers 替换时可以精确命中。
        atTriggerLocation = range.location
        // 手动插入 "@"，并应用当前字体
        let currentFont = textField.font ?? UIFont.systemFont(ofSize: 16)
        let atAttr = NSAttributedString(string: "@", attributes: [
          .foregroundColor: UIColor.ne_darkText,
          .font: currentFont,
        ])
        let muta = NSMutableAttributedString(attributedString: textField.attributedText ?? NSAttributedString())
        muta.insert(atAttr, at: range.location)
        textField.attributedText = muta
        textField.selectedRange = NSRange(location: range.location + 1, length: 0)
        textField.typingAttributes = [
          .foregroundColor: UIColor.ne_darkText,
          .font: currentFont,
        ]
        // 同步弹出 modal（此时 "@" 已在文本里）
        delegate?.shouldShowAtMemberSelect?()
        return false  // 阻止系统再次插入 "@"
      }
      delegate?.textChanged(text: text)
    }

    return true
  }

  /// 参考 NEBaseChatInputView.checkRemoveAtMessage：
  /// 若光标前一个字符属于某个 @mention 段（通过颜色判断），则整段原子删除
  @discardableResult
  private func checkRemoveAtMessage(range: NSRange) -> Bool {
    guard let attrText = textField.attributedText, attrText.length > 0, range.location > 0 else {
      return false
    }
    // 取光标前一个字符的颜色
    let checkIndex = range.location - 1
    let color = attrText.attribute(.foregroundColor, at: checkIndex, effectiveRange: nil) as? UIColor
    guard color == UIColor.ne_normalTheme else { return false }

    // 枚举所有高亮段，找到包含 checkIndex 的那段
    var foundRange: NSRange? = nil
    attrText.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attrText.length), options: []) { value, r, stop in
      if let c = value as? UIColor, c == UIColor.ne_normalTheme {
        if r.contains(checkIndex) {
          foundRange = r
          stop.pointee = true
        }
      }
    }

    guard let mentionRange = foundRange else { return false }

    // 删除范围 = mention 高亮段 + 紧跟其后的一个空格（若存在）
    var deleteRange = mentionRange
    let afterMention = mentionRange.location + mentionRange.length
    if afterMention < attrText.length {
      let nextColor = attrText.attribute(.foregroundColor, at: afterMention, effectiveRange: nil) as? UIColor
      // 下一个字符颜色是 defaultColor（即空格），一并删除
      if nextColor != UIColor.ne_normalTheme {
        let nextChar = (attrText.string as NSString).character(at: afterMention)
        if nextChar == 32 { // 32 = ' '
          deleteRange = NSRange(location: mentionRange.location, length: mentionRange.length + 1)
        }
      }
    }

    // 从 nickAccidDic 中移除对应条目（通过文本匹配）
    let mentionText = attrText.attributedSubstring(from: mentionRange).string
    nickAccidDic.removeValue(forKey: mentionText.trimmingCharacters(in: .whitespaces))
    nickAccidList = nickAccidDic.values.map { $0 }

    // 整段删除（含尾部空格）
    let mutable = NSMutableAttributedString(attributedString: attrText)
    mutable.deleteCharacters(in: deleteRange)
    textField.attributedText = mutable

    let font = textField.font ?? UIFont.systemFont(ofSize: 16)
    textField.typingAttributes = [
      .foregroundColor: UIColor.ne_darkText,
      .font: font,
    ]
    textField.selectedRange = NSRange(location: deleteRange.location, length: 0)
    return true
  }

  /// 将 @用户名 插入输入框，并记录 accid
  public func addToAtUsers(addText: String, accid: String) {
    let font = textField.font ?? UIFont.systemFont(ofSize: 16)
    let defaultColor = UIColor.ne_darkText
    let mentionColor = UIColor.ne_normalTheme

    // 使用触发时缓存的位置；modal 弹出后 textView 失焦，selectedRange 会归零，不可信
    guard atTriggerLocation >= 0 else { return }
    let atPos = atTriggerLocation
    atTriggerLocation = -1

    // 构造 mention 字符串：addText 高亮，尾部空格用默认色
    // 空格必须用 defaultColor，否则后续输入会继承蓝色，且删除时被一并吞掉
    let mentionAttr = NSMutableAttributedString(string: addText, attributes: [
      .foregroundColor: mentionColor,
      .font: font,
    ])
    let spaceStr = NSAttributedString(string: " ", attributes: [
      .foregroundColor: defaultColor,
      .font: font,
    ])
    mentionAttr.append(spaceStr)

    // 取出当前文本
    let mutaString = NSMutableAttributedString(
      attributedString: textField.attributedText ?? NSAttributedString()
    )
    let currentStr = mutaString.string
    print("[AT] atPos=\(atPos), totalLen=\(mutaString.length), text='\(currentStr)'")

    // 找到 atPos 处字符（用 NSString 操作，避免 Swift String 与 NSRange 的 Unicode 偏移差异）：
    //   - 若是 "@"（unicode 0x40），替换掉（length=1）
    //   - 若不是（异常情况），直接插入（length=0）
    let nsStr = currentStr as NSString
    var replaceLen = 0
    if atPos < nsStr.length {
      let ch = nsStr.character(at: atPos)
      print("[AT] char at atPos='\(ch)' isAt=\(ch == 64)")
      replaceLen = (ch == 64) ? 1 : 0   // 64 = '@'
    }
    mutaString.replaceCharacters(in: NSRange(location: atPos, length: replaceLen), with: mentionAttr)
    finishAtInsertion(mutaString: mutaString, atPos: atPos,
                      addText: addText, accid: accid, font: font, defaultColor: defaultColor)
  }

  private func finishAtInsertion(mutaString: NSMutableAttributedString, atPos: Int,
                                 addText: String, accid: String, font: UIFont, defaultColor: UIColor) {
    // 记录 accid
    nickAccidList.append(accid.isEmpty ? "ait_all" : accid)
    nickAccidDic[addText] = accid.isEmpty ? "ait_all" : accid

    // 先将光标移到末尾再赋值，可减少 iOS 对 typingAttributes 的干扰
    textField.attributedText = mutaString

    // 光标移到 mention + 空格之后（addText 已含 "@"，空格算 +1）
    let newCursor = NSRange(location: atPos + addText.count + 1, length: 0)
    textField.selectedRange = newCursor

    // 赋值 + 设光标之后再设 typingAttributes，确保后续输入用默认色
    // （attributedText 赋值会重置 typingAttributes，必须在其之后设）
    textField.typingAttributes = [
      .foregroundColor: defaultColor,
      .font: font,
    ]
  }

  /// 发送后清除 @ 相关缓存
  public func clearAtCache() {
    atRangeCache.removeAll()
    nickAccidList.removeAll()
    nickAccidDic.removeAll()
  }

  // MARK: - @ remoteExt 构建（参考 NEBaseChatInputView.getAtRemoteExtension）

  /// 遍历输入框富文本，将所有蓝色 @ 片段的 start/end 信息写成 yxAitMsg 格式的字典
  /// - Returns: 可直接赋值给 NIMQChatMessage.remoteExt 的字典；无 @ 时返回 nil
  public func getAtRemoteExtension() -> [String: Any]? {
    guard let attribute = textField.attributedText else { return nil }
    var atDic = [String: [String: Any]]()
    let string = attribute.string

    print("[QChatAt-Debug] getAtRemoteExtension attrLen=\(attribute.length) string='\(string)' nickAccidDic=\(nickAccidDic)")

    attribute.enumerateAttribute(
      NSAttributedString.Key.foregroundColor,
      in: NSMakeRange(0, attribute.length)
    ) { value, findRange, _ in
      guard let findColor = value as? UIColor,
            isEqualToColor(findColor, UIColor.ne_normalTheme) else { return }
      if let range = Range(findRange, in: string) {
        let text = String(string[range])
        print("[QChatAt-Debug] found highlight range=\(findRange) text='\(text)'")
        let model = QChatMessageAtInfoModel()
        // 计算 @ 前面的表情带来的额外索引偏移
        let expandIndex = getConvertedExtraIndex(attribute.attributedSubstring(from: NSRange(location: 0, length: findRange.location)))
        model.start = findRange.location + expandIndex
        let nameExpandCount = getConvertedExtraIndex(attribute.attributedSubstring(from: findRange))
        // end 使用半开区间右边界，并 +1 将尾部空格纳入，与服务端返回格式一致
        model.end = model.start + findRange.length + nameExpandCount + 1
        print("[QChatAt-Debug] segment start=\(model.start) end=\(model.end) accid=\(nickAccidDic[text] ?? "nil")")

        if let accid = nickAccidDic[text] {
          var dic = atDic[accid] ?? [String: Any]()
          var array = (dic[qchat_atSegmentsKey] as? [Any]) ?? [Any]()
          let segObj: [String: Any] = ["start": model.start, "end": model.end]
          array.append(segObj)
          dic[qchat_atSegmentsKey] = array
          dic[qchat_atTextKey] = text + " "
          dic["accid"] = accid
          atDic[accid] = dic
        }
      }
    }
    return atDic.isEmpty ? nil : [qchat_yxAtMsg: atDic]
  }

  /// 计算富文本片段中表情占位符带来的额外索引数（一个表情字符 = tag 字符串长度 - 1）
  private func getConvertedExtraIndex(_ attribute: NSAttributedString) -> Int {
    var count = 0
    attribute.enumerateAttributes(
      in: NSMakeRange(0, attribute.length),
      options: []
    ) { dics, _, _ in
      if let neAttachment = dics[NSAttributedString.Key.attachment] as? NEEmotionAttachment,
         let tagCount = neAttachment.emotion?.tag?.count {
        count += tagCount - 1
      }
    }
    return count
  }

  /// 比较两个 UIColor 是否完全相同（RGBA 分量逐一对比）
  private func isEqualToColor(_ color1: UIColor, _ color2: UIColor) -> Bool {
    guard let c1 = color1.cgColor.components,
          let c2 = color2.cgColor.components,
          color1.cgColor.colorSpace == color2.cgColor.colorSpace,
          color1.cgColor.numberOfComponents == 4,
          color2.cgColor.numberOfComponents == 4 else { return false }
    return c1[0] == c2[0] && c1[1] == c2[1] && c1[2] == c2[2] && c1[3] == c2[3]
  }

  public func setVisitorModel(isVisitorMode: Bool) {
    for button in buttons {
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
