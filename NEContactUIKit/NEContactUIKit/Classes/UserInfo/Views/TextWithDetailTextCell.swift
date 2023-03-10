
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
@objcMembers
public class TextWithDetailTextCell: ContactBaseTextCell {
  public var detailTitleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    detailTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    detailTitleLabel.font = UIFont.systemFont(ofSize: 12)
    detailTitleLabel.textColor = UIColor(hexString: "#A6ADB6")
    contentView.addSubview(detailTitleLabel)
    NSLayoutConstraint.activate([
      detailTitleLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 20),
      detailTitleLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -20
      ),
      detailTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      detailTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
