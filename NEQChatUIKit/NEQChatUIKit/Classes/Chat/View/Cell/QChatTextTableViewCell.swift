
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEQChatKit
import UIKit

class QChatTextTableViewCell: QChatBaseTableViewCell {
  let reeditMargin: CGFloat = 8

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  override public var messageFrame: QChatMessageFrame? {
    didSet {
      textView.attributedText = messageFrame?.attributeStr
      textView.frame = CGRect(
        x: messageFrame?.startX ?? 0,
        y: 0,
        width: (messageFrame?.contentSize.width ?? 0) - qChat_angle_w,
        height: contentBtn.height -
          (quickCommentCollection.height > 0 ? quickCommentCollection.height + qChat_margin : 0)
      )
      let textFrame = textView.frame

      reeditButton.isHidden = true
      if messageFrame?.isRevoked == true,
         let msg = messageFrame?.message {
        textView.textColor = UIColor.ne_greyText

        // 不是自己发的消息不可重新编辑
        // 非文本消息不可重新编辑
        // 本地无撤回原文本则不可编辑
        // 超出重新编辑期限则不可编辑
        guard msg.isOutgoingMsg,
              msg.messageType == .text,
              Date().timeIntervalSince1970 - msg.timestamp < 2 * 60,
              UserDefaults.standard.value(forKey: msg.serverID) != nil
        else {
          return
        }

        reeditButton.isHidden = false

        let oldFrame = contentBtn.frame
        let reeditViewWidth = 82 + reeditMargin
        contentBtn.frame = CGRect(x: oldFrame.origin.x - reeditViewWidth,
                                  y: oldFrame.origin.y,
                                  width: oldFrame.width + reeditViewWidth,
                                  height: oldFrame.height)
        reeditButton.frame = CGRect(x: textFrame.origin.x + textFrame.width + reeditMargin,
                                    y: textFrame.origin.y,
                                    width: reeditViewWidth,
                                    height: textFrame.height)
      } else {
        textView.textColor = UIColor.ne_darkText
      }
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var textView: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = DefaultTextFont(16)
    self.contentBtn.addSubview(label)
    return label
  }()

  private lazy var reeditButton: UIButton = {
    let button = UIButton()
    button.isHidden = true
    button.setTitle(localizable("message_reedit"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    button.setTitleColor(UIColor.ne_blueText, for: .normal)
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -30, bottom: 0, right: 0)

    button.setImage(UIImage.ne_imageNamed(name: "right_arrow"), for: .normal)
    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 0)

    button.addTarget(self, action: #selector(reeditAction), for: .touchUpInside)

    self.contentBtn.addSubview(button)

    return button
  }()

  @objc func reeditAction() {
    delegate?.didTapReeditButton(self, messageFrame)
  }
}

// class QChatTextView: UITextView {
//  override init(frame: CGRect, textContainer: NSTextContainer?) {
//    super.init(frame: frame, textContainer: textContainer)
//    setupUI()
//  }
//
//  public required init?(coder aDecoder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  func setupUI() {
//    backgroundColor = .clear
//    textContainer.lineFragmentPadding = 0
//    textContainerInset = .zero
//    dataDetectorTypes = .all
//    autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    font = DefaultTextFont(16)
//  }
//
//  override var textContainerInset: UIEdgeInsets {
//    set {
//      let padding = textContainer.lineFragmentPadding
//      super.textContainerInset = UIEdgeInsets(
//        top: newValue.top,
//        left: newValue.left - padding,
//        bottom: newValue.bottom,
//        right: newValue.right - padding
//      )
//    }
//    get {
//      super.textContainerInset
//    }
//  }
// }
