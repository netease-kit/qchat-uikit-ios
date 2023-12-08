
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatDestructiveCell: QChatCornerCell {
  lazy var redTextLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_redText
    label.font = DefaultTextFont(16)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
    setupUI()
  }

  func setupUI() {
    contentView.backgroundColor = .clear
    backgroundColor = .clear
    contentView.addSubview(redTextLabel)
    NSLayoutConstraint.activate([
      redTextLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      redTextLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      redTextLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      redTextLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  override func configure(model: QChatSettingModel) {
    super.configure(model: model)
    redTextLabel.text = model.title
  }

  func changeDisableTextColor() {
    redTextLabel.textColor = .ne_disableRedText
  }

  func changeEnableTextColor() {
    redTextLabel.textColor = .ne_redText
  }
}
