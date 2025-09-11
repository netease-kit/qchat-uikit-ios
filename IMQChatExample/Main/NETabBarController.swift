// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NEContactUIKit
import NEConversationUIKit
import NELocalConversationUIKit
import NEQChatUIKit
import NIMQChat
import NIMSDK
import UIKit

class NETabBarController: UITabBarController {
  private var chat = UIViewController()
  private var qchatVC = QChatHomeViewController()
  private var squareVC = QChatSquareHomeViewController()
  private var contactVC = NEBaseContactViewController()
  private var meVC = MeViewController()

  private var sessionUnreadCount = 0
  private var contactUnreadCount = 0
  private var serverUnreadCount: UInt = 0

  /// 是通过切换UI风格触发，需要重置会话是否同步完成标志位，因为不是首次登录，已经同步过，同步完成回调不会再触发，正常单皮肤可忽略此逻辑
  public var isChangeUIType = false {
    didSet {}
  }

  public init(_ isChangeUI: Bool) {
    isChangeUIType = isChangeUI
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    TeamRepo.shared.addTeamListener(self)
    setUpControllers()
    setUpSessionBadgeValue()
    setUpContactBadgeValue()

    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      LocalConversationRepo.shared.addLocalConversationListener(self)
    } else {
      ConversationRepo.shared.addConversationListener(self)
    }

    NotificationCenter.default.addObserver(self, selector: #selector(clearValidationUnreadCount), name: NENotificationName.clearValidationMessageUnreadCount, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeLanguage), name: NENotificationName.changeLanguage, object: nil)
  }

  @objc func changeLanguage() {
    chat.tabBarItem.title = localizable("message")
    contactVC.tabBarItem.title = localizable("contact")
    meVC.tabBarItem.title = localizable("mine")
    qchatVC.tabBarItem.title = localizable("qchat")
    squareVC.tabBarItem.title = localizable("square")
  }

  deinit {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      LocalConversationRepo.shared.removeLocalConversationListener(self)
    } else {
      LocalConversationRepo.shared.removeLocalConversationListener(self)
    }

