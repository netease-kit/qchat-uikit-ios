
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
public class QChatPermissionCellModel: QChatSettingModel {
  weak var permission: QChatPermissionModel?
  var permissionKey: String?
  var hasPermission = false
}
