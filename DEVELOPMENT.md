# MacScreen 开发文档

这份文档面向项目维护者，记录本地开发、构建打包、资源管理、发布流程、实现细节和历史踩坑。项目介绍请看 `README.md`；自动更新的完整操作步骤请看 `AUTO_UPDATE_GUIDE.md`。

## 当前状态

- 主实现：`Sources/MacScreen`
- 运行方式：`make run`
- 构建产物：`.build/MacScreen.app`
- 打包产物：`dist/MacScreen.dmg`
- 视频素材：`Videos/*.mp4`
- 视频缩略图：构建阶段生成到 `Assets/Thumbnails/`
- 应用图标源：`Assets/AppIcon/icon.png`
- 应用图标产物：构建阶段生成 `Assets/AppIcon/MacScreenIcon.icns`
- 最低系统：macOS 14+
- 推荐开发环境：macOS 15.3.1 + Xcode 16.4

## 项目结构

```text
.
├── App/
│   └── Info.plist                  # App bundle 信息、图标配置、版本号
├── Assets/
│   ├── AppIcon/                    # 图标源文件
│   └── Links/                      # 外链图标资源
├── Scripts/
│   ├── generate-appcast.sh         # 生成 Sparkle appcast
│   ├── generate-assets.sh          # 生成缩略图和 .icns 图标
│   └── install-xcode-16.4.sh       # 安装 Xcode 16.4 的辅助脚本
├── Sources/
│   └── MacScreen/
│       ├── MacScreenApp.swift      # SwiftUI App 入口
│       ├── AppDelegate.swift       # AppKit 生命周期补充
│       ├── AppConfiguration.swift  # 运行时配置集中管理
│       ├── ContentView.swift       # 主界面
│       ├── PreferencesView.swift   # macOS 原生偏好设置页
│       ├── StatusBarController.swift # 菜单栏常驻入口
│       ├── SoftwareUpdateController.swift # Sparkle 自动更新入口
│       ├── LoginItemController.swift # 开机启动注册
│       ├── LowBatteryMonitorController.swift # 低电量监控和用户决策弹窗
│       ├── WallpaperLibrary.swift  # 扫描资源、读取视频信息和缩略图
│       ├── WallpaperService.swift  # 业务服务抽象，便于测试
│       ├── WallpaperStore.swift    # SwiftUI 状态管理
│       ├── WallpaperWindowController.swift # 桌面动态壁纸窗口控制
│       ├── PlayerView.swift        # AVPlayerLayer 承载视图
│       ├── WallpaperItem.swift     # 壁纸资源模型
│       └── UserDefaultsKeys.swift  # UserDefaults key
├── Videos/                         # 内置 mp4 动态壁纸资源
├── AUTO_UPDATE_GUIDE.md            # 自动更新配置和发布指南
├── DEVELOPMENT.md                  # 开发维护文档
├── Makefile                        # 构建、运行、打包、清理
├── Package.swift                   # SwiftPM 元数据
├── Tests/                          # SwiftPM 测试
└── README.md                       # 项目介绍
```

## 基础准备

### 安装 Xcode 16.4

当前机器是 macOS 15.3.1。App Store 里的最新版 Xcode 要求更高系统，不能直接安装。因此项目使用 `xcodes` 安装 Xcode 16.4 到用户目录：

```bash
bash Scripts/install-xcode-16.4.sh
```

安装过程中可能需要 Apple ID、双重认证验证码，以及 Apple Developer 协议确认。

### 接受 Xcode license

Xcode 安装完成后，如果编译时报：

```text
You have not agreed to the Xcode license agreements.
```

执行：

```bash
sudo xcodebuild -license
```

看完协议后输入：

```text
agree
```

### 准备视频资源

把 mp4 动态壁纸放在工程根目录的 `Videos` 下。当前项目已有多个 mp4，主要是 H.264，部分是 4K 分辨率。

### 准备应用图标

当前图标源文件为：

```text
Assets/AppIcon/icon.png
```

