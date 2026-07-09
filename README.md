# MacScreen

MacScreen 是一个 macOS 动态壁纸 MVP。当前版本使用 **SwiftUI + AppKit + AVFoundation** 实现，读取工程内的本地 mp4 视频资源，左侧显示资源列表和第一帧缩略图，右侧显示静态预览，点击“应用到桌面”后把选中视频静音循环播放到桌面背景层。

这个项目当前优先目标不是完整商业产品，而是验证最小闭环：

- 能扫描本地动态壁纸资源
- 能看到可选资源和缩略图
- 能选择一个资源
- 能把视频应用为动态桌面
- 不影响用户正常工作，不默认播放 4K 视频

## 当前状态

- 主实现：`Sources/MacScreen`
- 运行方式：`make run`
- 构建产物：`.build/MacScreen.app`
- 视频素材：`Videos/*.mp4`
- 视频缩略图：`Assets/Thumbnails/*.png`
- 应用图标源：`Assets/AppIcon/icon.png`
- 应用图标产物：`Assets/AppIcon/MacScreenIcon.icns`
- 最低系统：macOS 14+
- 推荐开发环境：macOS 15.3.1 + Xcode 16.4

## 项目结构

```text
.
├── App/
│   └── Info.plist                  # App bundle 信息、图标配置、版本号
├── Assets/
│   ├── AppIcon/                    # 图标源文件和生成的 .icns
│   └── Thumbnails/                 # 构建阶段生成的视频第一帧缩略图
├── Scripts/
│   ├── generate-assets.sh          # 生成缩略图和 .icns 图标
│   └── install-xcode-16.4.sh       # 安装 Xcode 16.4 的辅助脚本
├── Sources/
│   └── MacScreen/
│       ├── MacScreenApp.swift      # SwiftUI App 入口，使用 WindowGroup
│       ├── AppDelegate.swift       # AppKit 生命周期补充
│       ├── ContentView.swift       # 主界面：左侧列表、右侧静态预览和操作区
│       ├── WallpaperLibrary.swift  # 扫描 Videos、读取视频信息和缩略图
│       ├── WallpaperStore.swift    # SwiftUI 状态管理
│       ├── WallpaperWindowController.swift # 桌面动态壁纸窗口控制
│       ├── PlayerView.swift        # AVPlayerLayer 承载视图
│       ├── WallpaperItem.swift     # 壁纸资源模型
│       └── UserDefaultsKeys.swift
├── Videos/                         # 本地 mp4 动态壁纸资源
├── Makefile                        # 构建、运行、清理
├── Package.swift                   # SwiftPM 元数据
```

## 基础准备

1. 安装 Xcode 16.4

当前机器是 macOS 15.3.1。App Store 里的最新版 Xcode 要求更高系统，不能直接安装。因此项目使用 `xcodes` 安装 Xcode 16.4 到用户目录：

```bash
bash Scripts/install-xcode-16.4.sh
```

安装过程中可能需要 Apple ID、双重认证验证码，以及 Apple Developer 协议确认。

2. 接受 Xcode license

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

3. 准备视频资源

把 mp4 动态壁纸放在工程根目录的 `Videos` 下。当前项目已有 8 个 mp4，主要是 H.264，部分是 4K 分辨率。

4. 准备应用图标

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

打包为内部使用的 DMG：

```bash
make package
```

产物位于：

```text
dist/MacScreen.dmg
```

`dist/` 是本地生成产物，不提交到 Git。需要给同事安装时，可以本地执行 `make package`，也可以推送版本 tag 后让 GitHub Actions 自动构建并上传 DMG 到 GitHub Release。

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
- 把 `Videos`、`Thumbnails`、`MacScreenIcon.icns` 打包进 `.build/MacScreen.app/Contents/Resources`

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

构建脚本会自动为新视频生成缩略图，并把视频复制进 App bundle。新增后建议把 `Videos/*.mp4` 和生成的 `Assets/Thumbnails/*.png` 一起提交到 Git。

用户也可以在 App 内点击“添加视频”，导入自己的本地视频作为动态壁纸素材。导入的视频会复制到当前用户的 Application Support 目录：

```text
~/Library/Application Support/MacScreen/Videos/
```

这类用户自定义素材不会写回代码仓库，也不需要重新打包。当前支持 `mp4`、`mov`、`m4v` 视频文件。

用户可以选中素材后点击“删除素材”。按住 Command 可多选素材并批量删除。自定义上传的视频会删除本地文件；内置默认素材不会物理删除 App 包内文件，只会从当前用户的素材列表中移除。删除确认弹窗支持“下次不再提醒”。

