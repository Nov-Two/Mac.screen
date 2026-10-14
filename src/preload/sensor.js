'use strict';

/**
 * 电源传感器 preload。
 * Electron 主进程没有直接的电池电量 API，这里让一个常驻的隐藏页面
 * 通过浏览器的 Battery Status API 采集电量，再转发给主进程。
 */

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('sensorBridge', {
  report: (payload) => ipcRenderer.send('sensor:battery', payload),
});
