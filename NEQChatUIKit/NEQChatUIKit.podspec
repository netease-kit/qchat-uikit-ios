#
#  Be sure to run `pod spec lint NEQChatUIKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the s.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/pods.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

# 配置内容详见：../PodConfigs/config_podspec.rb
require_relative "../PodConfigs/config_podspec.rb"

Pod::Spec.new do |spec|
  spec.name         = 'NEQChatUIKit'
  spec.version      = YXConfig.qchatkit_version
  spec.summary      = 'Netease XKit'
  spec.homepage         = YXConfig.homepage
  spec.license          = YXConfig.license
  spec.author           = YXConfig.author
  spec.ios.deployment_target = YXConfig.deployment_target
  spec.swift_version = YXConfig.swift_version
  spec.source           = { :git => '', :tag => spec.version.to_s }
  spec.source_files = 'NEQChatUIKit/Classes/**/*'
  spec.resource = 'NEQChatUIKit/Assets/**/*'
  YXConfig.pod_target_xcconfig(spec)
  
  spec.dependency 'NEQChatKit'
  spec.dependency 'NECommonUIKit', '9.8.1'
  spec.dependency 'MJRefresh'
  spec.dependency 'SDWebImageWebPCoder'
  spec.dependency 'SDWebImageSVGKitPlugin'

end
