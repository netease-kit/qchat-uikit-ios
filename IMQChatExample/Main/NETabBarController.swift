
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NEContactUIKit
import NEConversationUIKit
import NECoreIMKit
import NECoreKit
import NECoreQChatKit
import NEQChatUIKit
import NETeamUIKit
import NIMSDK
import NIMQChat
import UIKit

class NETabBarController: UITabBarController {
  private var sessionUnreadCount = 0
  private var contactUnreadCount = 0
  private var serverUnreadCount: UInt = 0

  private var qchatHomeController: QChatHomeViewController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpControllers()
    setUpSessionBadgeValue()
    setUpContactBadgeValue()
    NIMSDK.shared().conversationManager.add(self)
    NIMSDK.shared().systemNotificationManager.add(self)
  }

  func setUpControllers() {
    // chat
    let chat = ConversationController()
    chat.tabBarItem = UITabBarItem(
      title: NSLocalizedString("message", comment: ""),
      image: UIImage(named: "chat"),
      selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
    )
    let chatNav = NENavigationController(rootViewController: chat)

    // qchat
    let qchat = QChatHomeViewController()
    qchatHomeController = qchat
    qchat.delegate = self
    qchat.tabBarItem = UITabBarItem(
      title: NSLocalizedString("qchat", comment: ""),
      image: UIImage(named: "qchat"),
      selectedImage: UIImage(named: "qchatSelect")?.withRenderingMode(.alwaysOriginal)
    )
    let qChatNav = NENavigationController(rootViewController: qchat)

    let square = QChatSquareHomeViewController()
    square.delegate = self
    square.tabBarItem = UITabBarItem(
      title: NSLocalizedString("square", comment: ""),
      image: UIImage(named: "squareSelect"),
      selectedImage: UIImage(named: "squareSelect")?.withRenderingMode(.alwaysOriginal)
    )
    let squareNav = NENavigationController(rootViewController: square)

    // Contacts
    let contactVC = ContactsViewController()
    contactVC.tabBarItem = UITabBarItem(
      title: NSLocalizedString("contact", comment: ""),
      image: UIImage(named: "contact"),
      selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
    )
    let title = UIBarButtonItem(title: NSLocalizedString("contact", comment: ""), style: .plain, target: nil, action: nil)
    title.isEnabled = false
    title.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black,
                                  NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)], for: .disabled)
    contactVC.navigationItem.setLeftBarButton(title, animated: false)
    let contactsNav = NENavigationController(rootViewController: contactVC)

    // Me
    let meVC = MeViewController()
    meVC.tabBarItem = UITabBarItem(
      title: NSLocalizedString("mine", comment: ""),
      image: UIImage(named: "person"),
      selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal)
    )
    let meNav = NENavigationController(rootViewController: meVC)

    tabBar.isTranslucent = false
    tabBar.backgroundColor = UIColor(hexString: "#F6F8FA")
    tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
    viewControllers = [chatNav, qChatNav, squareNav, contactsNav, meNav]
    viewControllers?.forEach { vc in
      vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
      vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
    }
    selectedIndex = 0
  }

  func setUpSessionBadgeValue() {
    sessionUnreadCount = ConversationProvider.shared.allUnreadCount(notify: true)
    if sessionUnreadCount > 0 {
      tabBar.setRedDotView(index: 0)
    } else {
      tabBar.hideRedDocView(index: 0)
    }
  }

  func setUpContactBadgeValue() {
    contactUnreadCount = NIMSDK.shared().systemNotificationManager.allUnreadCount()
    if contactUnreadCount > 0 {
      tabBar.setRedDotView(index: 3)
    } else {
      tabBar.hideRedDocView(index: 3)
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  func setupServerBadge() {
    if serverUnreadCount > 0 {
      // tabBar.showBadgOn(index: 1, tabbarItemNums: 5)
      if serverUnreadCount > 99 {
        tabBar.setServerBadge(count: "99+")
      } else {
        tabBar.setServerBadge(count: "\(serverUnreadCount)")
      }
    } else {
      tabBar.setServerBadge(count: nil)
    }
  }

  deinit {
    NIMSDK.shared().systemNotificationManager.remove(self)
    NIMSDK.shared().conversationManager.remove(self)
  }
}

extension NETabBarController: NIMConversationManagerDelegate {
  func didAdd(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }

  func didUpdate(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }

  func didRemove(_ recentSession: NIMRecentSession, totalUnreadCount: Int) {
    refreshSessionBadge()
  }
}

extension NETabBarController: NIMSystemNotificationManagerDelegate {
  func onSystemNotificationCountChanged(_ unreadCount: Int) {
    contactUnreadCount = unreadCount
    setUpContactBadgeValue()
  }
}

extension NETabBarController: QChatServerDelegate {
  func serverUnReadTotalCountChange(count: UInt) {
    serverUnreadCount = count
    print("serverUnReadTotalCountChange : ", count)
    setupServerBadge()
  }
}

extension NETabBarController: SquareDataSourceDelegate {
  func requestSquareSearchType(_ completion: @escaping ([QChatSquarePageInfo], NSError?) -> Void) {
    DemoService.getSearchTypeData { error, result in
      var infos = [QChatSquarePageInfo]()
      if let datas = result?.originData?["data"] as? [Any] {
        for item in datas {
          let info = QChatSquarePageInfo()
          if let dic = item as? [String: Any] {
            if let type = dic["type"] as? Int {
              info.type = type
            }
            if let title = dic["title"] as? String {
              info.title = title
            }
          }
          infos.append(info)
        }
        completion(infos, error as NSError?)
      } else {
        completion(infos, error as NSError?)
      }
    }
  }

  func requestServerInfoForSearchType(_ searchType: Int, _ completion: @escaping ([QChatSquareServer], NSError?) -> Void) {
    DemoService.getSquareData(searchType: searchType) { error, result in
      print("requestServerInfoForSearchType ", result?.originData as Any)
      var servers = [QChatSquareServer]()

      if let datas = result?.originData?["data"] as? [Any] {
        for item in datas {
          let imServer = NIMQChatServer()
          if let dic = item as? [String: Any] {
            if let sid = dic["serverId"] as? String, let id = UInt64(sid) {
              imServer.serverId = id
            }
            if let name = dic["serverName"] as? String {
              imServer.name = name
            }
            if let icon = dic["icon"] as? String {
              imServer.icon = icon
            }

            if let custom = dic["custom"] as? String {
              imServer.custom = custom
            }
          }
          let server = NEQChatServer(server: imServer)
          let squareServer = QChatSquareServer()
          squareServer.server = server
          servers.append(squareServer)
        }
        completion(servers, error as NSError?)
      } else {
        completion(servers, error as NSError?)
      }
    }
  }

  func didSelectSquareServer(server: QChatSquareServer) {
    // 切换圈组社区列表所在tab
    guard let server = server.server else {
      return
    }
    selectedIndex = 1
    qchatHomeController?.setCurrentServer(server: server)
  }
}
