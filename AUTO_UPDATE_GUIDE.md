# MacScreen 自动更新发布指南

这份文档说明如何配置和发布 MacScreen 的自动更新。项目已经接入 Sparkle 2，后续你发布新版本时，用户本地 App 可以像普通 macOS App 一样检查、下载并安装更新。

## 1. 生成 Sparkle 公钥和私钥

先进入项目目录：

```bash
cd /Users/user/Desktop/project/Mac.screen
```

先构建一次，让项目下载 Sparkle：

```bash
make build
```

找到 Sparkle 工具目录：

```bash
SPARKLE_BIN="$(find .build/artifacts -path '*/Sparkle/bin' -type d -print -quit)"
echo "$SPARKLE_BIN"
```

如果输出类似下面这样，说明正常：

```text
.build/artifacts/sparkle/Sparkle/bin
```

然后生成 Sparkle 密钥：

```bash
"$SPARKLE_BIN/generate_keys"
```

命令会输出类似：

```xml
<key>SUPublicEDKey</key>
<string>xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=</string>
```

你需要保存的是 `<string>` 里面那一串内容，它就是 Sparkle 公钥。

把公钥写入本地配置文件：

```bash
printf '%s' '这里替换为你的公钥字符串' > .sparkle-public-ed-key
```

`.sparkle-public-ed-key` 已经加入 `.gitignore`，不会被提交到 Git。

接着导出 Sparkle 私钥：

```bash
"$SPARKLE_BIN/generate_keys" -x sparkle-private-key.txt
```

这会生成：

```text
sparkle-private-key.txt
```

这个文件是 Sparkle 私钥，用来签名更新包。不要提交到 Git，不要公开发送给别人。

查看私钥内容：

```bash
cat sparkle-private-key.txt
```

后面配置 GitHub Secrets 时需要复制这个内容。

## 2. 配置 GitHub Actions Secrets

打开 GitHub 仓库：

```text
https://github.com/Nov-Two/Mac.screen
```

进入：

```text
Settings -> Secrets and variables -> Actions
```

点击：

```text
New repository secret
```

添加第一个 Secret：

```text
Name:
SPARKLE_PUBLIC_ED_KEY

Secret:
第 1 步 generate_keys 输出的公钥字符串
```

也就是你写入 `.sparkle-public-ed-key` 的那一串。

再添加第二个 Secret：

```text
Name:
SPARKLE_PRIVATE_ED_KEY

Secret:
sparkle-private-key.txt 文件里的完整内容
```

可以用下面命令查看并复制：

```bash
cat sparkle-private-key.txt
```

配置完成后，GitHub Actions secrets 里应该能看到这两个名字：

```text
SPARKLE_PUBLIC_ED_KEY
SPARKLE_PRIVATE_ED_KEY
```

GitHub 不会显示 Secret 的具体值，这是正常现象。

## 3. 开启 GitHub Pages

App 内的自动更新源已经配置为：

```text
https://nov-two.github.io/Mac.screen/appcast.xml
```

所以需要开启 GitHub Pages。

在 GitHub 仓库里进入：

```text
Settings -> Pages
```

找到：

```text
Build and deployment
```

设置为：

```text
Source: Deploy from a branch
Branch: gh-pages
Folder: / root
```

然后保存。

第一次配置时，可能还没有 `gh-pages` 分支。没关系，等第一次发布 tag 后，GitHub Actions 会自动创建 `gh-pages` 分支，并发布 `appcast.xml`。

发布成功后，可以访问：

```text
https://nov-two.github.io/Mac.screen/appcast.xml
```

如果能看到 XML 内容，说明自动更新源已经生效。

## 4. 发布一个新版本

假设当前版本是：

```text
0.1.0
```

你做了新功能，准备发布：

```text
0.1.1
```

先打开：

```text
App/Info.plist
```

修改这两个版本号：

```xml
<key>CFBundleShortVersionString</key>
<string>0.1.1</string>

<key>CFBundleVersion</key>
<string>2</string>
```

版本号规则：

```text
CFBundleShortVersionString：给用户看的版本号，比如 0.1.1
CFBundleVersion：内部构建号，每次发布必须递增，比如 1 -> 2 -> 3
```

然后更新：

```text
CHANGELOG.md
```

写清楚这次新增了什么功能、修复了什么问题，例如：

```md
## 2026-07-09

- 新增自动更新功能。
- 新增某个壁纸体验功能。
- 修复某个已知问题。
```

本地可以先打包确认：

```bash
make package
```

确认没问题后提交并推送：

```bash
git add .
git commit -m "Release 0.1.1"
git push origin main
```

然后打 tag 发布：

```bash
git tag v0.1.1
git push origin v0.1.1
```

推送 tag 后，GitHub Actions 会自动执行：

```text
1. 构建 MacScreen.app
2. 打包 dist/MacScreen.dmg
3. 上传 DMG 到 GitHub Release
4. 使用 SPARKLE_PRIVATE_ED_KEY 签名更新包
5. 生成 appcast.xml
6. 发布 appcast.xml 到 GitHub Pages
```

用户本地旧版本 App 打开后，点击菜单：

```text
MacScreen -> 检查更新...
```

就会看到新版本提示。用户确认后，Sparkle 会下载新版 DMG，并完成本地 App 更新。

## 注意事项

- 每次发布新版本时，`CFBundleVersion` 必须递增。
- Sparkle 私钥不能提交到 Git。
- GitHub Secrets 里的公钥和私钥必须同时配置。
- 如果没有配置 Sparkle 密钥，本地 App 菜单里仍会显示“检查更新...”，但会提示暂未配置自动更新。
- 正式分发给用户时，最好配好 Apple Developer ID 签名和 notarization，这样用户安装和更新体验会更顺畅。
