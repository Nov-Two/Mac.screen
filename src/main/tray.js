'use strict';

/**
 * 托盘常驻菜单。对应 Mac 版 StatusBarController.swift。
 * 主窗口关闭后应用继续驻留托盘，所有常用操作都能在这里完成。
 */

const path = require('path');
const { Tray, Menu, nativeImage, app, dialog } = require('electron');

const config = require('./config');

const TRAY_ICON = path.join(__dirname, '..', '..', 'assets', 'tray.png');

class TrayController {
  constructor({ service, settings, onShowWindow, onQuit, onCheckUpdate, onAbout }) {
    this.service = service;
    this.settings = settings;
    this.onShowWindow = onShowWindow;
    this.onQuit = onQuit;
    this.onCheckUpdate = onCheckUpdate;
    this.onAbout = onAbout;
    this.tray = null;
    this._lastTooltip = null;
  }

  create() {
    if (this.tray) return this.tray;

    let image = nativeImage.createFromPath(TRAY_ICON);
    if (image.isEmpty()) {
      // 图标缺失时给一个 1x1 兜底，保证托盘仍然可用
      image = nativeImage.createEmpty();
    } else if (process.platform === 'win32') {
      image = image.resize({ width: 16, height: 16 });
    }

    this.tray = new Tray(image);
    this.tray.setToolTip(config.APP_NAME);
    this.tray.on('click', () => this.onShowWindow());
    this.tray.on('double-click', () => this.onShowWindow());

    this.refresh();
    return this.tray;
  }

  refresh() {
    if (!this.tray) return;

    const state = this.service.getState();
    const settings = this.settings.all();

    const header = state.activePath
      ? `${state.isPaused ? '已暂停' : '正在播放'}：${state.activeTitle}`
      : '当前没有播放动态壁纸';

    const template = [
      { label: header, enabled: false },
      { type: 'separator' },
      { label: '显示主窗口', click: () => this.onShowWindow() },
      {
        label: '应用选中素材',
        enabled: Boolean(this._selectedPath),
        click: async () => {
          if (!this._selectedPath) return;
          await this.service.applyPath(this._selectedPath);
          this.refresh();
        },
      },
      { type: 'separator' },
      {
        label: state.isPaused ? '继续播放' : '暂停播放',
        enabled: Boolean(state.activePath),
        click: () => {
          this.service.controller.togglePause();
          this.refresh();
        },
      },
      {
        label: '下一个壁纸',
        enabled: this.service.items.length > 0,
        click: async () => {
          await this.service.next();
          this.refresh();
        },
      },
      {
        label: '停止播放',
        enabled: Boolean(state.activePath),
        click: () => {
          this.service.controller.stop();
          this.settings.set('lastWallpaperPath', null);
          this.refresh();
        },
      },
      { type: 'separator' },
      {
        label: `音量（${Math.round((state.volume || 0) * 100)}%）`,
        submenu: [0, 0.25, 0.5, 0.75, 1].map((value) => ({
          label: value === 0 ? '静音' : `${Math.round(value * 100)}%`,
          type: 'radio',
          checked: Math.abs((state.volume || 0) - value) < 0.01,
          click: () => {
            this.service.controller.setVolume(value);
            this.refresh();
          },
        })),
      },
      {
        label: '画面铺满方式',
        submenu: [
          { key: 'cover', label: '裁剪铺满（推荐）' },
          { key: 'contain', label: '完整显示（留黑边）' },
          { key: 'fill', label: '拉伸填满' },
        ].map((option) => ({
          label: option.label,
          type: 'radio',
          checked: (settings.videoFit || 'cover') === option.key,
          click: () => {
            this.service.controller.setFit(option.key);
            this.refresh();
          },
        })),
      },
      { type: 'separator' },
      {
        label: '启动时恢复上次壁纸',
        type: 'checkbox',
        checked: Boolean(settings.restoresLastWallpaperOnLaunch),
        click: () => {
          this.settings.toggle('restoresLastWallpaperOnLaunch');
          this.refresh();
        },
      },
      {
        label: '开机自动启动',
        type: 'checkbox',
        checked: Boolean(settings.opensAtLogin),
        click: () => {
          const next = this.settings.toggle('opensAtLogin');
          try {
            require('./login-item').setEnabled(next);
          } catch (error) {
            dialog.showErrorBox('设置失败', `无法更新开机启动：${error.message}`);
          }
          this.refresh();
        },
      },
      {
        label: '低电量时暂停',
        type: 'checkbox',
        checked: Boolean(settings.pausesOnLowBattery),
        click: () => {
          this.settings.toggle('pausesOnLowBattery');
          this.refresh();
        },
      },
      { type: 'separator' },
      {
        label: '素材目录',
        submenu: [
          { label: '打开我的素材目录', click: () => this.service.openFolder('user') },
          { label: '打开内置素材目录', click: () => this.service.openFolder('bundled') },
          { label: '打开下载目录', click: () => this.service.openFolder('downloads') },
          { type: 'separator' },
          {
            label: '恢复内置素材',
            click: async () => {
              await this.service.restoreBundledVideos();
              this.refresh();
            },
          },
        ],
      },
      { type: 'separator' },
      { label: '检查更新…', click: () => this.onCheckUpdate() },
      { label: `关于 ${config.APP_NAME}`, click: () => this.onAbout() },
      { type: 'separator' },
      { label: '退出', click: () => this.onQuit() },
    ];

    this.tray.setContextMenu(Menu.buildFromTemplate(template));

    const tooltip = state.activePath
      ? `${config.APP_NAME} · ${state.isPaused ? '已暂停' : '播放中'}：${state.activeTitle}`
      : `${config.APP_NAME} · 空闲`;
    if (tooltip !== this._lastTooltip) {
      this.tray.setToolTip(tooltip);
      this._lastTooltip = tooltip;
    }
  }

  /** 由渲染层同步「当前选中素材」，供托盘菜单使用 */
  setSelectedPath(selectedPath) {
    this._selectedPath = selectedPath;
    this.refresh();
  }

  destroy() {
    if (this.tray) {
      this.tray.destroy();
      this.tray = null;
    }
  }
}

module.exports = { TrayController };
