
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class QChatTextArrowCell: QChatTextCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    rightStyle = .indicate
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func configure(model: QChatSettingModel) {
    super.configure(model: model)
    titleLabel.text = model.title
    detailLabel.text = model.detailLabel
  }
}
