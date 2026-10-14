'use strict';

/**
 * 电源传感器页面（隐藏常驻）。
 * 用浏览器的 Battery Status API 采集电量，定期回报给主进程。
 * 台式机没有电池时 supported 为 false，主进程会跳过低电量逻辑。
 */

const INTERVAL = 60000;
let lastReport = { supported: false, level: null, charging: true };

async function readBattery() {
  if (typeof navigator.getBattery !== 'function') {
    return { supported: false, level: null, charging: true };
  }
  try {
    const battery = await navigator.getBattery();
    return {
      supported: true,
      level: battery.level,
      charging: battery.charging,
    };
  } catch {
    return { supported: false, level: null, charging: true };
  }
}

/** 供主进程 executeJavaScript 直接调用 */
window.__readBattery = async function () {
  lastReport = await readBattery();
  return lastReport;
};

async function tick() {
  lastReport = await readBattery();
  try {
    window.sensorBridge.report(lastReport);
  } catch {
    /* 忽略 */
  }
}

if (typeof navigator.getBattery === 'function') {
  navigator.getBattery().then((battery) => {
    const push = () => tick();
    battery.addEventListener('levelchange', push);
    battery.addEventListener('chargingchange', push);
  });
}

tick();
setInterval(tick, INTERVAL);
