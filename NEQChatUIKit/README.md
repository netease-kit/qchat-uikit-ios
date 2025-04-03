# NEQChatUIKit

> IMUIKit 圈组UI模块，提供通快速集成圈组UI能力。

## Change Log

[change log](CHANGELOG.md)

## 本地引用

### 其他Kit引用
如果是其他Kit引用NEQChatUIKit，就在对应Kit的podspec文件中添加依赖。

```
s.dependency 'NEQChatUIKit'
```

由于podspec中无法通过路径来依赖本地的pod库，所以，需要在根目录的pod文件中找到对应的example工程来添加对NEQChatUIKit的依赖。

```
pod 'NEQChatUIKit', :path => 'IMUIKit/NEQChatUIKit/NEQChatUIKit.podspec'
```
### 界面工程直接引用
如果是example直接依赖NEQChatUIKit，则直接在根目录的pod文件中找到对应的example工程来添加对NEQChatUIKit的依赖。

```
// 本地引用示例，path路径根据实际相对路径填写
pod 'NEQChatUIKit', :path => 'IMUIKit/NEQChatUIKit/NEQChatUIKit.podspec'
```

## Pod引用
```
pod 'NEQChatUIKit', '9.3.0'
```
