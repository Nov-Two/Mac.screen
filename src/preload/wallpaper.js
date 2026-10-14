'use strict';

/**
 * 壁纸窗口 preload。只暴露「接收播放指令」和「回报就绪」两件事。
 */

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('wallpaperBridge', {
  onCommand: (listener) => {
    const wrapped = (_event, command) => listener(command);
    ipcRenderer.on('wallpaper:command', wrapped);
    return () => ipcRenderer.removeListener('wallpaper:command', wrapped);
  },
  ready: () => ipcRenderer.send('wallpaper:ready'),
});
