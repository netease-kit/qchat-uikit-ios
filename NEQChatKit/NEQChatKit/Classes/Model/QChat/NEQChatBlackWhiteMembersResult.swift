
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat

public struct NEQChatBlackWhiteMembersResult {
  public var memberArray = [NEQChatServerMemeber]()

  init(result: NIMQChatGetExistingChannelBlackWhiteMembersResult?) {
    if let members = result?.memberArray {
      for member in members {
        memberArray.append(NEQChatServerMemeber(member))
      }
    }
  }
}
