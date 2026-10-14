'use strict';

/**
 * Windows 桌面层挂载（WorkerW 技术）。
 *
 * 原理：Windows 的桌面其实由两层窗口组成 —— Progman（承载壁纸与图标层）
 * 以及一个隐藏的 WorkerW。向 Progman 发送未公开消息 0x052C 会让系统
 * 再派生出一个位于桌面图标之下、所有普通窗口之上的 WorkerW 窗口。
 * 我们把 Electron 的壁纸窗口 SetParent 到这个 WorkerW，就能实现
 * 「视频在桌面图标后面播放、不遮挡任何应用窗口、按 Win+D 不会被覆盖」。
 *
 * 这是 Wallpaper Engine / Lively Wallpaper 等同类软件使用的通用方案。
 * 全部调用都通过 koffi 直接走 user32.dll，不依赖任何需要编译的原生插件。
 *
 * 非 Windows 平台（开发调试用）不会加载本模块的 FFI 部分，
 * 壁纸窗口会退化为「全屏置底窗口」预览模式。
 */

const koffi = require('koffi');

/* ------------------------------------------------------------------ *
 * Win32 常量
 * ------------------------------------------------------------------ */

const WM_SPAWN_WORKER = 0x052c;
const SMTO_NORMAL = 0x0000;

const GWL_STYLE = -16;
const GWL_EXSTYLE = -20;

const WS_CHILD = 0x40000000;
const WS_POPUP = 0x80000000;
const WS_VISIBLE = 0x10000000;
const WS_EX_TOOLWINDOW = 0x00000080;
const WS_EX_APPWINDOW = 0x00040000;
const WS_EX_NOACTIVATE = 0x08000000;

const HWND_BOTTOM = 1;
const HWND_TOP = 0;

const SWP_NOSIZE = 0x0001;
const SWP_NOMOVE = 0x0002;
const SWP_NOZORDER = 0x0004;
const SWP_NOACTIVATE = 0x0010;
const SWP_FRAMECHANGED = 0x0020;
const SWP_SHOWWINDOW = 0x0040;

/* ------------------------------------------------------------------ *
 * koffi 类型解析（不同 koffi 版本对 intptr_t 别名的支持略有差异）
 * ------------------------------------------------------------------ */

function pickTypeName(candidates) {
  for (const name of candidates) {
    try {
      koffi.sizeof(name);
      return name;
    } catch {
      /* 尝试下一个 */
    }
  }
  return candidates[candidates.length - 1];
}

const INTPTR = pickTypeName(['intptr_t', 'int64_t']);
const CALL_CONVENTION = process.platform === 'win32' && process.arch === 'ia32' ? '__stdcall ' : '';

let lib = null;
let fns = null;
let loadError = null;

function loadUser32() {
  if (fns) return fns;
  if (loadError) return null;
  if (process.platform !== 'win32') {
    loadError = '当前平台不是 Windows，桌面层挂载不可用';
    return null;
  }

  try {
    lib = koffi.load('user32.dll');

    const findWindowW = lib.func(`${CALL_CONVENTION}FindWindowW`, 'void *', ['str16', 'str16']);
    const findWindowExW = lib.func(`${CALL_CONVENTION}FindWindowExW`, 'void *', [
      'void *',
      'void *',
      'str16',
      'str16',
    ]);
    const sendMessageTimeoutW = lib.func(
      `${CALL_CONVENTION}SendMessageTimeoutW`,
      INTPTR,
      ['void *', 'uint32_t', 'uintptr_t', INTPTR, 'uint32_t', 'uint32_t', 'void *']
    );
    const enumWindows = lib.func(`${CALL_CONVENTION}EnumWindows`, 'int32_t', [
      koffi.pointer('EnumWindowsProc'),
      INTPTR,
    ]);
    const setParent = lib.func(`${CALL_CONVENTION}SetParent`, 'void *', ['void *', 'void *']);
    const setWindowPos = lib.func(`${CALL_CONVENTION}SetWindowPos`, 'int32_t', [
      'void *',
      'void *',
      'int32_t',
      'int32_t',
      'int32_t',
      'int32_t',
      'uint32_t',
    ]);
    const getWindowLongPtrW = lib.func(`${CALL_CONVENTION}GetWindowLongPtrW`, INTPTR, [
      'void *',
      'int32_t',
    ]);
    const setWindowLongPtrW = lib.func(`${CALL_CONVENTION}SetWindowLongPtrW`, INTPTR, [
      'void *',
      'int32_t',
      INTPTR,
    ]);
    const getClassNameW = lib.func(`${CALL_CONVENTION}GetClassNameW`, 'int32_t', [
      'void *',
      'void *',
      'int32_t',
    ]);
    const isWindow = lib.func(`${CALL_CONVENTION}IsWindow`, 'int32_t', ['void *']);
    const getWindowThreadProcessId = lib.func(
      `${CALL_CONVENTION}GetWindowThreadProcessId`,
      'uint32_t',
      ['void *', 'void *']
    );

    fns = {
      findWindowW,
      findWindowExW,
      sendMessageTimeoutW,
      enumWindows,
      setParent,
      setWindowPos,
      getWindowLongPtrW,
      setWindowLongPtrW,
      getClassNameW,
      isWindow,
      getWindowThreadProcessId,
      EnumWindowsProc: koffi.proto(`${CALL_CONVENTION}EnumWindowsProc`, 'bool', [
        'void *',
        INTPTR,
      ]),
    };
    return fns;
  } catch (error) {
    loadError = error.message;
    console.error('[win32] user32.dll 加载失败:', error.message);
    return null;
  }
}

