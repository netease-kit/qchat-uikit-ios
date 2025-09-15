
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMQChat
import NIMSDK

public class QChatKitClient: NSObject {
  public static let instance = QChatKitClient()

  override private init() {
    super.init()
  }

  /// 是否开启圈组消息缓存支持, 默认为 NO
  public var enabledMessageCache: Bool {
    set {
      NIMQChatConfig.shared().enabledMessageCache = newValue
    }
    get {
      NIMQChatConfig.shared().enabledMessageCache
    }
  }

  /// 是否开启圈组的自动订阅功能, 默认为 NO
  public var autoSubscribe: Bool {
    set {
      NIMQChatConfig.shared().autoSubscribe = newValue
    }
    get {
      NIMQChatConfig.shared().autoSubscribe
    }
  }

  /// NIM当前服务器配置
  public var imServerSetting: NIMServerSetting {
    set {
      IMKitClient.instance.serverSetting = newValue
    }
    get {
      IMKitClient.instance.serverSetting
    }
  }

  /// 获取NIMSDK版本号
  public func sdkVersion() -> String {
    IMKitClient.instance.sdkVersion()
  }

  /// 获取NIMSDK配置项实例
  public var imConfig: NIMSDKConfig {
    IMKitClient.instance.config
  }

  /// 查询当前登录的帐号（accid）
  public func imAccid() -> String {
    IMKitClient.instance.account()
  }

  /// 当前是否已登录
  /// - Returns: true已登录，false未登录
  public func isLogined() -> Bool {
    IMKitClient.instance.hasLogined()
  }

  /// 获取 AppKey
  /// - Returns: 返回当前注册的AppKey
  public func appKey() -> String {
    IMKitClient.instance.appKey()
  }

  /// 是否正在使用Demo AppKey
  /// - Returns: 返回是否正在使用Demo AppKey
  public func isUsingDemoAppKey() -> Bool {
    IMKitClient.instance.isUsingDemoAppKey()
  }

  /// 是否是自己
  /// - Parameter accid: 账户id
  /// - Returns: 是否是自己
  public func isMe(_ accid: String?) -> Bool {
    IMKitClient.instance.isMe(accid)
  }

  /// 配置圈组的推送证书。通过配置推送证书的名称（对应云信控制台上的推送证书名称），与第三方推送厂商完成通信。
  /// - Parameter option: 圈组选项，推送证书名称
  public func setQChatOption(option: NIMQChatOption) {
    NIMSDK.shared().qchat(with: option)
  }

  /// 更新APNS Token
  /// - Parameters:
  ///   - data: APNS Token
  ///   - key: 自定义本端推送内容, 设置key可对应业务服务器自定义推送文案; 传@"" 清空配置, nil 则不更改
  ///   - qchatKey: qchatKey 自定义圈组本端推送内容, 设置key可对应业务服务器自定义推送文案; 传@"" 清空配置, nil 则不更改
  /// - Returns: 格式化后的APNS Token
  public func updateApnsToken(data: Data, key: String?, qchatKey: String?) -> String {
    NIMSDK.shared()
      .updateApnsToken(data, customContentKey: key, qchatCustomContentKey: qchatKey)
  }

  /// 上传日志
  /// - Parameter completion: 上传日志完成回调
  public func uploadLogs(_ completion: @escaping NIMUploadLogsHandler) {
    IMKitClient.instance.uploadLogs(completion)
  }
}