构建时 `Scripts/generate-assets.sh` 会居中裁切为方形图标，并转换为 `.icns`。如果后续更换图标，直接替换这个文件即可。

## 构建和运行

构建并打开 App：

```bash
make run
```

只构建不打开：

```bash
make build
```

打包 DMG：

```bash
make package
```

产物位于：

```text
dist/MacScreen.dmg
```

清理构建产物：

```bash
make clean
```

构建时会自动执行：

```bash
Scripts/generate-assets.sh
```

这个脚本会：

- 用 `qlmanage` 为每个 mp4 生成第一帧缩略图
- 用 `sips` 和 `iconutil` 生成 `.icns` 应用图标
- 把 `Videos`、`Thumbnails`、`Links`、`MacScreenIcon.icns` 打包进 `.build/MacScreen.app/Contents/Resources`
- 清理没有对应视频的过期缩略图
- 使用 ad-hoc 签名处理 `.app` 包，降低 GitHub 下载后被 macOS 判定为损坏的概率

## 新增壁纸资源

新增内置资源不需要改 Swift 代码。把新的 `.mp4` 文件放进：

```text
Videos/
```

然后重新构建或打包：

```bash
make build
# 或
make package
```

构建脚本会自动为新视频生成缩略图，并把视频复制进 App bundle。新增后只需要把 `Videos/*.mp4` 提交到 Git；`Assets/Thumbnails/` 是生成物，不需要提交。

用户也可以在 App 内点击“添加视频”，导入自己的本地视频作为动态壁纸素材。导入的视频会复制到当前用户的 Application Support 目录：

```text
~/Library/Application Support/MacScreen/Videos/
```

这类用户自定义素材不会写回代码仓库，也不需要重新打包。当前支持 `mp4`、`mov`、`m4v` 视频文件。

用户可以选中素材后点击“删除素材”。单选时删除当前素材；按住 Command 可多选素材，再点击“删除选中”批量删除。自定义上传的视频会删除本地文件；内置默认素材不会物理删除 App 包内文件，只会从当前用户的素材列表中移除。

如果用户误删了内置默认素材，可以点击左侧的“初始化资源”。这个操作会恢复所有被隐藏的内置素材，不会删除用户自己上传的视频。

## 分发和发布

内部测试可以先直接分发本地生成的 DMG：

```text
dist/MacScreen.dmg
```

正式分发推荐使用 GitHub Release。推送 `v*` tag 后，`.github/workflows/release-dmg.yml` 会在 GitHub macOS runner 上自动执行：

```bash
make package
```

并把生成的 `MacScreen.dmg` 上传到对应 Release。

如果需要手动重新构建某个版本，也可以在 GitHub Actions 页面运行 `Build DMG Release`，输入要附加 DMG 的 tag。

当前 DMG 体积主要来自内置视频资源。要明显减小安装包，需要减少内置视频数量，或改成轻量 App 加用户自行导入/在线下载资源。

当前内部版本默认使用 ad-hoc 签名，不是 Apple Developer ID 签名，也没有 notarization。如果从 GitHub 下载后被 macOS Gatekeeper 拦截，可以右键 App 选择“打开”，或在终端对安装后的 App 执行：

```bash
xattr -dr com.apple.quarantine /Applications/MacScreen.app
```

要让下载后完全像正式软件一样直接打开，需要 Developer ID 签名和 Apple notarization。GitHub Actions 已经预留自动签名公证流程；在仓库 Secrets 配好下面这些值后，推送 tag 会自动生成已签名并公证的 DMG：

```text
DEVELOPER_ID_CERTIFICATE_BASE64
DEVELOPER_ID_CERTIFICATE_PASSWORD
DEVELOPER_ID_APPLICATION_IDENTITY
BUILD_KEYCHAIN_PASSWORD
APPLE_ID
APPLE_TEAM_ID
APPLE_APP_PASSWORD
```

其中 `DEVELOPER_ID_CERTIFICATE_BASE64` 是 Developer ID Application `.p12` 证书的 base64 内容，`APPLE_APP_PASSWORD` 是 Apple ID app-specific password。

## 自动更新维护

