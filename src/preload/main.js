'use strict';

/**
 * 主窗口 preload：通过 contextBridge 暴露一组受控的 IPC 接口。
 * 渲染进程不直接接触 Node / Electron 内部对象。
 */

const { contextBridge, ipcRenderer, webUtils } = require('electron');

/** 白名单：只有这些频道允许渲染进程订阅 */
const EVENT_CHANNELS = [
  'wallpaper:state',
  'library:enrich:start',
  'library:enrich:item',
  'library:enrich:end',
  'library:changed',
  'online:progress',
  'online:done',
  'settings:changed',
  'toast',
  'updater:status',
  'power:lowBattery',
];

const api = {
  app: {
    info: () => ipcRenderer.invoke('app:info'),
    openExternal: (url) => ipcRenderer.invoke('app:openExternal', url),
  },

  library: {
    list: () => ipcRenderer.invoke('library:list'),
    import: () => ipcRenderer.invoke('library:import'),
    importPaths: (paths) => ipcRenderer.invoke('library:importPaths', paths),
    remove: (paths) => ipcRenderer.invoke('library:delete', paths),
    restoreBundled: () => ipcRenderer.invoke('library:restoreBundled'),
    toggleFavorite: (path) => ipcRenderer.invoke('library:toggleFavorite', path),
    reveal: (path) => ipcRenderer.invoke('library:reveal', path),
    openFolder: (kind) => ipcRenderer.invoke('library:openFolder', kind),
  },

  wallpaper: {
    apply: (path) => ipcRenderer.invoke('wallpaper:apply', path),
    pause: () => ipcRenderer.invoke('wallpaper:pause'),
    resume: () => ipcRenderer.invoke('wallpaper:resume'),
    toggle: () => ipcRenderer.invoke('wallpaper:toggle'),
    stop: () => ipcRenderer.invoke('wallpaper:stop'),
    next: () => ipcRenderer.invoke('wallpaper:next'),
    state: () => ipcRenderer.invoke('wallpaper:state'),
    setVolume: (volume) => ipcRenderer.invoke('wallpaper:setVolume', volume),
    setFit: (fit) => ipcRenderer.invoke('wallpaper:setFit', fit),
    probe: (path) => ipcRenderer.invoke('wallpaper:probe', path),
  },

  settings: {
    all: () => ipcRenderer.invoke('settings:all'),
    set: (key, value) => ipcRenderer.invoke('settings:set', { key, value }),
    toggle: (key) => ipcRenderer.invoke('settings:toggle', key),
  },

  online: {
    list: (options) => ipcRenderer.invoke('online:list', options || {}),
    download: (payload) => ipcRenderer.invoke('online:download', payload),
    openPage: () => ipcRenderer.invoke('online:openPage'),
  },

  updater: {
    check: () => ipcRenderer.invoke('updater:check'),
  },

  ui: {
    /** 把当前选中的素材同步给托盘菜单 */
    setSelection: (selectedPath) => ipcRenderer.send('ui:selection', selectedPath),
  },

  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    hide: () => ipcRenderer.invoke('window:hide'),
    toggleMaximize: () => ipcRenderer.invoke('window:toggleMaximize'),
    close: () => ipcRenderer.invoke('window:close'),
  },

  /** 拖拽进来的文件对象转成绝对路径（Electron 32+ 必须走 webUtils） */
  pathForFile: (file) => {
    try {
      return webUtils.getPathForFile(file);
    } catch {
      return null;
    }
  },

  on: (channel, listener) => {
    if (!EVENT_CHANNELS.includes(channel)) {
      throw new Error(`未授权的频道: ${channel}`);
    }
    const wrapped = (_event, payload) => listener(payload);
    ipcRenderer.on(channel, wrapped);
    return () => ipcRenderer.removeListener(channel, wrapped);
  },
};

contextBridge.exposeInMainWorld('winscreen', api);