/* ------------------------------------------------------------------ *
 * 工具
 * ------------------------------------------------------------------ */

function isAvailable() {
  return process.platform === 'win32' && loadUser32() !== null;
}

function describe() {
  return {
    available: isAvailable(),
    platform: process.platform,
    arch: process.arch,
    error: loadError,
  };
}

/** 读取窗口类名，用于诊断 */
function classNameOf(hwnd) {
  const api = loadUser32();
  if (!api || !hwnd) return null;
  try {
    const buffer = Buffer.alloc(512);
    const length = api.getClassNameW(hwnd, buffer, 256);
    if (length <= 0) return null;
    return buffer.toString('ucs2').replace(/\0.*$/, '');
  } catch {
    return null;
  }
}

function isWindowValid(hwnd) {
  const api = loadUser32();
  if (!api || !hwnd) return false;
  try {
    return api.isWindow(hwnd) !== 0;
  } catch {
    return false;
  }
}

/* ------------------------------------------------------------------ *
 * WorkerW 查找
 * ------------------------------------------------------------------ */

/**
 * 向 Progman 发送 0x052C，让系统派生出位于图标层之下的 WorkerW。
 * 返回可作为壁纸宿主的窗口句柄，失败返回 null。
 */
function findWallpaperHost() {
  const api = loadUser32();
  if (!api) return null;

  const progman = api.findWindowW('Progman', null);
  if (!progman) {
    console.warn('[win32] 未找到 Progman 窗口');
    return null;
  }

  // 触发 WorkerW 派生。部分系统版本需要重复发送。
  api.sendMessageTimeoutW(progman, WM_SPAWN_WORKER, 0, 0, SMTO_NORMAL, 1000, null);
  api.sendMessageTimeoutW(progman, WM_SPAWN_WORKER, 0, 0, SMTO_NORMAL, 1000, null);

  let workerw = null;
  let defViewHost = null;

  const callback = koffi.register((hwnd) => {
    // 找到承载桌面图标（SHELLDLL_DefView）的那一层
    const defView = api.findWindowExW(hwnd, null, 'SHELLDLL_DefView', null);
    if (defView) {
      defViewHost = hwnd;
      // 紧随其后的顶层 WorkerW 就是可以铺视频的宿主窗口
      const candidate = api.findWindowExW(null, hwnd, 'WorkerW', null);
      if (candidate) workerw = candidate;
    }
    return true;
  }, koffi.pointer(api.EnumWindowsProc));

  try {
    api.enumWindows(callback, 0);
  } finally {
    try {
      koffi.unregister(callback);
    } catch {
      /* 忽略 */
    }
  }

  if (workerw) return workerw;

  // 兜底一：某些 Windows 版本（含部分 Win11）不会派生独立 WorkerW，
  // 此时 SHELLDLL_DefView 直接挂在 Progman 下，用 Progman 当宿主。
  const progmanDefView = api.findWindowExW(progman, null, 'SHELLDLL_DefView', null);
  if (progmanDefView) {
    console.log('[win32] 未派生独立 WorkerW，回退使用 Progman 作为宿主');
    return progman;
  }

  // 兜底二：任何顶层 WorkerW 都试一下
  const anyWorkerW = api.findWindowW('WorkerW', null);
  if (anyWorkerW) {
    console.log('[win32] 回退使用顶层 WorkerW 作为宿主');
    return anyWorkerW;
  }

  console.warn('[win32] 未能定位桌面宿主窗口', { defViewHost: Boolean(defViewHost) });
  return null;
}

/* ------------------------------------------------------------------ *
 * 窗口修饰
 * ------------------------------------------------------------------ */

/** 让窗口不出现在任务栏与 Alt+Tab 列表中 */
function markAsToolWindow(hwnd) {
  const api = loadUser32();
  if (!api) return;
  try {
    const exStyle = Number(api.getWindowLongPtrW(hwnd, GWL_EXSTYLE));
    const next = (exStyle | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE) & ~WS_EX_APPWINDOW;
    api.setWindowLongPtrW(hwnd, GWL_EXSTYLE, next);
  } catch (error) {
    console.warn('[win32] 设置扩展样式失败:', error.message);
  }
}