项目已接入 Sparkle 2，用于实现类似普通 macOS App 的自动更新体验：

- App 菜单中会出现“检查更新...”
- 配置好 Sparkle 密钥后，App 会定期检查更新
- 用户确认后，Sparkle 会下载新版 DMG、替换本地 App，并在重启后生效

自动更新源当前配置为：

```text
https://nov-two.github.io/Mac.screen/appcast.xml
```

完整配置和发布步骤见：

```text
AUTO_UPDATE_GUIDE.md
```

## 运行策略

为了避免影响正常工作，当前版本刻意采用低负载策略：

- App 启动时不自动播放视频
- App 启动时默认不自动恢复上次动态壁纸；用户可在菜单栏开启
- 右侧只显示静态预览图，不播放 4K 视频
- 缩略图在构建阶段生成，不在 App 启动阶段同步抽帧
- 点击“应用到桌面”后才创建 AVPlayer 播放视频
- 当前会把同一个动态壁纸应用到所有屏幕
- 低电量暂停默认关闭；开启后会先暂停播放并让用户决定停止、退出或继续播放
- 开机启动默认关闭，通过菜单栏开关注册或取消 `SMAppService.mainApp`
- App 会做单实例保护，避免多个副本同时争抢桌面壁纸窗口
- 内置浏览器允许用户直接下载资源，下载完成后自动尝试导入
- 下载资源导入成功后默认清理下载源文件
- 退出时会停止播放器并关闭动态壁纸窗口

## 当前实现说明

### 配置集中管理

运行时配置集中在 `AppConfiguration`，包括：

- App 名称和 Application Support 子目录
- 内置视频、缩略图、下载目录和链接资源目录名
- 支持的视频和压缩包扩展名
- 导入视频的最低分辨率
- 壁纸网站、GitHub 链接和内置浏览器窗口尺寸
- 低电量暂停阈值和轮询间隔
- 内置浏览器窗口尺寸和默认下载文件名

后续新增可调参数时，优先放到 `AppConfiguration`，避免散落硬编码。

### 业务与 UI 边界

`WallpaperStore` 是 SwiftUI 视图使用的状态入口，但资源加载、导入、删除、隐藏、设置读写等能力通过 `WallpaperServicing` 抽象出来。默认实现是 `DefaultWallpaperService`，测试中可以替换为 mock service。

这样做的目的：

- UI 只关心状态和用户动作
- 业务逻辑可以独立测试
- UserDefaults、文件系统、登录项等系统依赖集中在 service 或专用 controller 中
- 后续做偏好设置页或自动化测试时不需要重写主界面

### 资源扫描

`WallpaperLibrary` 会按优先级找视频目录：

1. App bundle 里的 `Resources/Videos`
2. 当前工作目录下的 `Videos`

正常构建后的 App 应该走第一项。

### 缩略图

缩略图文件名格式：

```text
原视频文件名.mp4.png
```

例如：

```text
Videos/示例壁纸.mp4
Assets/Thumbnails/示例壁纸.mp4.png
```

运行时优先读取 App bundle 中的 `Resources/Thumbnails`。如果读取失败，当前代码还有运行时兜底抽帧逻辑，但维护时应尽量保证构建阶段生成好缩略图，避免启动阶段解码视频。

### 动态壁纸窗口

`WallpaperWindowController` 负责创建桌面播放窗口：

- 遍历 `NSScreen.screens`，所有屏幕同步播放同一个视频
- 无边框
- 忽略鼠标事件
- 静音播放
- 循环播放
- 支持暂停、继续、停止
- 窗口层级使用 `desktopWindow`

这部分是动态壁纸 MVP 的核心，也是最容易影响系统体验的地方。后续修改必须谨慎。

### 菜单栏入口

`StatusBarController` 负责菜单栏常驻入口。状态栏 item 必须延迟到 App UI 出现后创建，不要在 `MacScreenApp.init()` 期间创建，否则 macOS 15 上可能在 AppKit/SkyLight 初始化阶段崩溃。

菜单栏当前包含：

