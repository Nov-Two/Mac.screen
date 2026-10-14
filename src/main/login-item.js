'use strict';

/**
 * 开机自启动。对应 Mac 版 LoginItemController.swift。
 * Windows 下写入 HKCU\Software\Microsoft\Windows\CurrentVersion\Run。
 */

const { app } = require('electron');

const AUTOSTART_FLAG = '--autostart';

function isEnabled() {
  try {
    return Boolean(
      app.getLoginItemSettings({ path: process.execPath, args: [AUTOSTART_FLAG] }).openAtLogin
    );
  } catch {
    return false;
  }
}

function setEnabled(enabled) {
  const options = {
    openAtLogin: Boolean(enabled),
    path: process.execPath,
    args: [AUTOSTART_FLAG],
  };
  if (process.platform === 'darwin') {
    options.openAsHidden = true;
  }
  app.setLoginItemSettings(options);
  return isEnabled();
}

/** 本次启动是否由开机自启触发 */
function launchedByAutostart() {
  return process.argv.includes(AUTOSTART_FLAG);
}

module.exports = { isEnabled, setEnabled, launchedByAutostart, AUTOSTART_FLAG };
