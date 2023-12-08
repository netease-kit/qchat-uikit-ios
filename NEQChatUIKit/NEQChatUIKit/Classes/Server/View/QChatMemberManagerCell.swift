
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

open class QChatMemberManagerCell: QChatIdGroupMemberCell {
  override func setupUI() {
    super.setupUI()
    contentView.backgroundColor = .white
    line.isHidden = false
    leftSpace?.constant = 20
    rightSpace?.constant = -20
  }
}
