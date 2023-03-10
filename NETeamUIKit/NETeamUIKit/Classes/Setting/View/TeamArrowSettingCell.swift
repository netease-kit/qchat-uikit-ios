
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class TeamArrowSettingCell: BaseTeamSettingCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func configure(_ anyModel: Any) {
    super.configure(anyModel)
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    contentView.addSubview(arrow)
    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
  }
}
