
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMQChat
import NIMSDK

public enum NEQChatLoginAuthType: Int {
  case theDefault = 0
  case dynamicToken = 1
}

public typealias NEQChatCallBack = (_ str: String) -> String

@objcMembers
public class NEQChatLoginParam: NSObject {
  public var account: String
  public var token: String?
  public var option: V2NIMLoginOption?

  public init(_ account: String, _ token: String?) {
    self.account = account
    self.token = token
  }

  func toIMParam() -> NIMQChatLoginParam {
    let imParam = NIMQChatLoginParam()

    imParam.dynamicTokenHandler = { account -> String in
      guard let token = self.token else {
        return ""
      }
      return token
    }
    switch option?.authType {
    case .LOGIN_AUTH_TYPE_DYNAMIC_TOKEN:
      imParam.authType = .dynamicToken
    default:
      imParam.authType = .default
    }

//        imParam.loginExt = self.loginExt
    return imParam
  }
}
