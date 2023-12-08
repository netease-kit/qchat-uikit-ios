//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatAnncMemberManagerCell: QChatAnncMemberCell {
  // 管理员标签
  lazy var adminLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 12)
    label.textColor = .ne_adminLabelTextColor
    label.clipsToBounds = true
    label.layer.cornerRadius = 11
    label.layer.borderColor = UIColor.ne_adminLabelBorderColor.cgColor
    label.layer.borderWidth = 1
    label.backgroundColor = .ne_adminLabelBackColor
    label.textAlignment = .center
    return label
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override func setupNameLabel() {}

  override func setupUI() {
    super.setupUI()
    setupCommonUI()
  }

  func setupCommonUI() {
    contentView.addSubview(removeBtn)
    NSLayoutConstraint.activate([
      removeBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      removeBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      removeBtn.topAnchor.constraint(equalTo: contentView.topAnchor),
      removeBtn.widthAnchor.constraint(equalToConstant: 70),
    ])

    contentView.addSubview(nameLabel)
    nameLabelRight = nameLabel.rightAnchor.constraint(lessThanOrEqualTo: removeBtn.leftAnchor, constant: -62)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headView.rightAnchor, constant: 12),
      nameLabelRight!,
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    contentView.addSubview(adminLabel)
    NSLayoutConstraint.activate([
      adminLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
      adminLabel.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 5),
      adminLabel.widthAnchor.constraint(equalToConstant: 52),
      adminLabel.heightAnchor.constraint(equalToConstant: 22),
    ])
  }

  override func setIsShowRemove(isShow: Bool) {
    super.setIsShowRemove(isShow: isShow)
    if isShow {
      nameLabelRight?.constant = -62
    } else {
      nameLabelRight?.constant = -2
    }
  }
}