- 当前播放、暂停或选择状态
- 显示主窗口
- 添加视频
- 应用当前选择
- 暂停或继续播放
- 下一个动态壁纸
- 停止动态壁纸
- 开机启动
- 启动时恢复上次壁纸
- 低电量时暂停并提醒
- 偏好设置
- 初始化资源
- 打开壁纸网站
- 退出 App

### 偏好设置页

`PreferencesView` 使用 SwiftUI `Settings` 场景承载，集中管理常用设置：

- 开机启动
- 启动时恢复上次壁纸
- 低电量时暂停并提醒
- 下载导入成功后清理源文件
- 查看下载行为和下载目录

菜单栏保留高频操作和设置开关；偏好设置页用于集中解释和管理不需要频繁操作的选项。

### 素材墙界面

主界面当前采用固定尺寸素材墙，而不是左侧列表加右侧大预览：

- 素材卡片固定为 16:9 尺寸，避免不同素材互相挤压或碰撞
- 图片使用 `scaledToFill` 裁切填充，保持卡片尺寸一致
- hover 覆盖层不改变卡片尺寸，只显示在卡片内部
- 卡片外层固定尺寸还不够，图片层、overlay 层、角标层也必须显式使用同一个固定宽高；否则大尺寸素材可能影响内部布局 proposal，导致文字层位置不一致
- hover 覆盖层内部使用固定分区：左侧显示主分类、标题、分辨率和时长；右侧固定收藏和应用按钮。文字只截断，不挤压按钮
- 父视图维护 `hoveredItemID`，保证同一时间只有一个卡片显示 hover 信息
- 顶部提供标题/标签搜索、收藏筛选和自动标签分类
- 分类栏中“全部”和“收藏”固定在最左侧，其他自动分类放在横向滚动区域
- 当前分类刻意收敛为少量主分类：二次元、风景、人物、其他。不要直接把文件名拆出的所有词铺到顶部
- 当筛选或搜索结果为空时展示空状态提示
- 收藏路径存入 `favoriteWallpaperPaths`

后续新增分类数据模型时，可以保留当前自动标签作为 fallback。

### 内置浏览器下载

`InAppBrowserWindowController` 的目标是尽量接近普通浏览器的朴素体验：

- 地址栏会跟随 WebView 当前 URL 更新，也允许用户直接输入地址并回车跳转
- 页面触发下载时不做来源、类型、大小拦截
- 下载文件落到 MacScreen 自己的 Application Support 下载目录，并自动处理重名
- 下载完成后交给 `WallpaperStore.importDownloadedResource` 尝试自动导入
- 主窗口和内置浏览器的明确交互控件应显示小手光标

导入成功后，如果 `cleansDownloadedResourcesAfterImport` 为 true，Store 会删除 Application Support 下载目录中的源文件，避免长期堆积。不要删除用户手动选择导入的原始视频文件。

### 单实例保护

`AppDelegate` 会在启动完成时检查同 bundle identifier 的其他运行实例。如果发现已有实例，会激活已有实例并退出当前实例。这样可以避免用户从 DMG、Downloads、Applications 或开发构建中同时打开多个副本，导致多个桌面窗口互相抢占。

### 开机启动

`LoginItemController` 使用 `SMAppService.mainApp` 注册或取消开机启动。该功能通过菜单栏开关触发，`WallpaperStore` 只维护状态和错误信息。

开机启动失败时，Store 会把错误写入 `errorMessage`，不应让 App 崩溃。

### 低电量暂停

`LowBatteryMonitorController` 通过 IOKit Power Sources API 读取电池状态，默认每 60 秒检查一次。触发条件：

- 用户开启“低电量时暂停并提醒”
- 当前使用电池供电
- 电量小于或等于 `AppConfiguration.lowBatteryPauseThresholdPercent`
- 当前正在播放动态壁纸

触发后会先暂停播放，再弹出 `NSAlert`。用户可以选择：

- 停止壁纸
- 退出应用
- 继续播放

为了避免反复打扰，同一次低电量状态只提醒一次；电量恢复或不再满足低电量条件后，提醒状态会重置。

