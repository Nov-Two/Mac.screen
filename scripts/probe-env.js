'use strict';

/**
 * 环境自检。在动手打包之前跑一遍，可以提前发现大部分环境问题。
 *
 *   node scripts/probe-env.js
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.join(__dirname, '..');

function line(label, value, ok) {
  const mark = ok === undefined ? ' ' : ok ? '✓' : '✗';
  console.log(`  ${mark} ${label.padEnd(34)} ${value}`);
}

function checkFile(relativePath) {
  const full = path.join(ROOT, relativePath);
  const exists = fs.existsSync(full);
  line(relativePath, exists ? `${(fs.statSync(full).size / 1024).toFixed(1)} KB` : '缺失', exists);
  return exists;
}

console.log('\n运行环境');
line('Node', process.version);
line('平台', `${process.platform} / ${process.arch}`);

console.log('\n必需文件');
const required = [
  'package.json',
  'src/main/main.js',
  'src/main/win32.js',
  'src/main/wallpaper-window.js',
  'src/preload/main.js',
  'src/preload/wallpaper.js',
  'src/preload/sensor.js',
  'src/renderer/index.html',
  'src/renderer/app.js',
  'src/renderer/styles.css',
  'src/renderer/wallpaper.html',
  'src/renderer/wallpaper.js',
  'src/renderer/probe.html',
  'src/renderer/sensor.html',
  'src/renderer/sensor.js',
  'assets/materials.json',
  'assets/tray.png',
  'build/icon.ico',
  'build/icon.png',
];
let missing = 0;
for (const file of required) {
  if (!checkFile(file)) missing += 1;
}

console.log('\n依赖');
for (const dep of ['electron', 'koffi', 'extract-zip']) {
  const pkgPath = path.join(ROOT, 'node_modules', dep, 'package.json');
  if (fs.existsSync(pkgPath)) {
    const version = JSON.parse(fs.readFileSync(pkgPath, 'utf8')).version;
    line(dep, version, true);
  } else {
    line(dep, '未安装（先执行 npm install）', false);
  }
}

console.log('\nkoffi 原生绑定');
try {
  const koffi = require(path.join(ROOT, 'node_modules', 'koffi'));
  line('koffi 版本', koffi.version || '未知', true);

  // 校验 win32.js 用到的类型名在当前 koffi 版本下是否可解析
  const typeNames = ['void *', 'str16', 'int32_t', 'uint32_t', 'uintptr_t', 'intptr_t', 'int64_t'];
  for (const name of typeNames) {
    try {
      koffi.sizeof(name);
      line(`类型 ${name}`, '可用', true);
    } catch (error) {
      line(`类型 ${name}`, error.message, false);
    }
  }

  // 校验回调原型注册（EnumWindows 依赖它）
  try {
    const proto = koffi.proto('EnumWindowsProc', 'bool', ['void *', 'intptr_t']);
    koffi.pointer(proto);
    line('回调原型注册', '可用', true);
  } catch (error) {
    line('回调原型注册', error.message, false);
  }
} catch (error) {
  line('koffi 加载', error.message, false);
}

console.log('\nWindows 打包所需的原生二进制');
// koffi 的平台包受 os/cpu 字段限制，在 macOS 上极易被静默跳过，
// 结果就是打出来的 Windows 包缺少 user32.dll 调用能力。这里必须显式校验。
const winFfi = path.join(
  ROOT,
  'node_modules',
  '@koromix',
  'koffi-win32-x64',
  'win32_x64',
  'koffi.node'
);
if (fs.existsSync(winFfi)) {
  line('@koromix/koffi-win32-x64', `${(fs.statSync(winFfi).size / 1048576).toFixed(1)} MB`, true);
} else {
  line('@koromix/koffi-win32-x64', '缺失！Windows 包无法挂载桌面层', false);
  console.log('    → 确认 package.json 的 dependencies 里有它，且根目录 .npmrc 写着 force=true，');
  console.log('      然后重新执行 npm install。详见 README「必读：koffi 原生二进制与 .npmrc」。');
  missing += 1;
}
try {
  const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8'));
  const unpack = (pkg.build && pkg.build.asarUnpack) || [];
  const ok = unpack.some((pattern) => pattern.includes('@koromix'));
  line('asarUnpack 含 @koromix', ok ? '是' : '否（.node 将无法从 asar 加载）', ok);
  if (!ok) missing += 1;
} catch (error) {
  line('读取 package.json 的 build 配置', error.message, false);
}

console.log('\n素材清单');
try {
  const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets', 'materials.json'), 'utf8'));
  const total = manifest.items.reduce((sum, item) => sum + item.size, 0);
  line('条目数', String(manifest.items.length), manifest.items.length > 0);
  line('合计体积', `${(total / 1048576).toFixed(1)} MB`);
} catch (error) {
  line('读取失败', error.message, false);
}

console.log('\n内置素材目录');
const videosDir = path.join(ROOT, 'videos');
const videos = fs.existsSync(videosDir)
  ? fs.readdirSync(videosDir).filter((name) => /\.(mp4|mov|m4v|webm)$/i.test(name))
  : [];
line('videos/ 中的视频', `${videos.length} 个`);
if (videos.length === 0) {
  console.log('    （为空也可以，用户可在应用内「在线素材」页按需下载）');
}

console.log('\n桌面层能力');
if (process.platform === 'win32') {
  const win32 = require(path.join(ROOT, 'src', 'main', 'win32.js'));
  const info = win32.describe();
  line('user32 可用', String(info.available), info.available);
  if (info.error) line('错误', info.error, false);
  const host = win32.findWallpaperHost();
  line('桌面宿主窗口', host ? `找到 (${win32.classNameOf(host)})` : '未找到', Boolean(host));
} else {
  console.log('    当前不是 Windows，桌面层挂载不可用；应用会以全屏预览窗口运行。');
}

console.log(`\n结论：${missing === 0 ? '文件齐备。' : `缺少 ${missing} 个文件。`}`);
console.log(`构建机：${os.type()} ${os.release()} ${os.arch()}\n`);
