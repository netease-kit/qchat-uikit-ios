
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class SettingModel: NSObject {
  var title: String?
  var cornerType: CornerType = .bottomLeft.union(CornerType.bottomRight)
    .union(CornerType.topLeft).union(CornerType.topRight)
}
