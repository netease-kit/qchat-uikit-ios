
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public enum QChatSettingCellType: Int {
  case SettingTextCell = 0
  case SettingArrowCell
  case SettingDestructiveCell
  case SettingSwitchCell
}

@objcMembers
public class QChatSettingModel: NSObject {
  public typealias SwitchChangeCompletion = (Bool) -> Void
  public typealias CellClick = () -> Void

  var title: String?
  var detailLabel: String?
  var cornerType: CornerType = .bottomLeft.union(CornerType.bottomRight)
    .union(CornerType.topLeft).union(CornerType.topRight)
  public var type = QChatSettingCellType.SettingArrowCell.rawValue
  public var switchOpen = false
  public var swichChange: SwitchChangeCompletion?
  public var cellClick: CellClick?
}
