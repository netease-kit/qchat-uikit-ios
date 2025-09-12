# 配置内容详见：PodConfigs/config_podspec.rb
# YXConfig.imuikit_version = 10.8.6
# YXConfig.qchatkit_version = 10.0.1
require_relative "PodConfigs/config_podspec.rb"

# Uncomment the next line to define a global platform for your project
platform :ios, YXConfig.deployment_target
source 'https://github.com/CocoaPods/Specs.git'

target 'IMQChatExample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # 基础库
  pod 'NEChatKit',   							YXConfig.imuikit_version      # IMUIKit 基础库
#  pod 'NEQChatKit',  						YXConfig.qchatkit_version     # QChatUIKit 基础库

  # UI 组件
  pod 'NEChatUIKit',           		YXConfig.imuikit_version     	# 会话（聊天）组件
  pod 'NEContactUIKit',       		YXConfig.imuikit_version      # 通讯录组件
  pod 'NEConversationUIKit', 			YXConfig.imuikit_version      # (云端)会话列表组件
  pod 'NELocalConversationUIKit', YXConfig.imuikit_version  		# (本地)会话列表组件
  pod 'NETeamUIKit',           		YXConfig.imuikit_version     	# 群相关设置组件
#  pod 'NEQChatUIKit',         		YXConfig.qchatkit_version     # 圈组 组件

  # 扩展库 - 地理位置组件
  pod 'NEMapKit',             		YXConfig.imuikit_version
  
  # 扩展库 - AI 划词搜索
  pod 'NEAISearchKit', 						YXConfig.imuikit_version

  # 扩展库 - 呼叫组件
  pod 'NERtcSDK/RtcBasic'                   #  RTC 音视频基础组件
  pod 'NERtcSDK/Nenn'                       #  RTC 音视频神经网络组件（使用背景虚化功能需要集成）
  pod 'NERtcSDK/Segment'                    #  RTC 音视频背景分割组件（使用背景虚化功能需要集成）
  pod 'NERtcCallKit/NOS_Special', '3.6.0'
  pod 'NERtcCallUIKit/NOS_Special', '3.6.0' # (源码地址：https://github.com/netease-kit/NEVideoCall-1to1/tree/main/NLiteAVDemo-iOS-ObjC/CallKit)


  # 如果需要查看UI部分源码请注释掉以上在线依赖(不包含呼叫组件)，打开下面的本地依赖
  # IMUIKit 源码地址：https://github.com/netease-kit/nim-uikit-ios
  pod 'NEQChatKit', :path => 'NEQChatKit/NEQChatKit.podspec'
  pod 'NEQChatUIKit', :path => 'NEQChatUIKit/NEQChatUIKit.podspec'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = YXConfig.deployment_target
      
      # Apple 芯片模拟器运行打开以下代码
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
