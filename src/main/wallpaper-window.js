'use strict';

/**
 * 壁纸窗口控制器。
 * 对应 Mac 版 WallpaperWindowController.swift。
 *
 * Windows 上：窗口被挂到桌面图标层之下的 WorkerW，不抢焦点、不遮挡窗口、
 * Win+D 也不会被盖掉；鼠标事件全部穿透，桌面图标照常可点。
 * 其它平台：退化为「无边框全屏置底窗口」的预览模式，方便在 macOS 上开发调试。
 */

const fs = require('fs');
const path = require('path');
const { BrowserWindow, screen } = require('electron');

const config = require('./config');
const win32 = require('./win32');
const protocol = require('./protocol');

const PRELOAD_PATH = path.join(__dirname, '..', 'preload', 'wallpaper.js');

class WallpaperWindowController {
  constructor({ settings, onStateChange }) {
    this.settings = settings;
    this.onStateChange = onStateChange || (() => {});

    this.window = null;
    this.activePath = null;
    this.isPaused = false;
    this.mode = null; // 'workerw' | 'bottom' | 'preview'
    this._displayListenerBound = false;
  }

  /* ---------------- 状态 ---------------- */

  getState() {
    return {
      activePath: this.activePath,
      activeTitle: this.activePath ? path.basename(this.activePath, path.extname(this.activePath)) : null,
      isPaused: this.isPaused,
      volume: Number(this.settings.get('wallpaperVolume')) || 0,
      mode: this.mode,
      isPlaying: Boolean(this.activePath) && !this.isPaused,
      desktopAttached: this.mode === 'workerw',
    };
  }

  _emitState() {
    this.onStateChange(this.getState());
  }

  /* ---------------- 目标矩形 ---------------- */

  _targetRect() {
    const primary = screen.getPrimaryDisplay();
    if (!this.settings.get('spanAllDisplays')) {
      return { ...primary.bounds };
    }

    const displays = screen.getAllDisplays();
    const left = Math.min(...displays.map((d) => d.bounds.x));
    const top = Math.min(...displays.map((d) => d.bounds.y));
    const right = Math.max(...displays.map((d) => d.bounds.x + d.bounds.width));
    const bottom = Math.max(...displays.map((d) => d.bounds.y + d.bounds.height));
    return { x: left, y: top, width: right - left, height: bottom - top };
  }

  /* ---------------- 应用壁纸 ---------------- */

  /**
   * @param {string} filePath 视频绝对路径
   * @returns {Promise<{ok:boolean, mode?:string, reason?:string}>}
   */
  async apply(filePath) {
    this.stop();

    if (!filePath || !fs.existsSync(filePath)) {
      return { ok: false, reason: 'file-not-found' };
    }

    const rect = this._targetRect();
    const isWindows = process.platform === 'win32';

    const win = new BrowserWindow({
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
      frame: false,
      transparent: false,
      backgroundColor: '#000000',
      resizable: false,
      movable: false,
      minimizable: false,
      maximizable: false,
      closable: true,
      focusable: false,
      skipTaskbar: true,
      hasShadow: false,
      show: false,
      enableLargerThanScreen: true,
      autoHideMenuBar: true,
      title: config.APP_NAME,
      webPreferences: {
        preload: PRELOAD_PATH,
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: false,
        backgroundThrottling: false,
        autoplayPolicy: 'no-user-gesture-required',
        // 页面来自 wsmedia:// 安全来源，无需关闭 webSecurity
        webSecurity: true,
      },
    });

    win.setMenuBarVisibility(false);
    win.setIgnoreMouseEvents(true);

    this.window = win;

    const volume = Number(this.settings.get('wallpaperVolume')) || 0;
    const params = new URLSearchParams({
      src: protocol.toMediaUrl(filePath),
      volume: String(volume),
      fit: String(this.settings.get('videoFit') || 'cover'),
    });

    try {
      await win.loadURL(`wsmedia://app/wallpaper.html?${params.toString()}`);
    } catch (error) {
      console.error('[wallpaper] 页面加载失败:', error.message);
      this.stop();
      return { ok: false, reason: 'load-failed' };
    }

    if (win.isDestroyed()) return { ok: false, reason: 'window-destroyed' };

    // 先让窗口可见，再挂载到桌面层。
    // 顺序很关键：若先 SetParent 后 show，显示动作会让窗口管理器重新计算
    // 子窗口位置，可能把壁纸挤到桌面左上角或尺寸错乱。
    win.showInactive();
    win.setIgnoreMouseEvents(true);

    // 挂载到桌面层
    let attachResult;
    if (isWindows) {
      attachResult = win32.attachToDesktop(win.getNativeWindowHandle(), rect);
      if (!attachResult.ok) {
        console.warn('[wallpaper] 桌面层挂载失败，回退为置底窗口:', attachResult.reason);
        attachResult = win32.attachToBottom(win.getNativeWindowHandle(), rect);
      }
      // 挂载完成后再校正一次矩形，抵消 SetParent 带来的坐标基准变化
      if (attachResult.ok) win32.setRect(win.getNativeWindowHandle(), rect);
    } else {
      attachResult = { ok: true, mode: 'preview' };
    }

    this.mode = attachResult.ok ? attachResult.mode : 'failed';

    win.setIgnoreMouseEvents(true);

    this.activePath = filePath;
    this.isPaused = false;
    this._bindDisplayListener();

    this._emitState();

    return { ok: true, mode: this.mode, reason: attachResult.reason };
  }

