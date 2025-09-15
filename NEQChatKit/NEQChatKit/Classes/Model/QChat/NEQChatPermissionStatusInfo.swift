
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public enum NEQChatPermissionStatus: Int {
  case Deny = -1, Extend, Allow
}

public struct NEQChatPermissionStatusInfo {
  public var customType: Int?
  public var permissionType: NEQChatPermissionType?
  public var status: NEQChatPermissionStatus = .Extend

  public init(customtype: Int = 0, type: NEQChatPermissionType? = nil, status: NEQChatPermissionStatus = .Extend) {
    customType = customtype
    permissionType = type
    self.status = status
  }

  init(info: NIMQChatPermissionStatusInfo) {
    customType = info.customType
    permissionType = info.type.convertType()
    switch info.status {
    case .deny:
      status = .Deny
    case .extend:
      status = .Extend
    case .allow:
      status = .Allow
    default:
      status = .Deny
    }
  }
}
