'use strict';

/**
 * 自动更新。对应 Mac 版 SoftwareUpdateController.swift（Sparkle）。
 * 使用 electron-updater，配合 package.json 的 publish 配置工作。
 * 未打包运行时直接返回提示，不做任何网络请求。
 */

const { app } = require('electron');

class UpdaterController {
  constructor({ emit, onStatus }) {
    this.emit = emit || (() => {});
    this.onStatus = onStatus || (() => {});
    this.autoUpdater = null;
    this.available = false;
    this._bind();
  }

  _bind() {
    if (!app.isPackaged) return;
    try {
      // 延迟加载，避免开发环境缺依赖时报错
      const { autoUpdater } = require('electron-updater');
      this.autoUpdater = autoUpdater;
      this.available = true;
    } catch (error) {
      console.warn('[updater] electron-updater 不可用:', error.message);
      return;
    }

    const autoUpdater = this.autoUpdater;
    autoUpdater.autoDownload = true;
    autoUpdater.autoInstallOnAppQuit = true;

    autoUpdater.on('checking-for-update', () => this._status({ state: 'checking' }));
    autoUpdater.on('update-available', (info) =>
      this._status({ state: 'available', version: info?.version })
    );
    autoUpdater.on('update-not-available', () => this._status({ state: 'latest' }));
    autoUpdater.on('download-progress', (progress) =>
      this._status({ state: 'downloading', percent: Math.round(progress?.percent || 0) })
    );
    autoUpdater.on('update-downloaded', (info) =>
      this._status({ state: 'downloaded', version: info?.version })
    );
    autoUpdater.on('error', (error) =>
      this._status({ state: 'error', message: error?.message || String(error) })
    );
  }

  _status(payload) {
    this.emit('updater:status', payload);
    this.onStatus(payload);
  }

  async check() {
    if (!this.available) {
      return {
        ok: false,
        reason: app.isPackaged ? 'updater-unavailable' : 'not-packaged',
        message: app.isPackaged
          ? '更新组件未就绪，请确认已配置 publish 地址。'
          : '开发模式下不检查更新。',
      };
    }
    try {
      await this.autoUpdater.checkForUpdates();
      return { ok: true };
    } catch (error) {
      return { ok: false, reason: 'check-failed', message: error.message };
    }
  }

  quitAndInstall() {
    if (this.autoUpdater) this.autoUpdater.quitAndInstall();
  }
}

module.exports = { UpdaterController };