## 内部分发

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

当前 DMG 体积主要来自内置视频资源。`Videos/` 约 260MB，而 DMG 已经使用压缩格式生成；要明显减小安装包，需要减少内置视频数量，或改成轻量 App 加用户自行导入/在线下载资源。

如果同事打开时被 macOS 提示无法验证开发者，右键 App 选择“打开”通常可以绕过。更正式的公司内部分发建议后续增加 Developer ID 签名和 Apple notarization。

## 运行策略

为了避免影响正常工作，当前版本刻意采用低负载策略：

- App 启动时不自动播放视频
- App 启动时不自动恢复上次动态壁纸
- 右侧只显示静态预览图，不播放 4K 视频
- 缩略图在构建阶段生成，不在 App 启动阶段同步抽帧
- 点击“应用到桌面”后才创建 AVPlayer 播放视频
- 当前 MVP 只应用主屏，不做多屏同时播放
- 退出时会停止播放器并关闭动态壁纸窗口

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

App Store 里的 Xcode 要求 macOS 26.2 或更高，而本机是 macOS 15.3.1，所以不能直接装最新版。后来使用 `xcodes` 安装 Xcode 16.4。

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

- 启动时同步为 8 个 4K 视频抽第一帧
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

### 9. Swift 6 主线程隔离问题

Xcode 16.4 使用的 Swift 编译器会严格检查 `@MainActor`。曾经出现：

```text
call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
```

处理方式：

- `WallpaperStore` 和 `WallpaperWindowController` 保持 `@MainActor`
- SwiftUI App 使用 `@StateObject` 在 SwiftUI 生命周期中创建它们
- AppKit delegate 只做必要生命周期补充

## 当前实现说明

### 资源扫描

`WallpaperLibrary` 会按优先级找视频目录：

1. App bundle 里的 `Resources/Videos`
2. 当前工作目录下的 `Videos`
3. 开发机固定路径 `/Users/user/Desktop/project/Mac.screen/Videos`

正常构建后的 App 应该走第一项。

### 缩略图

缩略图文件名格式：

```text
原视频文件名.mp4.png
```

例如：

```text
Videos/090F9225-...mp4
Assets/Thumbnails/090F9225-...mp4.png
```

运行时优先读取 App bundle 中的 `Resources/Thumbnails`。如果读取失败，当前代码还有一个运行时兜底抽帧逻辑，但维护时应尽量保证构建阶段生成好缩略图，避免启动阶段解码视频。

### 动态壁纸窗口

`WallpaperWindowController` 负责创建桌面播放窗口：

- 只使用主屏
- 无边框
- 忽略鼠标事件
- 静音播放
- 循环播放
- 窗口层级使用 `desktopWindow`

这部分是动态壁纸 MVP 的核心，也是最容易影响系统体验的地方。后续修改必须谨慎。

## 维护建议

1. 不要在 App 启动时播放视频

启动阶段只做轻量操作：扫描文件、加载已有缩略图、展示 UI。不要在启动时创建 `AVPlayer` 播放 4K 视频。

2. 不要在 App 启动时自动恢复动态壁纸

自动恢复会让用户打开 App 时立刻铺屏，影响验证和正常工作。后续如果要加恢复功能，必须做成设置项，并默认关闭。

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

当前用 `Makefile + swiftc` 是为了快速 MVP。后续如果要长期维护，建议生成或手写 `.xcodeproj`，方便：

- Debug
- Signing
- Bundle resources
- App icon 管理
- Archive
- Notarization

## 常用命令

```bash
# 构建并打开
make run

# 只构建
make build

# 清理构建产物
make clean

# 重新生成资源
Scripts/generate-assets.sh

# 安装 Xcode 16.4
bash Scripts/install-xcode-16.4.sh
```

## 后续功能方向

- 自定义资源目录
- 菜单栏常驻
- 暂停/继续动态壁纸
- 多屏独立选择壁纸
- 开机启动
- 分类、收藏、搜索
- 正式 `.app` 打包、签名、公证
- 性能监控和低电量自动暂停

## 给后续维护者的一句话

这个项目的最大风险不是“能不能播放视频”，而是“播放视频时不要破坏用户正在使用电脑的体验”。任何新功能都应该先问：

- 会不会启动时自动解码 4K 视频？
- 会不会抢焦点？
- 会不会挡住其他窗口？
- 会不会引入退出崩溃？
- 会不会触发 macOS 隐私权限导致资源读不到？

先保证稳定、低负载、可验证，再继续扩展功能。