### 测试

项目现在包含 SwiftPM 测试 target：

```bash
swift test
```

当前测试重点覆盖 `WallpaperStore` 的核心状态行为：

- 根据上次壁纸路径恢复选中项
- 切换下一个动态壁纸并循环回第一个
- 启动时恢复上次壁纸开关
- 低电量暂停开关
- 开机启动开关对 service 的委托
- 下载导入后清理开关
- 收藏路径持久化
- 内置浏览器下载完成后的自动导入流程

不要在单元测试中直接注册系统登录项，测试应通过 mock `WallpaperServicing` 验证 Store 行为。

### 素材卡片 3D hover 动效

素材卡片支持基于鼠标实时坐标的 3D 倾斜动效：

- 鼠标在卡片内移动时，卡片会根据鼠标位置产生 `rotateX`、`rotateY`、`scale` 和 `offset` 变化
- 底图层、文字信息层、操作按钮层分别以不同倍率跟随，制造层次感
- 中心区域设有死区，避免鼠标在中心时卡片轻微抖动
- 鼠标离开后卡片平滑回正
- 工具栏右上角提供开关按钮（`ToolbarToggleButton`），关闭后停用连续鼠标跟踪以减轻卡顿；状态通过 `UserDefaults` 持久化
- 高光效果当前处于"参数保留、渲染禁用"状态，通过 `isHighlightEnabled` 控制
- 所有动效参数集中在 `AppConfiguration.wallpaperCardHover`，可直接调整倾斜角度、偏移量、缩放、阴影、死区等，不对外暴露 UI

### 素材右键菜单

右键素材卡片可弹出上下文菜单，包含：

- 应用
- 暂停 / 继续（仅当前使用中的素材显示）
- 停止（仅当前使用中的素材显示）
- 在 Finder 中查看
- 删除

菜单项的文案和图标配置在 `AppConfiguration.contextMenu` 中，修改标签或图标无需改动 UI 代码。

### 重复导入拦截

`WallpaperLibrary.findDuplicateSourceURLs` 在导入前检测源文件名是否已存在于用户素材目录。两个导入入口（文件选择面板、下载自动导入）都会先检测重复：

- 存在重复则弹窗列出重复文件名并跳过导入
- 无重复则正常导入
- 不与内置素材比对，只检查用户素材目录

### About 和 Help 面板

菜单栏的 About 和 Help 面板走配置文件：

- `AppConfiguration.aboutPanel` 控制标准 About 面板底部补充说明
- `AppConfiguration.helpPanel` 控制 Help 弹窗的菜单标题、弹窗标题、正文和按钮文案

### 偏好设置：打开素材目录

偏好设置 → 通用标签页提供两个按钮：

- "打开用户素材目录"：打开 `~/Library/Application Support/MacScreen/Videos/`
- "打开内置素材目录"：打开 App bundle 内的 `Videos/` 文件夹

用于从源头管理素材文件。

## 维护建议

1. 不要在 App 启动时播放视频

启动阶段只做轻量操作：扫描文件、加载已有缩略图、展示 UI。不要在启动时创建 `AVPlayer` 播放 4K 视频。

2. 自动恢复动态壁纸必须保持可控

自动恢复会让用户打开 App 时立刻铺屏，影响验证和正常工作。当前已经做成菜单栏设置项，并默认关闭。后续不要改成默认开启。

3. 不要直接依赖 Desktop 目录权限

macOS 对 Desktop、Documents、Downloads 有隐私权限限制。当前做法是构建时把资源复制进 App bundle，运行时读 bundle 资源。后续若支持用户自选目录，应使用 `NSOpenPanel` 选择目录，并保存 security-scoped bookmark。

4. 缩略图继续放在构建阶段生成

第一帧抽图是重操作。维护时优先扩展 `Scripts/generate-assets.sh`，不要把批量抽帧放进 App 启动逻辑。

5. 修改桌面窗口层级要小心

窗口层级不对会造成两类问题：

- 太高：挡住正常 App，影响工作
- 太低：看不到动态壁纸

