# DivineSleep

[English Version](./README.md)

DivineSleep 是一个轻量的 macOS 菜单栏工具，用来管理专注计时、睡眠倒计时、防睡眠和快速睡眠操作。

## 功能特性

- 支持番茄时钟模式和睡眠倒计时模式
- 预设时长卡片，点击即可开始
- 支持电池模式和接电模式下的防睡眠控制
- 可从面板或菜单栏菜单直接触发“立即睡眠”
- 开启防睡眠时，支持锁屏后 10 秒内自动快速息屏
- 支持亮色、暗黑和跟随系统主题
- 应用重开后可恢复未结束的计时会话
- 面板内可查看通知权限状态并直接请求授权
- 已补充核心状态和计时行为相关自动化测试

## 运行要求

- macOS 12.0 及以上
- 已安装支持 Swift 5.7+ 的 Xcode 或 Command Line Tools

## 运行项目

```bash
swift run DivineSleep
```

应用会以菜单栏工具形式运行，不会像普通 App 一样显示在 Dock 中。

## 构建

调试构建：

```bash
swift build
```

生成 release `.app`：

```bash
./build_app.sh
```

这个打包脚本会基于脚本自身位置定位项目根目录，所以即使你当前不在仓库目录里，也可以这样调用：

```bash
/path/to/DivineSleep/build_app.sh
```

生成产物路径：

```text
.build/release-app/DivineSleep.app
```

## 测试

```bash
swift test
```

当前测试覆盖：

- 偏好设置持久化
- 按模式恢复上次选择的时长
- 重启后恢复未完成计时
- 过期会话自动清理
- 防睡眠开关即时生效
- 通知权限流程
- 计时完成后的行为与反馈

## 通知权限

DivineSleep 使用 macOS 系统通知来提醒计时结束和系统操作结果。

如果通知被关闭，可以这样打开：

1. 打开 `系统设置`
2. 进入 `通知`
3. 找到 `DivineSleep`
4. 开启提醒和声音

你也可以直接在应用面板里的“提醒”卡片中请求授权或重新检测状态。

## 说明

- 防睡眠能力基于 `caffeinate`
- 立即睡眠和锁屏快速息屏能力基于 `pmset`
- 打包版本号定义在 [`Info.plist`](./Info.plist) 中
