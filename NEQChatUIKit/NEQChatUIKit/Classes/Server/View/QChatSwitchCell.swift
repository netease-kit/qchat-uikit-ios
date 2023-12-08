
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol QChatSwitchCellDelegate: AnyObject {
  func didChangeSwitchValue(_ cell: QChatSwitchCell)
}

class QChatSwitchCell: QChatCornerCell {
  weak var delegate: QChatSwitchCellDelegate?

  var qSwitch: UISwitch = {
    let q = UISwitch()
    q.translatesAutoresizingMaskIntoConstraints = false
    q.onTintColor = .ne_blueText
    return q
  }()

  var leftLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_darkText
    label.font = DefaultTextFont(16)
    return label
  }()

  var model: QChatSettingModel? {
    didSet {
      leftLabel.text = model?.title

      if let type = model?.cornerType {
        cornerType = type
      }
      if let model = model as? QChatPermissionCellModel {
        qSwitch.isOn = model.hasPermission
      }
    }
  }

  override func configure(model: QChatSettingModel) {
    super.configure(model: model)
    self.model = model
    leftLabel.text = model.title
    qSwitch.isOn = model.switchOpen
  }

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
    contentView.addSubview(qSwitch)
    NSLayoutConstraint.activate([
      qSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      qSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
    qSwitch.addTarget(self, action: #selector(valueChange(_:)), for: .valueChanged)

    contentView.addSubview(leftLabel)
    NSLayoutConstraint.activate([
      leftLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      leftLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -95),
      leftLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  @objc func valueChange(_ s: UISwitch) {
    if let model = model as? QChatPermissionCellModel {
      model.hasPermission = s.isOn
    }
    if let block = model?.swichChange {
      block(s.isOn)
      return
    }
    delegate?.didChangeSwitchValue(self)
  }
}
