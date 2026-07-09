# MacScreen

MacScreen 是一个 macOS 动态壁纸应用，可以把本地视频作为桌面动态壁纸播放。它当前面向 Apple silicon Mac，主打本地资源、低打扰、低负载的桌面美化体验。

项目现在仍处于 MVP 阶段，重点是把核心闭环做稳定：选择视频、预览素材、应用到桌面、停止播放、管理本地素材，并尽量不影响用户正常使用电脑。

## 项目特点

- 原生 macOS 应用，使用 SwiftUI + AppKit 实现
- 支持内置动态壁纸素材
- 支持导入用户自己的本地视频
- 支持静态缩略图预览，避免打开 App 就解码播放 4K 视频
- 支持一键应用视频到桌面背景层
- 支持停止动态壁纸播放
- 支持删除自定义素材或隐藏内置素材
- 支持恢复被隐藏的内置素材
- 支持 Sparkle 自动更新
- 支持打包为 DMG 分发

## 技术栈

- Swift
- SwiftUI
- AppKit
- AVFoundation
- Swift Package Manager
- Sparkle 2
- Makefile
- GitHub Actions

核心实现方向：

- SwiftUI 负责主界面、列表、预览和操作区
- AppKit 负责 macOS 生命周期、窗口层级和桌面播放窗口
- AVFoundation 负责视频播放
- Sparkle 负责 App 自动更新
- GitHub Actions 负责自动构建和发布 DMG

## 当前功能

### 动态壁纸资源

MacScreen 会读取内置视频素材，并在左侧列表中展示资源名称、分辨率、时长和缩略图。选中素材后，右侧会显示静态预览。

### 应用到桌面

用户选中一个视频后，可以点击“应用到桌面”，App 会把视频静音循环播放到桌面背景层，不会抢占当前正在使用的窗口。

### 本地视频导入

用户可以在 App 内添加自己的本地视频。导入的视频会复制到当前用户的 Application Support 目录，不会写回项目仓库。

当前支持的视频格式：

- mp4
- mov
- m4v

### 素材删除和恢复

用户可以删除自己导入的视频，也可以把内置素材从当前列表中隐藏。如果误删了内置素材，可以通过“初始化资源”恢复。

### 自动更新

项目已经接入 Sparkle 2。配置好 Sparkle 密钥和 GitHub Pages 后，用户可以在 App 菜单中检查更新，并在本地完成新版下载和安装。

详细配置步骤见：

```text
AUTO_UPDATE_GUIDE.md
```

## 安装和使用

开发阶段可以从源码运行：

```bash
make run
```

也可以构建 DMG：

```bash
make package
```

打包产物位于：

```text
dist/MacScreen.dmg
```

如果从 GitHub Release 下载后被 macOS 拦截，可以右键 App 选择“打开”。正式分发时建议配置 Developer ID 签名和 Apple notarization。

## 项目结构

```text
.
├── App/                    # App bundle 配置
├── Assets/                 # 图标、链接图标、生成缩略图
├── Scripts/                # 构建资源、自动更新、Xcode 安装脚本
├── Sources/MacScreen/      # App 源码
├── Videos/                 # 内置动态壁纸视频
├── AUTO_UPDATE_GUIDE.md    # 自动更新配置和发布指南
├── DEVELOPMENT.md          # 开发、构建、维护文档
├── Makefile                # 构建、运行、打包入口
├── Package.swift           # SwiftPM 配置
└── README.md               # 项目介绍
```

## 开发文档

更多工程细节请看：

```text
DEVELOPMENT.md
```

其中包含：

- 本地开发环境准备
- 构建和打包流程
- 新增内置壁纸资源的方法
- GitHub Release 分发流程
- 自动更新维护说明
- 当前实现说明
- 维护建议
- 历史问题和处理过程

## 未来计划

- 菜单栏常驻入口
- 暂停/继续动态壁纸
- 多屏独立选择壁纸
- 开机启动选项
- 壁纸分类、收藏、搜索
- 自定义资源目录
- 在线壁纸资源下载
- 低电量自动暂停
- 性能状态展示
- 正式签名和公证发布流程

## 设计原则

MacScreen 的核心目标不是“尽可能播放更多视频”，而是让动态壁纸在 macOS 上稳定、安静、可控地运行。

后续功能会优先遵循这些原则：

- 不在启动时自动播放大视频
- 不抢焦点
- 不遮挡用户正在使用的窗口
- 不强依赖 Desktop、Documents 等隐私目录权限
- 用户可以随时停止动态壁纸
- 默认体验要轻量、稳定、可恢复