  /* ---------------- 播放控制 ---------------- */

  _send(command) {
    if (!this.window || this.window.isDestroyed()) return;
    try {
      this.window.webContents.send('wallpaper:command', command);
    } catch {
      /* 窗口正在销毁，忽略 */
    }
  }

  pause() {
    if (!this.activePath || this.isPaused) return;
    this._send({ type: 'pause' });
    this.isPaused = true;
    this._emitState();
  }

  resume() {
    if (!this.activePath || !this.isPaused) return;
    this._send({ type: 'play' });
    this.isPaused = false;
    this._emitState();
  }

  togglePause() {
    if (this.isPaused) this.resume();
    else this.pause();
  }

  setVolume(volume) {
    const clamped = Math.max(0, Math.min(1, Number(volume) || 0));
    this.settings.set('wallpaperVolume', clamped);
    this._send({ type: 'volume', volume: clamped });
    this._emitState();
    return clamped;
  }

  setFit(fit) {
    this.settings.set('videoFit', fit);
    this._send({ type: 'fit', fit });
  }

  stop() {
    if (this.window && !this.window.isDestroyed()) {
      try {
        if (process.platform === 'win32') {
          win32.detachFromDesktop(this.window.getNativeWindowHandle());
        }
      } catch {
        /* 忽略 */
      }
      try {
        this.window.destroy();
      } catch {
        /* 忽略 */
      }
    }
    this.window = null;
    this.activePath = null;
    this.isPaused = false;
    this.mode = null;
    this._unbindDisplayListener();
    this._emitState();
  }

  /* ---------------- 显示器变化 ---------------- */

  _bindDisplayListener() {
    if (this._displayListenerBound) return;
    this._displayListenerBound = true;
    this._onDisplayChange = () => {
      if (!this.window || this.window.isDestroyed()) return;
      const rect = this._targetRect();
      if (process.platform === 'win32') {
        win32.setRect(this.window.getNativeWindowHandle(), rect);
      }
      try {
        this.window.setBounds(rect);
      } catch {
        /* 忽略 */
      }
    };
    screen.on('display-metrics-changed', this._onDisplayChange);
    screen.on('display-added', this._onDisplayChange);
    screen.on('display-removed', this._onDisplayChange);
  }

  _unbindDisplayListener() {
    if (!this._displayListenerBound) return;
    this._displayListenerBound = false;
    screen.removeListener('display-metrics-changed', this._onDisplayChange);
    screen.removeListener('display-added', this._onDisplayChange);
    screen.removeListener('display-removed', this._onDisplayChange);
  }

  destroy() {
    this._unbindDisplayListener();
    this.stop();
  }
}

module.exports = { WallpaperWindowController };