/** 把窗口改造成子窗口（SetParent 之后做一次，确保样式一致） */
function markAsChild(hwnd) {
  const api = loadUser32();
  if (!api) return;
  try {
    const style = Number(api.getWindowLongPtrW(hwnd, GWL_STYLE));
    const next = ((style | WS_CHILD | WS_VISIBLE) & ~WS_POPUP) >>> 0;
    api.setWindowLongPtrW(hwnd, GWL_STYLE, next);
  } catch (error) {
    console.warn('[win32] 设置窗口样式失败:', error.message);
  }
}

/**
 * 把壁纸窗口挂到桌面图标层之下。
 * @param {Buffer|BigInt} handle Electron 提供的原生句柄
 * @param {{x:number,y:number,width:number,height:number}} rect 目标矩形（屏幕坐标）
 * @returns {{ok:boolean, mode:'workerw'|'bottom'|'failed', host?:string, reason?:string}}
 */
function attachToDesktop(handle, rect) {
  if (process.platform !== 'win32') {
    return { ok: false, mode: 'failed', reason: 'not-windows' };
  }

  const api = loadUser32();
  if (!api) {
    return { ok: false, mode: 'failed', reason: loadError || 'user32-unavailable' };
  }

  const hwnd = toHwnd(handle);
  if (!hwnd) return { ok: false, mode: 'failed', reason: 'invalid-hwnd' };

  markAsToolWindow(hwnd);

  const host = findWallpaperHost();
  if (host) {
    try {
      api.setParent(hwnd, host);
      markAsChild(hwnd);
      const ok = api.setWindowPos(
        hwnd,
        null,
        Math.round(rect.x),
        Math.round(rect.y),
        Math.round(rect.width),
        Math.round(rect.height),
        SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_FRAMECHANGED
      );
      if (ok !== 0) {
        return { ok: true, mode: 'workerw', host: classNameOf(host) || 'unknown' };
      }
      console.warn('[win32] SetWindowPos 失败，回退置底模式');
    } catch (error) {
      console.warn('[win32] SetParent 失败:', error.message);
    }
  }

  return attachToBottom(hwnd, rect);
}

/** 兜底方案：把窗口压到 z 序最底，不挂桌面层 */
function attachToBottom(handle, rect) {
  const api = loadUser32();
  const hwnd = toHwnd(handle);
  if (!api || !hwnd) return { ok: false, mode: 'failed', reason: 'user32-unavailable' };

  markAsToolWindow(hwnd);
  try {
    const ok = api.setWindowPos(
      hwnd,
      HWND_BOTTOM,
      Math.round(rect.x),
      Math.round(rect.y),
      Math.round(rect.width),
      Math.round(rect.height),
      SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_FRAMECHANGED
    );
    return ok !== 0
      ? { ok: true, mode: 'bottom' }
      : { ok: false, mode: 'failed', reason: 'setwindowpos-failed' };
  } catch (error) {
    return { ok: false, mode: 'failed', reason: error.message };
  }
}

/** 解除桌面层挂载（退出/停止壁纸时调用） */
function detachFromDesktop(handle) {
  if (process.platform !== 'win32') return false;
  const api = loadUser32();
  const hwnd = toHwnd(handle);
  if (!api || !hwnd) return false;
  try {
    if (!isWindowValid(hwnd)) return false;
    api.setParent(hwnd, null);
    return true;
  } catch {
    return false;
  }
}

/** 调整壁纸窗口矩形 */
function setRect(handle, rect) {
  if (process.platform !== 'win32') return false;
  const api = loadUser32();
  const hwnd = toHwnd(handle);
  if (!api || !hwnd) return false;
  try {
    return (
      api.setWindowPos(
        hwnd,
        null,
        Math.round(rect.x),
        Math.round(rect.y),
        Math.round(rect.width),
        Math.round(rect.height),
        SWP_NOACTIVATE | SWP_NOZORDER | SWP_FRAMECHANGED
      ) !== 0
    );
  } catch {
    return false;
  }
}

/**
 * Electron 的 getNativeWindowHandle() 在 Windows 上返回 8 字节小端 Buffer，
 * 在其它平台返回指针宽度不同的 Buffer，统一转换成 koffi 能接受的指针值。
 */
function toHwnd(handle) {
  if (!handle) return null;
  if (typeof handle === 'bigint') return handle;
  if (typeof handle === 'number') return handle;
  if (Buffer.isBuffer(handle)) {
    if (handle.length >= 8) return handle.readBigUInt64LE(0);
    if (handle.length >= 4) return BigInt(handle.readUInt32LE(0));
  }
  return null;
}

module.exports = {
  isAvailable,
  describe,
  attachToDesktop,
  attachToBottom,
  detachFromDesktop,
  setRect,
  findWallpaperHost,
  classNameOf,
  toHwnd,
  WS_CHILD,
  WS_POPUP,
  WS_VISIBLE,
  HWND_BOTTOM,
  HWND_TOP,
  SWP_NOACTIVATE,
  SWP_SHOWWINDOW,
  SWP_FRAMECHANGED,
  SWP_NOSIZE,
  SWP_NOMOVE,
  SWP_NOZORDER,
};
