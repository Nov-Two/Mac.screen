'use strict';

/**
 * WinScreen —— Windows 桌面动态壁纸应用（Electron 实现）
 * 参考项目：https://github.com/Nov-Two/Mac.screen
 *
 * 主进程入口。负责：协议注册、单实例、窗口生命周期、模块装配与退出清理。
 */

const path = require('path');
const { app, BrowserWindow, dialog, powerMonitor, shell } = require('electron');

const config = require('./config');
const protocol = require('./protocol');
const { SettingsStore } = require('./settings');
const { MediaProbe } = require('./media-probe');
const { WallpaperService } = require('./service');
const { OnlineMaterials } = require('./online');
const { TrayController } = require('./tray');
const { PowerMonitor } = require('./power');
const { UpdaterController } = require('./updater');
const loginItem = require('./login-item');
const { registerIpc } = require('./ipc');

const MAIN_PRELOAD = path.join(__dirname, '..', 'preload', 'main.js');
const RENDERER_DIR = path.join(__dirname, '..', 'renderer');

/* ------------------------------------------------------------------ *
 * 启动前的准备
 * ------------------------------------------------------------------ */

app.setAppUserModelId(config.APP_ID);
app.setName(config.APP_NAME);

// 壁纸是自动播放的，必须绕开浏览器的「用户手势」限制
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
// 视频解码交给 GPU，降低 CPU 占用
app.commandLine.appendSwitch('enable-accelerated-video-decode');

// 自定义协议必须在 ready 之前注册
protocol.registerScheme();

/* ------------------------------------------------------------------ *
 * 单实例
 * ------------------------------------------------------------------ */

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
}

/* ------------------------------------------------------------------ *
 * 运行时状态
 * ------------------------------------------------------------------ */

let mainWindow = null;
let settings = null;
let probe = null;
let service = null;
let online = null;
let tray = null;
let power = null;
let updater = null;
let isQuitting = false;

/* ------------------------------------------------------------------ *
 * 事件广播
 * ------------------------------------------------------------------ */

function broadcast(channel, payload) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, payload);
  }
}

/* ------------------------------------------------------------------ *
 * 主窗口
 * ------------------------------------------------------------------ */

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 820,
    minWidth: 1000,
    minHeight: 640,
    show: false,
    frame: false,
    backgroundColor: '#0e1014',
    title: config.APP_NAME,
    autoHideMenuBar: true,
    webPreferences: {
      preload: MAIN_PRELOAD,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      spellcheck: false,
      backgroundThrottling: false,
    },
  });

  mainWindow.loadURL('wsmedia://app/index.html');

  mainWindow.once('ready-to-show', () => {
    // 开机自启时静默驻留托盘，不弹窗打扰
    if (!loginItem.launchedByAutostart()) {
      mainWindow.show();
    }
  });

  mainWindow.on('close', (event) => {
    if (isQuitting) return;
    if (settings.get('closeToTray') === false) {
      isQuitting = true;
      app.quit();
      return;
    }
    event.preventDefault();
    mainWindow.hide();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // 站内链接一律交给系统浏览器，避免在应用内打开外部页面
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//i.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });

  return mainWindow;
}

function showMainWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) {
    createMainWindow();
  }
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.show();
  mainWindow.focus();
}

function hideMainWindow() {
  if (mainWindow && !mainWindow.isDestroyed()) mainWindow.hide();
}

/* ------------------------------------------------------------------ *
 * 装配
 * ------------------------------------------------------------------ */

