# NERtcCallKit

> 为了方便开发者接入音视频通话 2.0 的呼叫功能，网易云信将信令和 NERTC 的音视频能力相结合，简化呼叫的复杂流程，将呼叫功能以组件的形式提供给客户，提高接入效率、降低使用成本。呼叫组件（NERtcCallKit）内部提供音视频类型通话的呼叫、接通、拒接，以及通话中音频和视频的开关控制，同时提供配套 UI，您可以使用呼叫组件实现类似通用即时通讯应用中的音视频通话功能。

## Change Log

[change log](CHANGELOG.md)

## 本地引用

### 其他Kit引用
如果是其他Kit引用NERtcCallUIKit，就在对应Kit的podspec文件中添加依赖。

```ruby
s.dependency 'NERtcCallUIKit'
```

由于podspec中无法通过路径来依赖本地的pod库，所以，需要在根目录的pod文件中找到对应的example工程来添加对组件的依赖。

```ruby
pod 'NERtcCallUIKit', :path => 'CallKit/NERtcCallUIKit/NERtcCallUIKit.podspec'
```

### 界面工程直接引用
如果是example直接依赖，则直接在根目录的pod文件中找到对应的example工程来添加对组件的依赖。

```ruby
pod 'NERtcCallUIKit', :path => 'CallKit/NERtcCallUIKit/NERtcCallUIKit.podspec'
```

## Pod引用
```ruby
pod 'NERtcCallUIKit', '1.8.2'
```

## 编译

## 发布
- 将打包的zip发给具备admin sdk管理权限的同事
- 将zip上传到admin的NERtcCallKit(上传SDK时自定义SDK种类填NERtcCallKit)目录下，获得文件链接
- 编辑Podspecs/CallKit/NERtcCallUIKit.podspec中的版本及SDK链接信息
- 通过pod trunk push 命令进行上传
- 如发生错发，使用 pod trunk delete NERtcCallUIKit xxx(版本号) 的命令来进行删除
