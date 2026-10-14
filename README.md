# WinScreen

**Windows 桌面动态壁纸应用** —— 基于 Electron 重写的 [MacScreen](https://github.com/Nov-Two/Mac.screen)。

把本地视频静音循环播放到 Windows 桌面图标**层之下**，不抢焦点、不遮挡任何正在使用的窗口，
按 `Win+D` 也不会被盖掉，鼠标点击照常穿透到桌面图标。

---

## 目录

- [它做了什么](#它做了什么)
- [技术实现](#技术实现)
- [快速开始](#快速开始)
- [打包分发](#打包分发)
- [项目结构](#项目结构)
- [功能对照表](#功能对照表)
- [已知限制](#已知限制)
- [常见问题](#常见问题)

---

## 它做了什么

| 能力 | 说明 |
| --- | --- |
| 桌面层播放 | 视频在桌面图标下方播放，不是"全屏窗口挡住桌面"的伪壁纸 |
| 素材库 | 内置素材 + 用户导入素材统一管理，自动生成缩略图与元数据 |
| 素材墙 | 搜索、分类筛选、收藏、3D 悬停动效、右键菜单 |
| 在线素材 | 内置原作者的素材清单，点选即可下载并自动导入（约 460MB，按需下载） |
| 托盘常驻 | 关闭主窗口后继续运行，播放控制、音量、设置全部可在托盘完成 |
| 播放控制 | 应用 / 暂停 / 继续 / 下一个 / 停止 / 音量 / 画面铺满方式 |
| 导入校验 | 默认只接受 1920×1080 及以上的视频，可跳过；支持 zip 资源包自动解包 |
| 系统集成 | 开机自启、启动时恢复上次壁纸、低电量自动暂停、休眠自动暂停 |
| 自动更新 | 接入 electron-updater，配置发布地址后可在应用内检查更新 |

---

## 技术实现

### 一、桌面层挂载（本项目最关键的部分）

Windows 的桌面其实由两层窗口叠成：

```
   ┌──────────────────────────────┐
   │  Progman（桌面图标层）        │  ← 图标、右键菜单在这一层
   ├──────────────────────────────┤
   │  WorkerW（壁纸层）            │  ← 视频挂在这里
   └──────────────────────────────┘
```

实现步骤（`src/main/win32.js`）：

1. `FindWindowW("Progman", null)` 找到桌面窗口；
2. 向它发送未公开消息 `0x052C`，系统会派生出一个位于图标层之下的 `WorkerW`；
3. `EnumWindows` 遍历顶层窗口，找到挂着 `SHELLDLL_DefView`（图标层）的那一层，
   紧随其后的 `WorkerW` 就是可以铺视频的宿主窗口；
4. `SetParent(壁纸窗口句柄, WorkerW)`，再用 `SetWindowPos` 铺满目标区域。

同时做两件事保证"不打扰用户"：

- 给窗口加上 `WS_EX_TOOLWINDOW`、去掉 `WS_EX_APPWINDOW`，让它不出现在任务栏和 `Alt+Tab`；
- `win.setIgnoreMouseEvents(true)`，所有鼠标事件穿透到桌面图标。

**三级降级**：找不到独立 `WorkerW` 时改用 `Progman` 本身当宿主；仍然失败则退化为
"全屏置底窗口"模式，并在界面上明确提示用户。

全部通过 [`koffi`](https://koffi.dev/) 直接调用 `user32.dll`，**不需要编译任何原生插件**，
也不需要 Visual Studio 构建工具链。

### 二、为什么不用 ffmpeg

生成缩略图和读取时长需要解码视频。常规做法是打包 `ffmpeg-static`（约 80MB），
本项目改用**隐藏的 BrowserWindow + Chromium 自带解码器**（`src/main/media-probe.js`）：

- 隐藏窗口加载 `probe.html`，把视频 seek 到第 3 秒；
- 画进 `<canvas>` 并 `toDataURL()` 取一帧，落盘成 PNG；
- 元数据（时长、分辨率）顺便从 `video` 元素读出来。

体积代价接近 0，且 Windows 上无需额外分发可执行文件。

### 三、自定义协议 `wsmedia://`

直接把 `file://` 丢给渲染进程会遇到三个坑：跨域导致 canvas 被污染（缩略图导不出来）、
`<img>` 读不到本地图片、大视频无法拖动进度。所以注册了一个标准安全协议
（`src/main/protocol.js`）：

| URL | 用途 |
| --- | --- |
| `wsmedia://app/index.html` | 界面静态文件 |
| `wsmedia://asset/icon.png` | 图标等资源 |
| `wsmedia://media/<编码后的绝对路径>` | 本地视频 / 缩略图 |

协议处理器**自己实现了 HTTP Range**（`206 Partial Content`），因此 40MB 的视频可以
边下边播、随意拖进度条。副作用是所有页面与视频同源，**不需要关闭 `webSecurity`**。

### 四、低电量检测

Electron 主进程没有电池电量 API。项目用一个常驻的隐藏页面
（`src/renderer/sensor.html`）通过 `navigator.getBattery()` 采集，每 60 秒回报主进程，
低于阈值时自动暂停壁纸并弹窗让用户选择。

---

## 快速开始

```bash
npm install
npm start          # 启动应用
npm run probe      # 环境自检（打包前建议先跑一遍）
```

> **开发说明**：在 macOS / Linux 上运行时，`user32.dll` 不存在，桌面层挂载自动降级为
> "无边框全屏窗口"预览模式，用于验证界面与播放逻辑。**桌面层效果必须在 Windows 上验证。**

### 让素材库有内容

安装包已预置 **1 个示例素材**，装完即可「应用到桌面」。想扩充有三种方式：

```bash
# 1. 应用内「在线素材」页 → 点「下载」（推荐）
# 2. 应用内「添加视频」按钮或直接把视频拖进窗口
# 3. 命令行批量拉取到内置素材目录
npm run fetch -- --limit 3
```

---

## 打包分发

### 在 Windows 上打包（推荐）

```bash
npm run dist:win        # 同时产出 NSIS 安装包 + 便携版 + 免安装 zip
npm run dist:zip        # 只出免安装 zip
npm run dist:portable   # 只出单文件便携版
npm run dist:dir        # 只出未打包目录，用于快速验证
```

产物在 `dist/`：

| 文件 | 说明 |
| --- | --- |
| `WinScreen-1.0.0-x64.exe` | NSIS 安装包，可选安装路径，带开始菜单与桌面快捷方式 |
| `WinScreen-1.0.0-portable.exe` | 单文件便携版，双击即用 |
| `WinScreen-1.0.0-x64.zip` | 免安装压缩包，解压后运行 `WinScreen.exe` |

### 在 macOS / Linux 上交叉打包

```bash
npm run dist:dir        # ✓ 可用：产出未打包的 Windows 目录
npm run dist:zip        # ✓ 可用：产出免安装 zip
npm run dist:win        # ✗ NSIS 需要 Wine，macOS 上会失败
```

跨平台打包 NSIS 需要额外安装 Wine（`brew install --cask wine-stable`），
不推荐。**正式分发请在 Windows 机器或 Windows CI 上执行。**

### ⚠️ 必读：koffi 原生二进制与 `.npmrc`

这是本项目最容易踩的坑，删掉任何一处都会导致「Windows 用户装完发现桌面层挂载失效」：

`koffi` 把各平台的原生二进制拆成独立包（`@koromix/koffi-<os>-<arch>`），
并在其中写了 `os` / `cpu` 字段。npm 默认只装与**当前机器**匹配的那一个。
在 macOS 上开发时，Windows 用的 `@koromix/koffi-win32-x64` 会被静默跳过，
打出来的包里就只有 `darwin_arm64/koffi.node`——**缺少调用 `user32.dll` 的二进制**，
用户机器上 `koffi.load('user32.dll')` 直接抛错，壁纸只能退化到"置底窗口"模式。

所以：

1. `package.json` 把 `@koromix/koffi-win32-x64` 显式列入 `dependencies`；
2. 项目根目录的 `.npmrc` 写了 `force=true`，否则普通 `npm install` 会因
   `EBADPLATFORM` 直接报错（该包声明了 `os: ["win32"]`）；
3. `build.asarUnpack` 必须包含 `**/node_modules/@koromix/**`——`.node` 文件
   无法从 asar 内加载，必须解包到磁盘。

**打包后自检**（在 macOS 上交叉打包时建议每次都跑）：

```bash
ls dist/win-unpacked/resources/app.asar.unpacked/node_modules/@koromix/
# 期望看到 koffi-win32-x64/win32_x64/koffi.node
```

`npm run probe` 也会检查这一项。

### 关于开机自启

开机自启写入 `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`，依赖
`process.execPath` 稳定存在。**便携版每次运行会解压到临时目录，路径不固定，因此
开机自启只对安装版有效**——便携版请手动把快捷方式放进
`shell:startup` 目录。

### 自动更新

1. 把 `package.json` 里 `build.publish[0].url` 改成你自己的发布地址；
2. 构建时带上发布参数：`electron-builder --win --publish always`；
3. 把产物与 `latest.yml` 一起上传到该地址。

未配置发布地址时，应用内的「检查更新」会提示不可用，不影响其它功能。

### 代码签名

未签名的安装包在 Windows 上会触发 SmartScreen 警告（"Windows 已保护你的电脑" →
点"更多信息"→"仍要运行"）。正式对外分发建议购买代码签名证书，在
`build.win` 下配置 `certificateFile` / `certificatePassword`。

---

## 项目结构

```
.
├── package.json                electron-builder 打包配置
├── assets/
│   ├── materials.json          在线素材清单（npm run materials 可重新生成）
│   ├── tray.png / tray@2x.png  托盘图标
├── build/
│   ├── icon.ico                Windows 图标（多尺寸，npm run icons 可重新生成）
│   └── icon.png                512×512 备用
├── videos/                     内置素材目录（预置 1 个示例，见 videos/README.md）
├── scripts/
│   ├── build-icons.js          纯 Node 绘制并打包图标，零依赖
│   ├── build-materials.js      从 GitHub 重新生成素材清单
│   ├── fetch-materials.js      批量下载素材到 videos/
│   └── probe-env.js            环境自检
└── src/
    ├── main/                   主进程
    │   ├── main.js             入口：协议注册、单实例、窗口生命周期
    │   ├── config.js           路径与常量集中配置
    │   ├── settings.js         JSON 设置持久化（原子写入 + 延迟合并）
    │   ├── protocol.js         wsmedia:// 协议 + HTTP Range 实现
    │   ├── win32.js            ★ WorkerW 桌面层挂载（koffi 调用 user32）
    │   ├── media-probe.js      隐藏窗口探测元数据 + 生成缩略图
    │   ├── library.js          素材库：扫描 / 导入 / 删除 / 元数据缓存
    │   ├── wallpaper-window.js ★ 壁纸窗口控制器
    │   ├── service.js          业务编排层
    │   ├── online.js           在线素材清单与流式下载
    │   ├── tray.js             托盘菜单
    │   ├── power.js            低电量监控
    │   ├── login-item.js       开机自启
    │   ├── updater.js          自动更新
    │   └── ipc.js              IPC 路由
    ├── preload/                contextBridge 桥接
    │   ├── main.js  wallpaper.js  sensor.js
    └── renderer/               界面（原生 HTML/CSS/JS，无构建步骤）
        ├── index.html  app.js  styles.css
        ├── wallpaper.html  wallpaper.js
        ├── probe.html       缩略图探测页
        └── sensor.html  sensor.js  电量采集页
```

---

## 功能对照表

| MacScreen（SwiftUI） | WinScreen（Electron） | 状态 |
| --- | --- | --- |
| 桌面层播放（`desktopWindow` 窗口层级） | WorkerW 挂载 | ✅ 等价 |
| 多屏同步播放 | 单窗口铺满主显示器 / 可切换铺满全部显示器 | ✅ |
| 素材墙 + 搜索 + 分类 + 收藏 | 同 | ✅ |
| 3D 悬停动效 | CSS transform 实现 | ✅ |
| 静态缩略图预览 | 隐藏窗口截图生成 | ✅ |
| 视频导入（分辨率校验、重名处理） | 同（额外支持竖屏 1080×1920） | ✅ |
| zip 资源包导入 | extract-zip 解包 | ✅ |
| 菜单栏常驻 | 系统托盘 | ✅ |
| 音量控制 | 主窗口 + 托盘 | ✅ |
| 低电量暂停 | Battery API + 隐藏采集页 | ✅ |
| 开机自启 | 注册表 Run 键 | ✅ |
| 启动时恢复上次壁纸 | 同 | ✅ |
| 删除自定义素材 / 隐藏内置素材 / 恢复 | 同 | ✅ |
| 内置浏览器下载素材 | 「在线素材」页 + 流式下载进度 | ✅ 改进 |
| 桌面上的音量浮层 | 由主窗口与托盘承担 | ⚠️ 差异 |
| Sparkle 自动更新 | electron-updater | ✅ |
| DMG 打包 | NSIS / 便携版 / zip | ✅ |

---

## 已知限制

1. **桌面层效果无法在 macOS 上验证**。`SetParent` / WorkerW 是 Windows 专属行为，
   本项目在 macOS 上只能验证界面、素材库、缩略图与播放逻辑。
   **首次分发前请在 Windows 上跑一次 `npm run probe` 并实际应用一次壁纸。**
2. **视频编码依赖 Chromium 解码能力**。H.264 / VP8 / VP9 / AV1 可用；
   HEVC(H.265) 与部分 MKV 封装可能无法播放，导入后表现为缩略图空白。
3. **多显示器只做单窗口铺满**，没有实现"每块屏幕独立选壁纸"。
4. **便携版不支持开机自启**（临时解压路径不固定）。
5. **桌面右键菜单**：极少数系统（Win11 24H2 某些版本）会派生多个 WorkerW，
   若出现壁纸被图标层覆盖，请把 `spanAllDisplays` 关闭后重试并反馈日志。

---

## 常见问题

**Q：点"应用到桌面"后桌面没有变化？**
先确认托盘菜单里显示"正在播放"。若提示"已退化为置底窗口"，说明 WorkerW 挂载失败：
确认系统是 Windows 10/11，并检查是否运行了其他壁纸软件（Wallpaper Engine、
Lively、动态壁纸大师等）——它们会争抢同一个 WorkerW，请先退出其中之一。

**Q：壁纸在但桌面图标不见了？**
不会发生。图标层（`SHELLDLL_DefView`）始终在壁纸层之上。若异常，在任务管理器里
重启"Windows 资源管理器"即可恢复。

**Q：播放卡顿 / CPU 占用高？**
把 4K 素材换成 1080p；或在设置里关掉"卡片 3D 悬停动效"；音量保持 0 也能省一点。
视频解码已走 GPU（`enable-accelerated-video-decode`），若显卡驱动过旧可尝试关闭。

**Q：导入时提示"已跳过低分辨率视频"？**
默认门槛是 1920×1080。在设置里打开"跳过分辨率校验"即可导入任意分辨率。

**Q：怎么彻底卸载？**
先通过托盘菜单退出应用，再用控制面板卸载。用户素材与设置保存在
`%APPDATA%\WinScreen\`，卸载时不会自动删除，需要手动清理。

---

## 许可

MIT。动态壁纸素材版权归原作者所有，本项目不分发素材文件，仅提供下载入口。
