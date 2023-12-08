
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public enum OperationType: Int {
  case copy = 1
  case reply
  case forward
  case pin
  case removePin
  case multiSelect
  case collection
  case delete
  case recall
}

@objcMembers
public class QChatOperationItem: NSObject {
  public var text: String = ""
  public var imageName: String = ""
  public var type: OperationType?

  static func copyItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_copy")
    item.imageName = "op_copy"
    item.type = .copy
    return item
  }

  static func replayItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_replay")
    item.imageName = "op_replay"
    item.type = .reply
    return item
  }

  static func forwardItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_forward")
    item.imageName = "op_forward"
    item.type = .forward
    return item
  }

  static func pinItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_pin")
    item.imageName = "op_pin"
    item.type = .pin
    return item
  }

  static func removePinItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_cancel_pin")
    item.imageName = "op_pin"
    item.type = .removePin
    return item
  }

//  static func selectItem() -> QChatOperationItem {
//    QChatOperationItem(
//      text: localizable("operation_select"),
//      imageName: "op_select",
//      type: .multiSelect
//    )
//  }

//  static func collectionItem() -> QChatOperationItem {
//    QChatOperationItem(
//      text: localizable("operation_collection"),
//      imageName: "op_collection",
//      type: .collection
//    )
//  }

  static func deleteItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_delete")
    item.imageName = "op_delete"
    item.type = .delete
    return item
  }

  static func recallItem() -> QChatOperationItem {
    let item = QChatOperationItem()
    item.text = localizable("operation_recall")
    item.imageName = "op_recall"
    item.type = .recall
    return item
  }
}
