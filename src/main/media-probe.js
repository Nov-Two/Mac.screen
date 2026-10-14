'use strict';

/**
 * 媒体探测：读取视频时长、分辨率，并截取一帧生成缩略图。
 *
 * 实现方式是一个隐藏的 BrowserWindow，借用 Chromium 自带的解码器，
 * 因此不需要打包 ffmpeg（可省下 ~80MB 体积），也不依赖任何原生编译。
 */

const fs = require('fs');
const path = require('path');
const { BrowserWindow } = require('electron');

const config = require('./config');
const protocol = require('./protocol');

class MediaProbe {
  constructor() {
    this.win = null;
    this.readyPromise = null;
    this.destroyed = false;
    /** 串行队列：Chromium 同时解码多个视频会互相抢资源，逐个来更稳 */
    this.queue = Promise.resolve();
  }

  _ensureWindow() {
    if (this.destroyed) return Promise.reject(new Error('probe-destroyed'));
    if (this.readyPromise) return this.readyPromise;

    this.readyPromise = new Promise((resolve, reject) => {
      const win = new BrowserWindow({
        width: 640,
        height: 360,
        show: false,
        frame: false,
        skipTaskbar: true,
        // 隐藏窗口也要持续产出画面，否则截图拿不到帧
        paintWhenInitiallyHidden: true,
        webPreferences: {
          backgroundThrottling: false,
          nodeIntegration: false,
          contextIsolation: true,
          sandbox: false,
          webSecurity: true,
          offscreen: false,
        },
      });

      win.on('closed', () => {
        this.win = null;
        this.readyPromise = null;
      });

      const timeout = setTimeout(() => reject(new Error('probe-window-timeout')), 15000);

      win.webContents.once('did-finish-load', () => {
        clearTimeout(timeout);
        resolve(win);
      });
      win.webContents.once('did-fail-load', (_event, code, description) => {
        clearTimeout(timeout);
        reject(new Error(`probe-window-load-failed: ${code} ${description}`));
      });

      win.loadURL('wsmedia://app/probe.html');
      this.win = win;
    }).catch((error) => {
      this.readyPromise = null;
      throw error;
    });

    return this.readyPromise;
  }

  /**
   * @param {string} filePath 本地视频绝对路径
   * @param {{seekSeconds?:number, maxWidth?:number}} [options]
   * @returns {Promise<{ok:boolean,width?:number,height?:number,duration?:number,dataUrl?:string,error?:string}>}
   */
  probe(filePath, options = {}) {
    const run = () => this._probeOnce(filePath, options);
    // 串行执行，避免多个视频同时解码
    const result = this.queue.then(run, run);
    this.queue = result.catch(() => {});
    return result;
  }

  async _probeOnce(filePath, options) {
    const seekSeconds = options.seekSeconds ?? config.THUMBNAIL_SEEK_SECONDS;
    const maxWidth = options.maxWidth ?? config.THUMBNAIL_MAX_WIDTH;

    let win;
    try {
      win = await this._ensureWindow();
    } catch (error) {
      return { ok: false, error: error.message };
    }
    if (!win || win.isDestroyed()) return { ok: false, error: 'probe-window-gone' };

    const mediaUrl = protocol.toMediaUrl(filePath);
    const script = `window.__probe(${JSON.stringify(mediaUrl)}, ${Number(
      seekSeconds
    )}, ${Number(maxWidth)})`;

    try {
      const result = await win.webContents.executeJavaScript(script, true);
      return result && typeof result === 'object' ? result : { ok: false, error: 'bad-result' };
    } catch (error) {
      return { ok: false, error: error.message };
    }
  }

  /**
   * 探测并落盘缩略图。
   * @returns {Promise<{ok:boolean,thumbnailPath?:string,width?:number,height?:number,duration?:number,error?:string}>}
   */
  async probeAndCache(filePath) {
    const result = await this.probe(filePath);
    if (!result.ok || !result.dataUrl) {
      return {
        ok: false,
        error: result.error || 'no-frame',
        width: result.width,
        height: result.height,
        duration: result.duration,
      };
    }

    const thumbnailPath = thumbnailPathFor(filePath);
    try {
      await fs.promises.mkdir(path.dirname(thumbnailPath), { recursive: true });
      const base64 = result.dataUrl.replace(/^data:image\/\w+;base64,/, '');
      await fs.promises.writeFile(thumbnailPath, Buffer.from(base64, 'base64'));
    } catch (error) {
      return { ok: false, error: `thumbnail-write-failed: ${error.message}` };
    }

    return {
      ok: true,
      thumbnailPath,
      width: result.width,
      height: result.height,
      duration: result.duration,
    };
  }

  destroy() {
    this.destroyed = true;
    if (this.win && !this.win.isDestroyed()) {
      this.win.destroy();
    }
    this.win = null;
    this.readyPromise = null;
  }
}

/** 缩略图文件名：视频路径的稳定哈希，避免中文/特殊字符问题 */
function thumbnailPathFor(filePath) {
  const crypto = require('crypto');
  const hash = crypto.createHash('sha1').update(path.resolve(filePath)).digest('hex');
  return path.join(config.thumbnailDirectory(), `${hash}.png`);
}

module.exports = { MediaProbe, thumbnailPathFor };
