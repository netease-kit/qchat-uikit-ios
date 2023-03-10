
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitContactUI
import YXLogin
import NEKitCore
import NIMSDK
import NEKitQChatUI
import NEKitCoreIM
import IQKeyboardManagerSwift
import NEKitConversationUI
import NEKitTeamUI
import NEKitChatUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public var window: UIWindow?
    private var tabbarCtrl = UITabBarController()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window?.backgroundColor = .white
        setupInit()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRoot), name: Notification.Name("logout"), object: nil)
        registerAPNS()
        return true
    }
        
    func setupInit(){
        // init
        let option = NIMSDKOption()
        option.appKey = AppKey.appKey
        option.apnsCername = AppKey.pushCerName
        IMKitEngine.instance.setupCoreKitIM(option)

        // login to business server
        let config = YXConfig()
        config.appKey = AppKey.appKey
        config.parentScope = NSNumber(integerLiteral: 2)
        config.scope = NSNumber(integerLiteral: 7)
        config.supportInternationalize = false
        config.type = .phone
        #if DEBUG
        config.isOnline = false
        print("debug ")
        #else
        config.isOnline = true
        print("release")
        #endif
        AuthorManager.shareInstance()?.initAuthor(with: config)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        weak var weakSelf = self
        if let canAutoLogin = AuthorManager.shareInstance()?.canAutologin(), canAutoLogin == true {
            AuthorManager.shareInstance()?.autoLogin(completion: { user, error in
                if let err = error{
                    print("auto login error : ", err)
                    weakSelf?.loginWithUI()
                }else {
                    print("login accid : ", user?.imAccid as Any)
                    weakSelf?.setupSuccessLogic(user)
                }
            })
        }else {
            loginWithUI()
        }
    }
    
    @objc func refreshRoot(){
        print("refresh root")
        loginWithUI()
    }
    
    func registerAPNS(){
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            center.requestAuthorization(options: [.badge, .sound, .alert]) { grant, error in
                if grant == false {
                    DispatchQueue.main.async {
                        UIApplication.shared.keyWindow?.makeToast(NSLocalizedString("open_push", comment: ""))
                    }
                }
            }
        } else {
            let setting = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NIMSDK.shared().updateApnsToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NELog.infoLog("app delegate : ", desc: error.localizedDescription)
    }
    
    func loginWithUI(){
        weak var weakSelf = self
        AuthorManager.shareInstance()?.startLogin(completion: { user, error in
            if let err = error{
                print("login error : ", err)
            }else {
                weakSelf?.setupSuccessLogic(user)
            }
        })
    }
    
    func setupSuccessLogic(_ user: YXUserInfo?){
        setupXKit(user)
    }
    
    func setupXKit(_ user: YXUserInfo?){
        if let token = user?.imToken, let account = user?.imAccid {
            weak var weakSelf = self
            
            IMKitEngine.instance.loginIM(account, token) { error in
                if let err = error {
                    print("NEKitCore login error : ", err)
                }else {
                    ChatRouter.setupInit()
                    let param = QChatLoginParam(account,token)
                    IMKitEngine.instance.loginQchat(param) { error, response in
                        if let err = error {
                            print("qchatLogin failed, error : ", err)
                        }else {
                            weakSelf?.setupTabbar()
                        }
                    }
                }
            }
        }
    }
    
    func setupTabbar() {
        self.window?.rootViewController = NETabBarController()
        loadService()
    }
    
//    regist router
    func loadService() {
        //TODO: service
        ContactRouter.register()
        ChatRouter.register()
        TeamRouter.register()
        ConversationRouter.register()
        
        Router.shared.register(MeSettingRouter) { param in
            if let nav = param["nav"] as? UINavigationController {
                let me = PersonInfoViewController()
                nav.pushViewController(me, animated: true)
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
}

