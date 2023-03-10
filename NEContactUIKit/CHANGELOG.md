# NEContactKit & NEContactUIKit Changelog

## 9.4.0(2023-03-08)
### New Features
* 添加好友页面输入框输入文字后新增一键清除按钮。
### Behavior changes
* 添加好友页面，好友同意后再次点击添加好友变成好友名片页，有发送消息和删除好友按钮
* 添加好友页面，输入框提示语优化: 输入查找用户id -> 请输入账号
* 通讯录右侧显示的首字母范围显示完整：["A"..."Z", "#"]
* 备注名长度限制为 15 字
### Bug Fixes
* 修复黑名单页好友昵称超长文案展示重叠的问题。
* 修复给好友添加备注输入空格也可以保存成功的问题。
* 优化通讯录好友列表排序规则。
* 修复加入黑名单 - 删除好友 - 添加好友 - 移除黑名单后对方不在通讯录显示的问题。
* 修复好友名片页面账号前无“账号：”，添加账号上方无颜色间隔的问题。
* 修复通讯录不同账号之间的头像相互复用的问题。

## 9.3.1(2023-1-05)
*   - FIXED    修复 NEMapKit 组件的已知问题。

## 9.3.0(2022-12-05)
*   - NEW    新增地理位置消息功能，具体实现方法参见实现地理位置消息功能。
*   - NEW    新增文件消息功能（升级后可直接使用）。
*   - FIXED    修复更新讨论组/高级群头像失败的问题。
*   - FIXED    修复发送视频消息未显示首帧的问题。
*   - FIXED    修复表情和文案不一致的问题。
*   - FIXED    修复“正在输入中”的显示问题。
*   - FIXED    修复群聊消息已读按钮失效的问题。
*   - FIXED    修复其他已知问题。

## 9.2.11(2022-11-17)
*   - UPDATE   NIM SDK 版本升级到 V9.6.4    
*   - FIXED    修复好友名片中未显示基本信息的问题。
*   - FIXED    修复视频消息加载问题。
*   - FIXED    修复更新自己群昵称失败的问题。
*   - FIXED    修复加入他人圈组服务器的按钮失效问题。
*   - FIXED    修复圈组频道成员列表和频道黑白名单成员列表的展示问题。
*   - FIXED    修复无法退出图片详情页的问题。
*   - FIXED    修复历史图片未展示缩略图的问题。
*   - FIXED    修复黑名单成员列表头像与好友头像不一致的问题。
*   - FIXED    修复其他已知问题。


## 9.2.10(02-November-2022)
*   - FIXED    修复xcode 14编译错误问题

## 9.2.9(25-August-2022)
*   - NEW      iOS新增自定义用户信息功能。
*   - changed  IMKitEngine类中功能迁移至IMKitClient
*   - FIXED    修复OC工程调用UI库失败问题
*   - FIXED    统一接口层API
*   - FIXED    修复已知bug

## 9.2.8(19-September-2022)
*   - NEW    多语言能力支持
*   - FIXED  相机权限修改
*   - FIXED  历史遗留bug修改

## 9.2.7(25-August-2022)
*   - FIXED  修复 Swift 版本编译问题。
*   - FIXED  修复相册选择图片时图片展示问题。
*   - FIXED  修复圈组频道身份组权限信息展示问题。

## 9.2.6-rc01(02-August-2022)
*   - FIXED  修复导航控制器push 页面 页面卡顿问题

## 9.2.6-rc01(02-August-2022)
*   - FIXED  修复导航控制器push 页面 页面卡顿问题
*   - FIXED  修改错误emoji表情问题。
*   - FIXED  统一log命名->NELog
*   - FIXED  好友名片页去掉消息提醒开关
*   - FIXED  修复app端修改群组头像 web端不能展示问题
*   - FIXED  统一podspec依赖，三方库不设置固定版本
*   - NEW    添加Conversationrepo chatrepo 注解
*   - NEW    新增userInfoProvider功能类

## 9.2.4(28-June-2022)
*   - FIXED  修复客户反馈chat页面，无消息时下拉崩溃，新建群组下拉消息重复。
*   - FIXED  router路由对齐，contact主页面设置open。
*   - FIXED  修改Toast提示信息位置
*   - NEW    补充自定义消息逻辑

## 9.2.1(20-July-2022)
    - FIXED  低版本xcode编译低版本的包（xcode 13.2.1）

## 9.0.2(29-May-2022)
*   - FIXED  修复NEConversationUIKit,NEChatUIKit,NETeamUIKit,NEQChatUIKit,NEContactUIKit中作用域问题。

## 9.0.1(19-May-2022)
*   - NEW  我的->个人信息页 新增copy账号功能
*   - FIXED 修复头像被压缩问题
*   - FIXED 发送视屏压缩模糊问题修复
*   - FIXED 修复搜索框背景色,高度问题，修复会话列表首页弹窗阴影过重问题，修复alert弹窗色值问题，修复通讯录icon失真问题...
*   - FIXED 更新会话列表logo&title
*   - FIXED 修复圈组聊天页键盘偶现不能弹起问题。
*   - FIXED 修复图片预览被压缩变形问题

## 9.0.0(09-May-2022)
*   - NEW  swift新版本IM发布,包含消息，圈组，通讯录，我的版块。
