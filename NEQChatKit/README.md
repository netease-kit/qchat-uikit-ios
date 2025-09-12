# NEQChatKit

> IMUIKit 圈组服务，提供圈组服务相关的数据能力。

## Change Log

[change log](CHANGELOG.md)

## 本地引用

### 其他Kit引用
如果是其他Kit引用NEQChatKit，就在对应Kit的podspec文件中添加依赖。

```
s.dependency 'NEQChatKit'
```

由于podspec中无法通过路径来依赖本地的pod库，所以，需要在根目录的pod文件中找到对应的example工程来添加对NEQChatKit的依赖。

```
pod 'NEQChatKit', :path => 'IMUIKit/NEQChatKit/NEQChatKit.podspec'
```
### 界面工程直接引用
如果是example直接依赖NEQChatKit，则直接在根目录的pod文件中找到对应的example工程来添加对NEQChatKit的依赖。

```
// 本地引用示例，path路径根据实际相对路径填写
pod 'NEQChatKit', :path => 'IMUIKit/NEQChatKit/NEQChatKit.podspec'
```

## Pod引用
```
pod 'NEQChatKit', '9.3.0'
```
## 编译
- 在根目录执行pod install，运行IMUIKitExample工程，确保本地工作正常。
- 在根目录执行脚本

```
sh build_frame.sh --project Pods/Pods.xcodeproj --targetName NEQChatKit --version xxxx(版本号)
```
- 完成上一步，根目录下会生成build目录，里面有NEQChatKit.framework等目录
- 找到build-iphonesimulator/NEQChatKit.framework/Modules/NEQChatKit.swiftmodule，将里面的文件按对应目录复制到build/NEQChatKit.framework/Modules/NEQChatKit.swiftmodule，这步是为了支持NEQChatKit可以在模拟器环境中运行，后续将通过脚本来优化这个流程
- 完成上一步，build/NEQChatKit.framework/Modules/NEQChatKit.swiftmodule下可以找到多个平台的swiftinstance文件，用文本编辑器打开，全文删除 'NIMSDK.'，这步是为了解决OC与Swift混编导致的Module引用问题
- 完成以上工作，点击NEQChatKit.framework压缩，并将其重命名带版本号

```
NEQChatKit_iOS_v9.3.0.framework.zip
```
## 发布
- 将打包的zip发给具备admin sdk管理权限的同事
- 将zip上传到admin的NEQChatKit(上传SDK时自定义SDK种类填IMUIKit)目录下，获得文件链接
- 编辑Podspecs/IM/NEQChatKit.podspec中的版本及SDK链接信息
- 通过pod trunk push 命令进行上传
- 如发生错发，使用 pod trunk delete NEQChatKit xxx(版本号) 的命令来进行删除
