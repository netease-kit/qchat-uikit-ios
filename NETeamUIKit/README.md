# NETeamUIKit

> IMUIKit 群组UI模块，提供通快速集成群组UI能力。

## Change Log

[change log](CHANGELOG.md)

## 本地引用

### 其他Kit引用
如果是其他Kit引用NETeamUIKit，就在对应Kit的podspec文件中添加依赖。

```
s.dependency 'NETeamUIKit'
```

由于podspec中无法通过路径来依赖本地的pod库，所以，需要在根目录的pod文件中找到对应的example工程来添加对NETeamUIKit的依赖。

```
pod 'NETeamUIKit', :path => 'IMUIKit/NETeamUIKit/NETeamUIKit.podspec'
```
### 界面工程直接引用
如果是example直接依赖NETeamUIKit，则直接在根目录的pod文件中找到对应的example工程来添加对NETeamUIKit的依赖。

```
// 本地引用示例，path路径根据实际相对路径填写
pod 'NETeamUIKit', :path => 'IMUIKit/NETeamUIKit/NETeamUIKit.podspec'
```

## Pod引用
```
pod 'NETeamUIKit', '9.3.0'
```
## 编译
- 在根目录执行pod install，运行IMUIKitExample工程，确保本地工作正常。
- 在根目录执行脚本

```
sh build_frame.sh --project Pods/Pods.xcodeproj --targetName NETeamUIKit --version xxxx(版本号)
```
- 完成上一步，根目录下会生成build目录，里面有NETeamUIKit.framework等目录
- 找到build-iphonesimulator/NETeamUIKit.framework/Modules/NETeamUIKit.swiftmodule，将里面的文件按对应目录复制到build/NETeamUIKit.framework/Modules/NETeamUIKit.swiftmodule，这步是为了支持NETeamUIKit可以在模拟器环境中运行，后续将通过脚本来优化这个流程
- 完成上一步，build/NETeamUIKit.framework/Modules/NETeamUIKit.swiftmodule下可以找到多个平台的swiftinstance文件，用文本编辑器打开，全文删除 'NIMSDK.'，这步是为了解决OC与Swift混编导致的Module引用问题
- 完成以上工作，点击NETeamUIKit.framework压缩，并将其重命名带版本号

```
NETeamUIKit_iOS_v9.3.0.framework.zip
```
## 发布
- 将打包的zip发给具备admin sdk管理权限的同事
- 将zip上传到admin的NETeamUIKit(上传SDK时自定义SDK种类填IMUIKit)目录下，获得文件链接
- 编辑Podspecs/IM/NETeamUIKit.podspec中的版本及SDK链接信息
- 通过pod trunk push 命令进行上传
- 如发生错发，使用 pod trunk delete NETeamUIKit xxx(版本号) 的命令来进行删除
