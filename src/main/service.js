'use strict';

/**
 * 业务编排层。
 * 对应 Mac 版 WallpaperStore.swift 的职责：把素材库、壁纸窗口控制器、
 * 设置三者串起来，向上（IPC / 托盘）提供语义化动作。
 */

const path = require('path');
const { shell } = require('electron');

const config = require('./config');
const { WallpaperLibrary } = require('./library');
const { WallpaperWindowController } = require('./wallpaper-window');

class WallpaperService {
  constructor({ settings, probe, emit }) {
    this.settings = settings;
    this.emit = emit || (() => {});
    this.items = [];
    this.loaded = false;

    this.library = new WallpaperLibrary({ settings, probe, emit });
    this.controller = new WallpaperWindowController({
      settings,
      onStateChange: (state) => this.emit('wallpaper:state', state),
    });
  }

  /* ---------------- 素材列表 ---------------- */

  async listItems({ enrich = true } = {}) {
    this.items = await this.library.listItems();
    this.loaded = true;

    if (enrich) {
      // 不阻塞返回：先把列表给界面，缺元数据的在后台补齐
      this.library
        .enrich(this.items)
        .then(() => this.emit('library:changed', { reason: 'enriched' }))
        .catch((error) => console.error('[service] 元数据补齐失败:', error.message));
    }

    return this.items;
  }

  async refresh() {
    await this.listItems();
    this.emit('library:changed', { reason: 'refresh' });
    return this.items;
  }

  findItem(itemPath) {
    const resolved = path.resolve(itemPath);
    return this.items.find((item) => path.resolve(item.path) === resolved) || null;
  }

  /* ---------------- 导入 / 删除 ---------------- */

  async importVideos() {
    const result = await this.library.importVideos(this._pendingPaths || []);
    return result;
  }

  async importResources(sourcePaths) {
    const result = await this.library.importResources(sourcePaths);
    await this.refresh();
    return result;
  }

  async deleteItems(paths) {
    const targets = paths
      .map((p) => this.findItem(p))
      .filter(Boolean)
      .map((item) => ({ path: item.path, kind: item.kind }));

    if (targets.length === 0) return { message: '没有可删除的素材。', removed: [] };

    const message = await this.library.deleteItems(targets);

    // 若删除的正是当前播放的壁纸，顺手停掉并清空记忆
    const activePath = this.controller.activePath;
    if (activePath && targets.some((t) => t.path === activePath)) {
      this.controller.stop();
      this.settings.set('lastWallpaperPath', null);
    }

    await this.refresh();
    return { message, removed: targets.map((t) => t.path) };
  }

  async restoreBundledVideos() {
    const message = this.library.restoreBundledVideos();
    await this.refresh();
    return message;
  }

  toggleFavorite(itemPath) {
    const isFavorite = this.library.toggleFavorite(itemPath);
    const item = this.findItem(itemPath);
    if (item) item.isFavorite = isFavorite;
    this.emit('library:changed', { reason: 'favorite', path: itemPath, isFavorite });
    return isFavorite;
  }

  /* ---------------- 应用壁纸 ---------------- */

  /**
   * @param {string} itemPath
   * @returns {Promise<{ok:boolean, mode?:string, reason?:string, title?:string}>}
   */
  async applyPath(itemPath) {
    const result = await this.controller.apply(itemPath);
    if (result.ok) {
      this.settings.set('lastWallpaperPath', itemPath);
      return { ...result, title: path.basename(itemPath, path.extname(itemPath)) };
    }
    this.settings.set('lastWallpaperPath', null);
    return result;
  }

  async next() {
    if (this.items.length === 0) await this.listItems();
    if (this.items.length === 0) return { ok: false, reason: 'empty-library' };

    const currentPath = this.controller.activePath;
    const currentIndex = currentPath
      ? this.items.findIndex((item) => path.resolve(item.path) === path.resolve(currentPath))
      : -1;
    const nextIndex = (currentIndex + 1) % this.items.length;
    return this.applyPath(this.items[nextIndex].path);
  }

  async restoreLastWallpaper() {
    if (!this.settings.get('restoresLastWallpaperOnLaunch')) return { ok: false, reason: 'disabled' };
    const lastPath = this.settings.get('lastWallpaperPath');
    if (!lastPath) return { ok: false, reason: 'no-history' };
    const fs = require('fs');
    if (!fs.existsSync(lastPath)) return { ok: false, reason: 'missing-file' };
    return this.applyPath(lastPath);
  }

  /* ---------------- 目录操作 ---------------- */

  openFolder(kind) {
    const map = {
      bundled: config.bundledVideoDirectory(),
      user: config.userVideoDirectory(),
      downloads: config.downloadDirectory(),
    };
    const target = map[kind] || map.user;
    try {
      require('fs').mkdirSync(target, { recursive: true });
    } catch {
      /* 忽略 */
    }
    shell.openPath(target);
    return target;
  }

  reveal(target) {
    if (!target) return false;
    shell.showItemInFolder(target);
    return true;
  }

  getState() {
    return this.controller.getState();
  }

  destroy() {
    this.controller.destroy();
  }
}

module.exports = { WallpaperService };
