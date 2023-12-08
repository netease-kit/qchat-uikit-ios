# Uncomment the next line to define a global platform for your project
# platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'IMQChatExample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  #登录组件
  pod 'YXLogin', '1.0.0'

  # 基础 Kit 库
  pod 'NIMSDK_LITE','9.14.0'
pod 'NECoreKit', '9.6.5'
pod 'NECoreIMKit', '9.6.5'
pod 'NEChatKit', '9.6.5'
pod 'NECommonKit', '9.6.4'
pod 'NECommonUIKit', '9.6.5'
pod 'NECoreQChatKit', '9.6.5'
pod 'NEQChatKit', '9.5.3'

# UI 组件，依次为通讯录组件、会话列表组件、会话（聊天）组件、群相关设置、圈组组件
pod 'NEContactUIKit', '9.6.5'      
pod 'NEConversationUIKit', '9.6.5' 
pod 'NEChatUIKit', '9.6.5'         
pod 'NETeamUIKit', '9.6.5'     
pod 'NEQChatUIKit', '9.5.3'     

# 扩展库-地理位置组件
pod 'NEMapKit', '9.6.5'         

# 扩展库-呼叫组件
 pod 'NERtcCallKit/NOS_Special', '2.2.0'
 pod 'NERtcCallUIKit/NOS_Special', '2.2.0'

# 扩展库，依次为 RTC 音视频基础组件、RTC 音视频神经网络组件（使用背景虚化功能需要集成）、RTC 音视频背景分割组件（使用背景虚化功能需要集成）
pod 'NERtcSDK/RtcBasic', '5.5.2'        
pod 'NERtcSDK/Nenn'                    
pod 'NERtcSDK/Segment'     

  # 如果需要查看UI部分源码请注释掉以上在线依赖，打开下面的本地依赖
#   pod 'NEQChatUIKit', :path => 'NEQChatUIKit/NEQChatUIKit.podspec'


end

#⚠️如果pod依赖报错，可打开以下注释
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
