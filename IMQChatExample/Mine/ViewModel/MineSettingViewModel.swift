
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreQChatKit
import NETeamUIKit

public protocol MineSettingViewModelDelegate: NSObjectProtocol {
  func didMessageRemindClick()
  func didClickCleanCache()
  func didClickConfigTest()
}

@objcMembers
public class MineSettingViewModel: NSObject {
  var sectionData = [SettingSectionModel]()
  weak var delegate: MineSettingViewModelDelegate?

  public func getData() {
    sectionData.append(getFirstSection())
    sectionData.append(getSecondSection())
  }

  private func getFirstSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    weak var weakSelf = self
//    let remind = SettingCellModel()
//    remind.cellName = NSLocalizedString("message_remind", comment: "")
//    remind.type = SettingCellType.SettingArrowCell.rawValue
//    remind.cellClick = {
//      weakSelf?.delegate?.didMessageRemindClick()
//    }
//    model.cellModels.append(remind)

//        let cleanCache = SettingCellModel()
//        cleanCache.cellName = "清理缓存"
//        cleanCache.type = SettingCellType.SettingArrowCell.rawValue
//        cleanCache.cellClick = {
//            weakSelf?.delegate?.didClickCleanCache()
//        }
//        model.cellModels.append(contentsOf: [remind, cleanCache])

    #if DEBUG
      let configTest = SettingCellModel()
      configTest.cellName = "配置测试页"
      configTest.type = SettingCellType.SettingArrowCell.rawValue
      configTest.cellClick = {
        weakSelf?.delegate?.didClickConfigTest()
      }
      model.cellModels.append(configTest)
    #endif

    model.setCornerType()
    return model
  }

  private func getSecondSection() -> SettingSectionModel {
    let model = SettingSectionModel()
    // 听筒模式
    let receiverModel = SettingCellModel()
    receiverModel.cellName = NSLocalizedString("receiver_mode", comment: "")
    receiverModel.type = SettingCellType.SettingSwitchCell.rawValue
//        receiverModel.switchOpen = CoreKitEngine.instance.repo.getHandSetMode()
    receiverModel.switchOpen = QChatKitClient.instance.getSettingRepo().getHandsetMode()

    receiverModel.swichChange = { isOpen in
      QChatKitClient.instance.getSettingRepo().setHandsetMode(isOpen)
    }
//        //过滤通知
//        let filterNotify = SettingCellModel()
//        filterNotify.cellName = "过滤通知"
//        filterNotify.type = SettingCellType.SettingSwitchCell.rawValue
//        //filterNotify.switchOpen = true
//
//        filterNotify.swichChange = { isOpen in
//
//        }

    // 删除好友是否同步删除备注
//    let deleteFriend = SettingCellModel()
//    deleteFriend.cellName = NSLocalizedString("delete_friend", comment: "")
//    deleteFriend.type = SettingCellType.SettingSwitchCell.rawValue
//    deleteFriend.switchOpen = QChatKitClient.instance.getSettingRepo().getDeleteFriendAlias()
//
//    deleteFriend.swichChange = { isOpen in
//      QChatKitClient.instance.getSettingRepo().setDeleteFriendAlias(isOpen)
//    }

    // 消息已读未读功能
    let hasRead = SettingCellModel()
    hasRead.cellName = NSLocalizedString("message_read_function", comment: "")
    hasRead.type = SettingCellType.SettingSwitchCell.rawValue
//        hasRead.switchOpen = true
    hasRead.switchOpen = QChatKitClient.instance.getSettingRepo().getShowReadStatus()
    hasRead.swichChange = { isOpen in
      QChatKitClient.instance.getSettingRepo().setShowReadStatus(isOpen)
    }
    model.cellModels.append(contentsOf: [receiverModel, hasRead])

    model.setCornerType()
    return model
  }
}
