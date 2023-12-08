
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

public protocol QChatAnncCellDelegate: NSObjectProtocol {
  func didClickRemove(index: Int)
}

open class QChatAnncMemberCell: QChatMemberManagerCell {
  public weak var deletate: QChatAnncCellDelegate?

  public var indexRow = 0

  public var nameLabelRight: NSLayoutConstraint?

  // 移除标签
  lazy var removeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 12)
    label.textColor = .ne_redText
    label.clipsToBounds = true
    label.layer.cornerRadius = 4
    label.layer.borderColor = UIColor.ne_redText.cgColor
    label.layer.borderWidth = 1
    label.backgroundColor = .white
    label.textAlignment = .center
    label.text = localizable("qchat_remove")
    return label
  }()

  // 移除按钮
  lazy var removeBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    button.addTarget(self, action: #selector(removeDidClick), for: .touchUpInside)
    return button
  }()

  override open func setupNameLabel() {
    contentView.addSubview(removeBtn)
    NSLayoutConstraint.activate([
      removeBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      removeBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      removeBtn.topAnchor.constraint(equalTo: contentView.topAnchor),
      removeBtn.widthAnchor.constraint(equalToConstant: 70),
    ])

    contentView.addSubview(nameLabel)
    nameLabelRight = nameLabel.rightAnchor.constraint(equalTo: removeBtn.leftAnchor)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
      nameLabelRight!,
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  override open func setupTailorImage() {
    contentView.addSubview(removeLabel)
    NSLayoutConstraint.activate([
      removeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      removeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      removeLabel.widthAnchor.constraint(equalToConstant: 40.0),
      removeLabel.heightAnchor.constraint(equalToConstant: 22.0),
    ])
  }

  func configure(user: ServerMemeber) {
    headView.configHeadData(headUrl: user.avatar, name: user.nick ?? "", uid: user.accid ?? "")
    nameLabel.text = (user.nick?.count ?? 0) > 0 ? user.nick : user.accid
  }

  @objc func removeDidClick() {
    deletate?.didClickRemove(index: indexRow)
  }

  func setIsShowRemove(isShow: Bool) {
    removeBtn.isHidden = !isShow
    removeLabel.isHidden = !isShow
    if isShow {
      nameLabelRight?.constant = 0
    } else {
      nameLabelRight?.constant = -40
    }
  }
}