    ContactRepo.shared.removeContactListener(self)
    TeamRepo.shared.removeTeamListener(self)
    NotificationCenter.default.removeObserver(self)
  }

  func setUpControllers() {
    if NEStyleManager.instance.isNormalStyle() {
      // chat
      if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
        chat = LocalConversationController()
        (chat as? LocalConversationController)?.viewModel.syncFinished = isChangeUIType
      } else {
        chat = ConversationController()
        (chat as? ConversationController)?.viewModel.syncFinished = isChangeUIType
      }

      chat.tabBarItem = UITabBarItem(
        title: localizable("message"),
        image: UIImage(named: "chat"),
        selectedImage: UIImage(named: "chatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav = NENavigationController(rootViewController: chat)

      // qchat
      qchatVC.delegate = self
      qchatVC.tabBarItem = UITabBarItem(
        title: localizable("qchat"),
        image: UIImage(named: "qchat"),
        selectedImage: UIImage(named: "qchatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let qChatNav = NENavigationController(rootViewController: qchatVC)

      squareVC.delegate = self
      squareVC.tabBarItem = UITabBarItem(
        title: localizable("square"),
        image: UIImage(named: "squareSelect"),
        selectedImage: UIImage(named: "squareSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let squareNav = NENavigationController(rootViewController: squareVC)

      // Contacts
      contactVC = ContactViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: localizable("contact"),
        image: UIImage(named: "contact"),
        selectedImage: UIImage(named: "contactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      meVC.tabBarItem = UITabBarItem(
        title: localizable("mine"),
        image: UIImage(named: "person"),
        selectedImage: UIImage(named: "personSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
      meVC.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = UIColor(hexString: "#F6F8FA")
      viewControllers = [chatNav, qChatNav, squareNav, contactsNav, meNav]
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#337EFF")]
        tabBar.standardAppearance = appearance
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        viewControllers?.forEach { vc in
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#337EFF")], for: .selected)
        }
      }
    } else {
      // chat
      if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
        chat = FunLocalConversationController()
        (chat as? FunLocalConversationController)?.viewModel.syncFinished = isChangeUIType
      } else {
        chat = FunConversationController()
        (chat as? FunConversationController)?.viewModel.syncFinished = isChangeUIType
      }

      chat.tabBarItem = UITabBarItem(
        title: localizable("message"),
        image: UIImage(named: "funChat"),
        selectedImage: UIImage(named: "funChatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      chat.tabBarItem.accessibilityIdentifier = "id.conversation"
      let chatNav = NENavigationController(rootViewController: chat)

      // qchat
      qchatVC.delegate = self
      qchatVC.tabBarItem = UITabBarItem(
        title: localizable("qchat"),
        image: UIImage(named: "qchat"),
        selectedImage: UIImage(named: "qchatSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let qChatNav = NENavigationController(rootViewController: qchatVC)

      squareVC.delegate = self
      squareVC.tabBarItem = UITabBarItem(
        title: localizable("square"),
        image: UIImage(named: "squareSelect"),
        selectedImage: UIImage(named: "squareSelect")?.withRenderingMode(.alwaysOriginal)
      )
      let squareNav = NENavigationController(rootViewController: squareVC)

      // Contacts
      contactVC = FunContactViewController()
      contactVC.tabBarItem = UITabBarItem(
        title: localizable("contact"),
        image: UIImage(named: "funContact"),
        selectedImage: UIImage(named: "funContactSelect")?.withRenderingMode(.alwaysOriginal)
      )
      contactVC.tabBarItem.accessibilityIdentifier = "id.contact"
      let contactsNav = NENavigationController(rootViewController: contactVC)

      // Me
      meVC.tabBarItem = UITabBarItem(
        title: localizable("mine"),
        image: UIImage(named: "funPerson"),
        selectedImage: UIImage(named: "funPersonSelect")?.withRenderingMode(.alwaysOriginal)
      )
      meVC.tabBarItem.accessibilityIdentifier = "id.mine"
      let meNav = NENavigationController(rootViewController: meVC)

      tabBar.backgroundColor = UIColor(hexString: "#F6F6F6")
      tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
      viewControllers = [chatNav, qChatNav, squareNav, contactsNav, meNav]
      viewControllers?.forEach { vc in
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
        vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
      }
      selectedIndex = 0

      if #available(iOS 13.0, *) {
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hexString: "#C5C9D2")
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#999999")]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.ne_funTheme]
        tabBar.standardAppearance = appearance
      } else {
        tabBar.unselectedItemTintColor = UIColor(hexString: "#C5C9D2")
        viewControllers?.forEach { vc in
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#999999")], for: .normal)
          vc.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ne_funTheme], for: .selected)
        }
      }
    }
  }

  func setUpSessionBadgeValue() {
    if NIMSDK.shared().v2Option?.enableV2CloudConversation == false {
      sessionUnreadCount = LocalConversationRepo.shared.getTotalUnreadCount()
    } else {
      sessionUnreadCount = ConversationRepo.shared.getTotalUnreadCount()
    }

    if sessionUnreadCount > 0 {
      tabBar.showBadgOn(index: 0, tabbarItemNums: 5)
    } else {
      tabBar.hideBadg(on: 0)
    }
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

  // 设置通讯录未读显示状态
  func setUpContactBadgeValue() {
    ContactRepo.shared.getUnreadApplicationCount { [weak self] count, error in
      if IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
        let option = V2NIMTeamJoinActionInfoQueryOption()
        option.offset = 0
        option.limit = neTeamJoinActionPageLimit
        TeamRepo.shared.getTeamJoinActionInfoList(option) { result, error in
          if let actions = result?.infos {
            let unreadActions = actions.filter { $0.timestamp > neTeamJoinActionReadTime }
            self?.contactUnreadCount = count + unreadActions.count
          } else {
            self?.contactUnreadCount = count
          }

          // 显示红点
          if (self?.contactUnreadCount ?? 0) > 0 {
            self?.tabBar.showBadgOn(index: 3, tabbarItemNums: 5)
          } else {
            self?.tabBar.hideBadg(on: 3)
          }

          //      // 显示未读数
          //      self?.setupContactBadge(unreadCount: contactUnreadCount)
        }
      }
    }
  }

  // 设置通讯录显示未读数
  func setupContactBadge(unreadCount: Int) {
    if unreadCount > 0 {
      if unreadCount > 99 {
        tabBar.setServerBadge(count: "99+")
      } else {
        tabBar.setServerBadge(count: "\(unreadCount)")
      }
    } else {
      tabBar.setServerBadge(count: nil)
    }
  }

  private func refreshSessionBadge() {
    setUpSessionBadgeValue()
  }

  @objc open func clearValidationUnreadCount() {
    tabBar.hideBadg(on: 3)
  }
}

// MARK: - NEContactListener

extension NETabBarController: NEContactListener {
  func onFriendAddApplication(_ application: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }

  func onFriendAddRejected(_ rejectionInfo: V2NIMFriendAddApplication) {
    setUpContactBadgeValue()
  }
}

// MARK: - NETeamListener

extension NETabBarController: NETeamListener {
  func onReceive(_ joinActionInfo: V2NIMTeamJoinActionInfo) {
    setUpContactBadgeValue()
  }
}

// MARK: - V2NIMConversationListener

extension NETabBarController: NEConversationListener {
  func onConversationChanged(_ conversations: [V2NIMConversation]) {
    refreshSessionBadge()
  }

  func onConversationCreated(_ conversation: V2NIMConversation) {
    refreshSessionBadge()
  }

  func onConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
  }
}

// MARK: - NELocalConversationListener

extension NETabBarController: NELocalConversationListener {
  func onLocalConversationChanged(_ conversations: [V2NIMLocalConversation]) {
    refreshSessionBadge()
  }

  func onLocalConversationCreated(_ conversation: V2NIMLocalConversation) {
    refreshSessionBadge()
  }

  func onLocalConversationDeleted(_ conversationIds: [String]) {
    refreshSessionBadge()
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
    qchatVC.setCurrentServer(server: server)
  }
}
