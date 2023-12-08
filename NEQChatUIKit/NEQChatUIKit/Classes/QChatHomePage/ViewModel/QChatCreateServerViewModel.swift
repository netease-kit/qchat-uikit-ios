//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreQChatKit
import NEQChatKit
import UIKit

@objcMembers
public class QChatCreateServerViewModel: NSObject {
  let repo = QChatRepo.shared

  public lazy var dataArray: [(String, String)] = {
    let array = [
      ("mine_create", localizable("qchat_mine_add")),
      ("addOther_icon", localizable("qchat_join_otherServer")),
      ("create_public_server", localizable("qchat_create_public_server")),
      ("join_public_server", localizable("qchat_join_public_server")),
    ]
    return array
  }()

  public func inviteMembersToServer(serverId: UInt64, accids: [String],
                                    _ completion: @escaping (NSError?) -> Void) {
    let param = QChatInviteServerMembersParam(serverId: serverId, accids: accids)
    repo.inviteMembersToServer(param) { error in
      completion(error)
    }
  }
}
