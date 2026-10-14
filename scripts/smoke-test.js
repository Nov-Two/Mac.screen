'use strict';

/**
 * 端到端冒烟测试（用 Electron 直接运行）：
 *
 *   npx electron scripts/smoke-test.js
 *
 * 会真实地跑一遍核心链路并输出结果：
 *   协议注册 → 媒体探测/缩略图 → 素材库扫描 → 壁纸窗口应用 → 主界面渲染截图
 *
 * 测试使用独立的临时 userData 目录，不会污染正式数据。
 * 非 Windows 平台会以「预览模式」创建壁纸窗口，用于验证播放链路。
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { app, BrowserWindow, net } = require('electron');

const ROOT = path.join(__dirname, '..');
const RENDERER_DIR = path.join(ROOT, 'src', 'renderer');
const ASSETS_DIR = path.join(ROOT, 'assets');
const SHOT_PATH = path.join(os.tmpdir(), 'winscreen-smoke-shot.png');

const TMP_USER_DATA = fs.mkdtempSync(path.join(os.tmpdir(), 'winscreen-smoke-'));
app.setPath('userData', TMP_USER_DATA);
app.setName('WinScreenSmoke');

const config = require(path.join(ROOT, 'src', 'main', 'config'));
const protocolModule = require(path.join(ROOT, 'src', 'main', 'protocol'));

protocolModule.registerScheme();
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
// 受限环境（CI / 容器）里 Chromium 沙箱可能起不来，测试时关掉；
// 正式应用不设置这两个开关。
app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('disable-gpu-sandbox');

const results = [];

function check(name, ok, detail = '') {
  results.push({ name, ok });
  console.log(`${ok ? '  PASS' : '  FAIL'}  ${name}${detail ? `  →  ${detail}` : ''}`);
}

function section(title) {
  console.log(`\n${title}`);
}

async function main() {
  protocolModule.registerHandler({ rendererDir: RENDERER_DIR, assetsDir: ASSETS_DIR });

  const { SettingsStore } = require(path.join(ROOT, 'src', 'main', 'settings'));
  const { MediaProbe } = require(path.join(ROOT, 'src', 'main', 'media-probe'));
  const { WallpaperService } = require(path.join(ROOT, 'src', 'main', 'service'));
  const { OnlineMaterials } = require(path.join(ROOT, 'src', 'main', 'online'));
  const { registerIpc } = require(path.join(ROOT, 'src', 'main', 'ipc'));
  const win32 = require(path.join(ROOT, 'src', 'main', 'win32'));

  let mainWindow = null;
  const broadcast = (channel, payload) => {
    if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(channel, payload);
  };

  const settings = new SettingsStore(config.settingsFile());
  const probe = new MediaProbe();
  const service = new WallpaperService({ settings, probe, emit: broadcast });
  const online = new OnlineMaterials({ library: service.library, settings, emit: broadcast });

  /* ---------- 1. 协议 ---------- */
  section('1. 自定义协议 wsmedia://');

  const cssResponse = await net.fetch('wsmedia://app/styles.css');
  check('静态文件可读', cssResponse.status === 200, `HTTP ${cssResponse.status}`);

  const sampleVideo = findSampleVideo();
  check('找到测试素材', Boolean(sampleVideo), sampleVideo || '（videos/ 为空，跳过播放相关用例）');

  if (sampleVideo) {
    const mediaResponse = await net.fetch(protocolModule.toMediaUrl(sampleVideo), {
      headers: { Range: 'bytes=0-1023' },
    });
    const body = Buffer.from(await mediaResponse.arrayBuffer());
    check(
      '视频 Range 请求返回 206',
      mediaResponse.status === 206 && body.length === 1024,
      `HTTP ${mediaResponse.status}, ${body.length} 字节, Content-Range=${mediaResponse.headers.get(
        'content-range'
      )}`
    );
  }

  /* ---------- 2. 媒体探测 ---------- */
  section('2. 媒体探测与缩略图');

  if (sampleVideo) {
    const started = Date.now();
    const result = await probe.probeAndCache(sampleVideo);
    check(
      '生成缩略图',
      Boolean(result.ok && result.thumbnailPath && fs.existsSync(result.thumbnailPath)),
      result.ok
        ? `${result.width}x${result.height}, ${(result.duration || 0).toFixed(1)}s, ${Date.now() - started}ms`
        : `失败: ${result.error}`
    );
    check(
      '分辨率达到 1080p',
      result.width >= 1920 && result.height >= 1080,
      `${result.width}x${result.height}`
    );
  } else {
    check('生成缩略图', false, '没有测试素材');
  }

  /* ---------- 3. 素材库 ---------- */
  section('3. 素材库扫描');

  await service.library.ensureDirectories();
  let items = await service.listItems({ enrich: false });
  check('扫描到素材', items.length > 0, `${items.length} 个`);

  if (items.length > 0) {
    const first = items[0];
    check('标题解析', Boolean(first.title), first.title);
    check('标签解析', Array.isArray(first.tags), JSON.stringify(first.tags));
    check('分类推断', Boolean(first.category), first.category);
  }

  await service.library.enrich(items);
  items = await service.listItems({ enrich: false });
  if (items.length > 0) {
    const first = items[0];
    check(
      '元数据补齐',
      Boolean(first.width && first.height && first.thumbnailUrl),
      `${first.resolutionText} · ${first.durationText} · ${first.sizeText}`
    );
  }

  /* ---------- 4. 壁纸窗口 ---------- */
  section('4. 壁纸窗口');

  if (sampleVideo) {
    const applied = await service.applyPath(sampleVideo);
    check(
      '应用到桌面',
      applied.ok,
      applied.ok ? `模式=${applied.mode}` : `原因=${applied.reason}`
    );

    const state = service.getState();
    check('状态回传', state.activePath === sampleVideo && !state.isPaused, JSON.stringify({
      isPaused: state.isPaused,
      mode: state.mode,
    }));

    service.controller.pause();
    check('暂停', service.getState().isPaused === true);
    service.controller.resume();
    check('继续', service.getState().isPaused === false);

    if (process.platform !== 'win32') {
      check(
        '非 Windows 平台降级说明',
        service.getState().mode === 'preview',
        '预览模式（Windows 上会走 WorkerW 挂载）'
      );
    }
  }

  /* ---------- 5. 主界面渲染 ---------- */
  section('5. 主界面渲染');

  const trayStub = { refresh: () => {}, setSelectedPath: () => {} };
  registerIpc({
    service,
    settings,
    online,
    updater: { check: async () => ({ ok: false, message: '冒烟测试不检查更新' }) },
    power: { handleReport: () => {}, getStatus: () => null },
    tray: trayStub,
    getMainWindow: () => mainWindow,
    showMainWindow: () => {},
    hideMainWindow: () => {},
    quitApp: () => {},
  });

  const rendererErrors = [];
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 820,
    show: true,
    frame: false,
    backgroundColor: '#0e1014',
    webPreferences: {
      preload: path.join(ROOT, 'src', 'preload', 'main.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      backgroundThrottling: false,
    },
  });

  mainWindow.webContents.on('console-message', (event) => {
    const level = typeof event === 'object' ? event.level : undefined;
    const message = typeof event === 'object' ? event.message : undefined;
    if (level === 'error' || level === 3) rendererErrors.push(message);
  });
  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    rendererErrors.push(`渲染进程崩溃: ${details.reason}`);
  });

  await mainWindow.loadURL('wsmedia://app/index.html');
  // 等素材墙渲染 + 缩略图补齐
  await new Promise((resolve) => setTimeout(resolve, 3500));

  // 切到「在线素材」页触发一次清单加载，再切回来
  await mainWindow.webContents.executeJavaScript(
    `document.querySelector('.nav-item[data-view="online"]').click()`,
    true
  );
  await new Promise((resolve) => setTimeout(resolve, 1200));
  await mainWindow.webContents.executeJavaScript(
    `document.querySelector('.nav-item[data-view="library"]').click()`,
    true
  );
  await new Promise((resolve) => setTimeout(resolve, 400));

  const domReport = await mainWindow.webContents.executeJavaScript(
    `(() => ({
      hasBridge: typeof window.winscreen === 'object',
      cards: document.querySelectorAll('.card').length,
      chips: document.querySelectorAll('.chip').length,
      thumbs: document.querySelectorAll('.card-media img').length,
      navCount: document.getElementById('nav-count-library').textContent,
      playerTitle: document.getElementById('player-title').textContent,
      status: document.getElementById('status-text').textContent,
      theme: document.documentElement.dataset.theme,
      detailVisible: !document.getElementById('detail-body').hidden,
      detailTitle: document.getElementById('detail-title').textContent,
      dropOverlayHidden: document.getElementById('drop-overlay').hidden,
      settingsRows: document.querySelectorAll('#settings .setting-row').length,
      onlineRows: document.querySelectorAll('#online-list .online-row').length,
    }))()`,
    true
  );

  check('preload 桥接可用', domReport.hasBridge);
  check('素材卡片渲染', domReport.cards > 0, `${domReport.cards} 张`);
  check('分类筛选渲染', domReport.chips > 0, `${domReport.chips} 个`);
  check('缩略图显示', domReport.thumbs > 0, `${domReport.thumbs} 张`);
  check('侧边栏计数同步', domReport.navCount === String(items.length), `navCount=${domReport.navCount}`);
  check('播放条状态同步', domReport.playerTitle !== '未播放', `"${domReport.playerTitle}"`);
  check('详情面板已展开', domReport.detailVisible, `标题="${domReport.detailTitle}"`);
  check('设置项已渲染', domReport.settingsRows >= 8, `${domReport.settingsRows} 行`);
  check('在线素材列表已渲染', domReport.onlineRows > 0, `${domReport.onlineRows} 行`);
  check('拖拽遮罩默认隐藏', domReport.dropOverlayHidden === true);
  check('主题生效', Boolean(domReport.theme), domReport.theme);

  mainWindow.focus();
  await new Promise((resolve) => setTimeout(resolve, 600));
  const image = await mainWindow.webContents.capturePage();
  fs.writeFileSync(SHOT_PATH, image.toPNG());
  check('界面截图', fs.existsSync(SHOT_PATH), SHOT_PATH);

  check('渲染进程无报错', rendererErrors.length === 0, rendererErrors.slice(0, 3).join(' | ') || '无');

  /* ---------- 6. 清理 ---------- */
  section('6. 平台能力');
  const capability = win32.describe();
  check(
    '桌面层接口状态',
    true,
    capability.available ? `可用（宿主：${win32.classNameOf(win32.findWallpaperHost())}）` : `不可用：${capability.error}`
  );

  service.destroy();
  probe.destroy();
  settings.flush();

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${'─'.repeat(56)}`);
  console.log(`合计 ${results.length} 项，通过 ${results.length - failed.length} 项，失败 ${failed.length} 项`);
  if (failed.length > 0) {
    console.log('失败用例：');
    for (const item of failed) console.log(`  · ${item.name}`);
  }
  console.log(`${'─'.repeat(56)}\n`);

  fs.rmSync(TMP_USER_DATA, { recursive: true, force: true });
  app.exit(failed.length === 0 ? 0 : 1);
}

function findSampleVideo() {
  const directories = [config.bundledVideoDirectory(), config.userVideoDirectory()];
  for (const directory of directories) {
    if (!fs.existsSync(directory)) continue;
    const found = fs
      .readdirSync(directory)
      .filter((name) => config.isSupportedVideo(name))
      .map((name) => path.join(directory, name));
    if (found.length > 0) return found[0];
  }
  return null;
}

app.whenReady().then(main).catch((error) => {
  console.error('\n冒烟测试异常终止：', error);
  app.exit(2);
});
