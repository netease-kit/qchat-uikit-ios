#
# Be sure to run `pod lib lint NEQChatUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NEQChatUIKit'
  s.version          = '9.2.10'
  s.summary          = 'Netease XKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://netease.im'
  s.license          = { :'type' => 'Copyright', :'text' => ' Copyright 2022 Netease '}
  s.author           = 'yunxin engineering department'
  s.source           = { :git => 'ssh://git@g.hz.netease.com:22222/yunxin-app/xkit-ios.git', :tag => s.version.to_s }
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
  
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.source_files = 'NEQChatUIKit/Classes/**/*'
  
#  s.resource_bundles = {
#    'NEQChatUIKit' => ['NEQChatUIKit/Assets/*.png']
#  }
  s.resource = 'NEQChatUIKit/Assets/**/*'
  s.dependency 'NECommonUIKit'
  s.dependency 'NEQChatKit'
  s.dependency 'SDWebImageWebPCoder'
  s.dependency 'SDWebImageSVGKitPlugin'
  s.dependency 'MJRefresh'
  s.dependency 'RSKPlaceholderTextView'
  s.dependency 'NIMSDK_LITE'
  s.dependency 'YXAlog'

end
