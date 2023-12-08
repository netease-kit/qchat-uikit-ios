
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc protocol QChatTextEditCellDelegate: AnyObject {
//  @objc optional func textFieldDidChangeSelection(cell: QChatTextEditCell,
//                                                  _ textField: UITextField)
  @objc optional func textDidChange(_ textField: UITextField)
}

class QChatTextEditCell: QChatCornerCell, UITextFieldDelegate {
  var limit: Int?
  var canEdit = true
  var editTotast = ""
  public lazy var textFied: UITextField = {
    let text = UITextField()
    text.textColor = .ne_darkText
    text.font = UIFont.systemFont(ofSize: 16)
    text.clearButtonMode = .whileEditing
    text.translatesAutoresizingMaskIntoConstraints = false
    text.addTarget(self, action: #selector(textFieldChange), for: .editingChanged)
    return text
  }()

  public weak var delegate: QChatTextEditCellDelegate?
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    contentView.addSubview(textFied)
    NSLayoutConstraint.activate([
      textFied.leftAnchor.constraint(equalTo: leftAnchor, constant: 36),
      textFied.topAnchor.constraint(equalTo: topAnchor),
      textFied.bottomAnchor.constraint(equalTo: bottomAnchor),
      textFied.rightAnchor.constraint(equalTo: rightAnchor, constant: -36),
    ])
    textFied.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  func textFieldChange() {
    guard let _ = textFied.markedTextRange else {
      if let d = delegate {
        d.textDidChange?(textFied)
      }
      return
    }
  }

  // MAKR: UITextFieldDelegate

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if canEdit == false, editTotast.count > 0 {
      UIApplication.shared.keyWindow?.makeToast(editTotast)
    }
    return canEdit
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let lim = limit, let text = textField.text {
      let newText = (text as NSString).replacingCharacters(in: range, with: string)
      if newText.utf16.count > lim {
        return false
      }
    }
    return true
  }
}
