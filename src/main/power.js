'use strict';

/**
 * 低电量暂停。
 * 对应 Mac 版 LowBatteryMonitorController.swift。
 *
 * Electron 主进程没有电池电量接口，这里用一个常驻隐藏页面
 * 通过 navigator.getBattery() 采集，再回报给主进程。
 */

const path = require('path');
const { BrowserWindow } = require('electron');

const config = require('./config');

const SENSOR_PRELOAD = path.join(__dirname, '..', 'preload', 'sensor.js');

class PowerMonitor {
  constructor({ settings, onLowBattery, onRecover, emit }) {
    this.settings = settings;
    this.onLowBattery = onLowBattery;
    this.onRecover = onRecover;
    this.emit = emit || (() => {});

    this.window = null;
    this.lastReport = null;
    this.thresholdNotified = false;
    this.timer = null;
  }

  start() {
    if (this.window) return;

    this.window = new BrowserWindow({
      width: 200,
      height: 120,
      show: false,
      skipTaskbar: true,
      frame: false,
      webPreferences: {
        preload: SENSOR_PRELOAD,
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: false,
        backgroundThrottling: false,
      },
    });
    this.window.loadURL('wsmedia://app/sensor.html');
    this.window.on('closed', () => {
      this.window = null;
    });

    // 页面每 60s 主动上报一次，这里再做一层兜底轮询
    this.timer = setInterval(() => this._poll(), config.LOW_BATTERY_INTERVAL);
  }

  async _poll() {
    if (!this.window || this.window.isDestroyed()) return;
    try {
      const report = await this.window.webContents.executeJavaScript(
        'window.__readBattery ? window.__readBattery() : null',
        true
      );
      if (report) this.handleReport(report);
    } catch {
      /* 忽略 */
    }
  }

  /** 渲染层上报：{ level: 0~1, charging: boolean, supported: boolean } */
  handleReport(report) {
    if (!report || typeof report !== 'object') return;
    this.lastReport = report;

    const enabled = Boolean(this.settings.get('pausesOnLowBattery'));
    const threshold = config.LOW_BATTERY_THRESHOLD / 100;

    if (!enabled || !report.supported || report.charging || report.level == null) {
      this.thresholdNotified = false;
      return;
    }

    if (report.level <= threshold) {
      if (!this.thresholdNotified) {
        this.thresholdNotified = true;
        this.onLowBattery({ level: report.level, threshold: config.LOW_BATTERY_THRESHOLD });
      }
    } else if (report.level > threshold + 0.03) {
      this.thresholdNotified = false;
      if (this.onRecover) this.onRecover();
    }
  }

  getStatus() {
    return this.lastReport;
  }

  destroy() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (this.window && !this.window.isDestroyed()) this.window.destroy();
    this.window = null;
  }
}

module.exports = { PowerMonitor };
