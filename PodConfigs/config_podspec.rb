# podspec 配置文件，用于源码依赖时统一配置

module YXConfig
  def self.imuikit_version
    "9.7.4"
#    "10.6.2"
  end

  def self.qchatkit_version
    "9.5.6"
#    "10.0.0"
  end

  def self.deployment_target
    "12.0"
  end

  def self.swift_version
    "5.0"
  end

  def self.homepage
    "http://netease.im"
  end

  def self.author
    "yunxin engineering department"
  end

  def self.pod_target_xcconfig(s)
    s.pod_target_xcconfig = {
      "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64",
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "APPLICATION_EXTENSION_API_ONLY" => "NO",
      "DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym"
    }
  end

  def self.license
    { :'type' => "Copyright", :'text' => " Copyright 2022 Netease " }
  end
end
