
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatUserUnCheckCell: QChatBaseCollectionViewCell {
  public var avatarImage = NEUserHeaderView(frame: .zero)
  public var nameTailLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(avatarImage)
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImage.widthAnchor.constraint(equalToConstant: 36),
      avatarImage.heightAnchor.constraint(equalToConstant: 36),
    ])
    avatarImage.layer.cornerRadius = 18.0
    avatarImage.clipsToBounds = true

    avatarImage.addSubview(nameTailLabel)
    nameTailLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      nameTailLabel.centerXAnchor.constraint(equalTo: avatarImage.centerXAnchor),
      nameTailLabel.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
      nameTailLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor, constant: 1),
      nameTailLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: -1),
    ])
    nameTailLabel.font = UIFont.systemFont(ofSize: 16.0)
    nameTailLabel.textAlignment = .center
    nameTailLabel.textColor = .white

    contentView.backgroundColor = .clear
  }

  func configure(_ model: QChatUserInfo) {
    if let avatar = model.avatar, !avatar.isEmpty {
      avatarImage.sd_setImage(with: URL(string: avatar))
      nameTailLabel.text = ""
    } else {
      avatarImage.sd_setImage(with: nil)
      avatarImage.backgroundColor = model.color
      guard let name = model.nickName else { return }
      nameTailLabel.text = name
        .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
    }
  }
}
