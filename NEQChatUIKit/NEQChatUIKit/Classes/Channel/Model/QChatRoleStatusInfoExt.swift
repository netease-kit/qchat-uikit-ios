
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit

public struct QChatRoleStatusInfoExt {
  public var status: NEQChatPermissionStatusInfo?
  public var title: String?

  public init(status: NEQChatPermissionStatusInfo?) {
    self.status = status
  }
}
