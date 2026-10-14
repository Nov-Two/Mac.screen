'use strict';

/**
 * 极简的 JSON 设置持久化，替代 Mac 版的 UserDefaults。
 * 写入采用「延迟合并 + 原子替换」，避免频繁 IO 与半截文件。
 */

const fs = require('fs');
const path = require('path');

const DEFAULTS = Object.freeze({
  /** 上次应用的壁纸路径 */
  lastWallpaperPath: null,
  /** 启动时恢复上次壁纸 */
  restoresLastWallpaperOnLaunch: false,
  /** 开机自动启动 */
  opensAtLogin: false,
  /** 低电量时暂停并提醒 */
  pausesOnLowBattery: false,
  /** 导入完成后清理下载的源文件 */
  cleansDownloadedResourcesAfterImport: true,
  /** 收藏的素材路径 */
  favoriteWallpaperPaths: [],
  /** 被隐藏的内置素材路径 */
  hiddenWallpaperPaths: [],
  /** 全局音量 0~1 */
  wallpaperVolume: 0,
  /** 壁纸窗口是否铺满所有显示器 */
  spanAllDisplays: false,
  /** 界面主题：dark | light */
  theme: 'dark',
  /** 素材墙卡片 3D 悬停动效 */
  enableCardHoverEffect: true,
  /** 关闭主窗口时最小化到托盘而不是退出 */
  closeToTray: true,
  /** 视频画面铺满方式：cover | contain | fill */
  videoFit: 'cover',
  /** 跳过导入时的分辨率校验 */
  skipResolutionCheck: false,
});

class SettingsStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.data = { ...DEFAULTS };
    this._timer = null;
    this._listeners = new Set();
    this.load();
  }

  load() {
    try {
      const raw = fs.readFileSync(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        this.data = { ...DEFAULTS, ...parsed };
      }
    } catch {
      // 首次运行或文件损坏，使用默认值
    }
  }

  get(key) {
    return this.data[key];
  }

  all() {
    return { ...this.data };
  }

  set(key, value) {
    if (this.data[key] === value) return;
    this.data[key] = value;
    this._scheduleSave();
    for (const listener of this._listeners) {
      try {
        listener(key, value);
      } catch {
        /* 忽略监听器异常，避免影响主流程 */
      }
    }
  }

  patch(partial) {
    for (const [key, value] of Object.entries(partial)) {
      this.set(key, value);
    }
  }

  toggle(key) {
    const next = !this.data[key];
    this.set(key, next);
    return next;
  }

  onChange(listener) {
    this._listeners.add(listener);
    return () => this._listeners.delete(listener);
  }

  _scheduleSave() {
    if (this._timer) clearTimeout(this._timer);
    this._timer = setTimeout(() => this.flush(), 250);
  }

  flush() {
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
    try {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      const tmp = `${this.filePath}.tmp`;
      fs.writeFileSync(tmp, JSON.stringify(this.data, null, 2), 'utf8');
      fs.renameSync(tmp, this.filePath);
    } catch (error) {
      console.error('[settings] 写入失败:', error.message);
    }
  }
}

module.exports = { SettingsStore, DEFAULTS };