目前使用 `.desktopWindow` 作为 MVP。后续要重点测试 Dock、Mission Control、多桌面、桌面图标、全屏 App。

6. 播放器退出必须清理干净

AVPlayer、AVPlayerItem、AVPlayerLayer、通知 observer、NSWindow 都要在停止或退出时释放干净。否则容易出现退出崩溃或后台残留。

7. SwiftUI 和 AppKit 边界要清晰

SwiftUI 负责主界面和状态展示。AppKit 只负责：

- NSApplication 生命周期补充
- NSWindow 动态壁纸层
- AVPlayerLayer 承载

不要把主窗口再改回手写 `NSWindow`，之前已经验证过容易出现进程启动但窗口不显示的问题。

8. 如果继续工程化，优先加 Xcode project

当前用 `Makefile + SwiftPM` 是为了快速 MVP。后续如果要长期维护，建议生成或手写 `.xcodeproj`，方便：

- Debug
- Signing
- Bundle resources
- App icon 管理
- Archive
- Notarization

9. AppKit 对象创建时机要保守

菜单栏 `NSStatusItem` 这类 AppKit/SkyLight 相关对象不要在 SwiftUI `App` 初始化阶段创建。曾经在 `StatusBarController` 属性初始化时创建 status item，`make run` 会在 macOS 15 上启动即崩溃。正确做法是延迟到 `onAppear` 后配置。

10. 系统能力要包一层

开机启动、低电量监控、下载、更新这类系统能力应放在 controller/service 中，视图层只调用 Store 或闭包。这样便于测试，也能减少系统 API 变化对 UI 的影响。

11. 下载功能要保持直接可用

内置浏览器下载不要增加来源、类型、大小拦截。用户在网页里点击下载后，应直接落盘到应用下载目录；下载完成后再由 Store 尝试导入支持的视频或 zip 资源包。文件名清理、重名处理和导入后清理可以保留，它们用于稳定落盘和避免堆积，不限制用户下载。

## 常用命令

```bash
# 构建并打开
make run

# 只构建
make build

# 打包 DMG
make package

# 运行测试
swift test

# 清理构建产物
make clean

# 重新生成资源
Scripts/generate-assets.sh

# 安装 Xcode 16.4
bash Scripts/install-xcode-16.4.sh
```

## 我们遇到的问题和处理过程

### 1. 一开始代码放错目录

最初工程被创建到了：

```text
/Users/user/Documents/Mac 电脑壁纸软件
```

实际应该放在：

```text
/Users/user/Desktop/project/Mac.screen
```

后来已迁移到正确目录，并删除了错误目录。

### 2. Command Line Tools 的 Swift 环境损坏

最开始机器只有 Command Line Tools，没有完整 Xcode。`swift build` 和 `swiftc import AppKit` 都失败，错误集中在：

```text
redefinition of module 'SwiftBridging'
```

检查发现：

```text
/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap
/Library/Developer/CommandLineTools/usr/include/swift/bridging.modulemap
```

两个文件都声明了 `SwiftBridging`，导致 AppKit/SwiftUI 无法编译。Xcode 16.4 安装完成后，项目使用 SwiftUI 原生版本构建。

### 3. Xcode 安装受系统和账号限制

App Store 里的 Xcode 要求更高系统，而本机是 macOS 15.3.1，所以不能直接装最新版。后来使用 `xcodes` 安装 Xcode 16.4。

安装中遇到过：

```text
403 Unauthorized
Developer Terms and Conditions were not accepted
```

处理方式是登录 Apple Developer 账号并接受协议，然后重新下载。安装完成后，还需要执行 `sudo xcodebuild -license` 接受本地 Xcode license。

### 4. 本地资源看不到

早期 App 左侧为空，原因有几个：

- `.app/Contents/Resources/Videos` 曾经使用符号链接，路径层级写错
- App 直接读 `Desktop/project/.../Videos` 时触发 macOS 桌面文件夹隐私权限
- 用户没有授权时，目录读取会返回空

最终处理方式：