async function bootstrap() {
  protocol.registerHandler({
    rendererDir: RENDERER_DIR,
    assetsDir: config.assetsDirectory(),
  });

  settings = new SettingsStore(config.settingsFile());
  settings.set('opensAtLogin', loginItem.isEnabled());

  probe = new MediaProbe();

  service = new WallpaperService({
    settings,
    probe,
    emit: broadcast,
  });

  online = new OnlineMaterials({
    library: service.library,
    settings,
    emit: broadcast,
  });

  power = new PowerMonitor({
    settings,
    emit: broadcast,
    onLowBattery: ({ level, threshold }) => {
      service.controller.pause();
      broadcast('power:lowBattery', { level, threshold, action: 'paused' });
      const choice = dialog.showMessageBoxSync(mainWindow || undefined, {
        type: 'warning',
        title: '电量偏低',
        message: `当前电量 ${Math.round(level * 100)}%，已低于 ${threshold}%。动态壁纸已自动暂停。`,
        buttons: ['继续播放', '保持暂停', '停止壁纸'],
        defaultId: 1,
        cancelId: 1,
        noLink: true,
      });
      if (choice === 0) {
        service.controller.resume();
      } else if (choice === 2) {
        service.controller.stop();
        settings.set('lastWallpaperPath', null);
      }
      tray?.refresh();
    },
    onRecover: () => {
      broadcast('power:lowBattery', { action: 'recovered' });
    },
  });

  updater = new UpdaterController({ emit: broadcast });

  tray = new TrayController({
    service,
    settings,
    onShowWindow: () => showMainWindow(),
    onQuit: () => {
      isQuitting = true;
      app.quit();
    },
    onCheckUpdate: async () => {
      const result = await updater.check();
      if (!result.ok) {
        dialog.showMessageBox(mainWindow || undefined, {
          type: 'info',
          title: '检查更新',
          message: result.message || '暂时无法检查更新。',
          buttons: ['好'],
        });
      }
    },
    onAbout: () => {
      dialog.showMessageBox(mainWindow || undefined, {
        type: 'info',
        title: `关于 ${config.APP_NAME}`,
        message: `${config.APP_NAME} ${app.getVersion()}`,
        detail:
          'Windows 桌面动态壁纸应用。\n\n' +
          '把本地视频静音循环播放到桌面图标层之下，不抢焦点、不遮挡窗口。\n\n' +
          '设计参考 MacScreen（SwiftUI 版），本项目为 Electron 跨平台重写。\n' +
          '素材来源：https://github.com/Nov-Two/Mac.screen',
        buttons: ['好'],
        noLink: true,
      });
    },
  });
  tray.create();

  registerIpc({
    service,
    settings,
    online,
    updater,
    power,
    tray,
    getMainWindow: () => mainWindow,
    showMainWindow,
    hideMainWindow,
    quitApp: () => {
      isQuitting = true;
      app.quit();
    },
  });

  createMainWindow();

  await service.library.ensureDirectories();
  power.start();

  // 预加载素材列表，让界面首屏就有内容
  await service.listItems();

  // 挂起时暂停壁纸，唤醒后恢复，避免休眠期间白白耗电
  powerMonitor.on('suspend', () => service.controller.pause());
  powerMonitor.on('resume', () => {
    if (service.getState().activePath) service.controller.resume();
  });

  // 启动后恢复上次壁纸（默认关闭）
  if (settings.get('restoresLastWallpaperOnLaunch')) {
    const result = await service.restoreLastWallpaper();
    if (!result.ok && result.reason === 'missing-file') {
      console.warn('[main] 上次的壁纸文件已不存在，跳过恢复');
    }
  }
}

/* ------------------------------------------------------------------ *
 * 生命周期
 * ------------------------------------------------------------------ */

app.on('second-instance', () => {
  showMainWindow();
});

app.whenReady().then(bootstrap).catch((error) => {
  console.error('[main] 启动失败:', error);
  dialog.showErrorBox('启动失败', `${config.APP_NAME} 无法启动：\n${error.message}`);
  app.quit();
});

// 托盘常驻应用：关掉所有窗口也不退出
app.on('window-all-closed', () => {
  // 非托盘模式（用户显式关闭了 closeToTray）时才退出
  if (settings && settings.get('closeToTray') === false) app.quit();
});

app.on('activate', () => {
  showMainWindow();
});

app.on('before-quit', () => {
  isQuitting = true;
  try {
    settings?.flush();
    service?.destroy();
    probe?.destroy();
    power?.destroy();
    tray?.destroy();
  } catch (error) {
    console.error('[main] 退出清理异常:', error.message);
  }
});

process.on('uncaughtException', (error) => {
  console.error('[main] 未捕获异常:', error);
});
