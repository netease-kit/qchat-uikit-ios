
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class QChatTextCell: QChatStateCell {
  public var titleLabel: UILabel = .init()
  public var detailLabel: UILabel = .init()

  var titleLeftMargin: NSLayoutConstraint?

  var detailRightMargin: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.textColor = .ne_darkText
    contentView.addSubview(titleLabel)
    titleLeftMargin = titleLabel.leftAnchor.constraint(
      equalTo: contentView.leftAnchor,
      constant: 36
    )
    titleLeftMargin?.isActive = true
    NSLayoutConstraint.activate([
      //            self.titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    titleLabel.text = localizable("delete")

    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.textColor = .ne_lightText
    contentView.addSubview(detailLabel)

    detailRightMargin = detailLabel.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -60
    )
    detailRightMargin?.isActive = true
    NSLayoutConstraint.activate([
      detailLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 0),
      detailLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 40),
      detailLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    detailLabel.textAlignment = .right
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
