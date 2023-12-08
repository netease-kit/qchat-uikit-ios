
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit

// 社区下成员列表数据模型
@objcMembers
public class QChatServerMemberModel: NSObject {
  public var serverMemberModel: ServerMemeber?
  public var imName: String?
  public var idGroupData: [String]?
}
