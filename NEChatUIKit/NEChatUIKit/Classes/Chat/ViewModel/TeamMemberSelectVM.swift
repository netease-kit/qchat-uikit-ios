// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import NEChatKit
import NECoreIMKit
@objcMembers
public class TeamMemberSelectVM: NSObject {
  public var chatRepo: ChatRepo = .init()
  private let className = "TeamMemberSelectVM"

  public func fetchTeamMembers(sessionId: String,
                               _ completion: @escaping (Error?, ChatTeamInfoModel?) -> Void) {
    NELog.infoLog(ModuleName + " " + className, desc: #function + ", sessionId: " + sessionId)
    chatRepo.getTeamInfo(sessionId, completion)
  }
}
