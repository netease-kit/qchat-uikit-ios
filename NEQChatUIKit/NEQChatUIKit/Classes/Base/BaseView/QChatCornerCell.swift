
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit

// this cell has rounding corner style
import UIKit

open class QChatCornerCell: CornerCell {
  open func configure(model: QChatSettingModel) {
    cornerType = model.cornerType
  }
}