- 构建阶段直接把 `Videos` 复制进 App bundle
- App 运行时优先读取 `Bundle.main.resourceURL/Videos`
- 避免依赖 Desktop 文件夹权限

### 5. UI 布局混乱、不可验证

早期用手写 AppKit split view 和 table view，布局错位，资源列表不可见。后来临时重做过两栏界面，明确显示资源数量、路径、列表和右侧预览。

当前 SwiftUI 版本使用：

```swift
NavigationSplitView
```

左侧是资源列表，右侧是静态预览和操作区。

### 6. 打开 App 导致电脑卡顿

早期版本有几个高负载问题：

- 启动时同步为 4K 视频抽第一帧
- 默认选中第一个资源后自动播放右侧 4K 预览
- 应用桌面壁纸时可能预览和桌面播放器同时解码
- 曾经自动恢复上次动态壁纸，启动即播放

这些都已经移除。现在缩略图在构建阶段生成，App 启动后只加载图片和元数据。

### 7. SwiftUI 窗口不显示

最初 SwiftUI 版本用 `@main AppDelegate` 手动创建 `NSWindow`，编译后进程启动了，但只出现菜单栏，主窗口没有正常显示。

最终改成真正的 SwiftUI 生命周期：

```swift
@main
struct MacScreenApp: App {
    var body: some Scene {
        WindowGroup("MacScreen") {
            ContentView(...)
        }
    }
}
```

这让系统稳定创建主窗口。

### 8. Swift 6 主线程隔离问题

Xcode 16.4 使用的 Swift 编译器会严格检查 `@MainActor`。曾经出现：

```text
call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
```

处理方式：

- `WallpaperStore` 和 `WallpaperWindowController` 保持 `@MainActor`
- SwiftUI App 使用 `@StateObject` 在 SwiftUI 生命周期中创建它们
- AppKit delegate 只做必要生命周期补充

### 9. 状态栏过早创建导致启动崩溃

加入菜单栏常驻入口时，曾经把 `NSStatusBar.system.statusItem` 放在 `StatusBarController` 属性初始化中。`make run` 后 App 在启动阶段崩溃，崩溃栈集中在：

```text
StatusBarController.init()
NSStatusItem _initWithStatusBar
SkyLight CGSConnectionByID
```

处理方式：

- `StatusBarController` 只保存可选的 `NSStatusItem`
- 在 App 主界面 `onAppear` 后调用 `configure`
- `configure` 内部再创建或复用 status item

这类 AppKit 对象创建时机后续也要保持保守。

### 10. 本轮阶段性优化记录

2026-07-10 完成了一轮从 MVP 到常驻工具的基础优化：

- 移除运行时代码中的开发机绝对路径 fallback
- 新增 `AppConfiguration` 集中配置
- 新增 `WallpaperServicing` 和 `DefaultWallpaperService`，隔离业务与 UI
- 新增 SwiftPM 测试 target
- 新增菜单栏常驻入口
- 新增暂停、继续、下一个动态壁纸
- 动态壁纸播放从主屏扩展为所有屏幕同步播放
- 新增单实例保护
- 新增启动时恢复上次壁纸开关
- 新增开机启动开关
- 新增低电量暂停提醒和用户决策弹窗
- 新增偏好设置页
- 新增内置浏览器下载、自动导入和导入后清理

阶段性自测命令：

```bash
swift test
make run
make package
codesign --verify --deep --strict .build/MacScreen.app
```

验证结果：测试、运行、打包和签名校验均通过。低电量弹窗依赖真实电池状态，当前只验证了编译、启动、设置持久化和监控接入。

## 给后续维护者的一句话

这个项目的最大风险不是“能不能播放视频”，而是“播放视频时不要破坏用户正在使用电脑的体验”。任何新功能都应该先问：

- 会不会启动时自动解码 4K 视频？
- 会不会抢焦点？
- 会不会挡住其他窗口？
- 会不会引入退出崩溃？
- 会不会触发 macOS 隐私权限导致资源读不到？

先保证稳定、低负载、可验证，再继续扩展功能。
