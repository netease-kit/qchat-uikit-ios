// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// @ 消息在服务端扩展字段中存储范围信息的模型（对标 NEChatUIKit 的 MessageAtInfoModel）
@objcMembers
public class QChatMessageAtInfoModel: NSObject {
  public var start = 0
  public var end = 0
  public var broken = false
}
