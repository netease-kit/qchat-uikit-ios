// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
public class ConversationSearchViewModel: NSObject {
  let repo = ConversationRepo()
  public var searchResult: (
    friend: [ConversationSearchListModel],
    contactGroup: [ConversationSearchListModel],
    seniorGroup: [ConversationSearchListModel]
  )?
  private let className = "ConversationSearchViewModel"

  override public init() {
    super.init()
  }

  /// 请求接口
  /// - Parameters:
  ///   - searchStr: 搜索的内容
  ///   - completion: 回调结果
  public func doSearch(searchStr: String,
                       _ completion: @escaping (NSError?, (
                         friend: [ConversationSearchListModel],
                         contactGroup: [ConversationSearchListModel],
                         seniorGroup: [ConversationSearchListModel]
                       )?) -> Void) {
    NELog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", searchStr.count:\(searchStr.count)"
    )
    weak var weakSelf = self
    repo.searchContact(searchStr: searchStr) { error, searchResult in
      weakSelf?.searchResult = searchResult
      completion(error, searchResult)
    }
  }
}
