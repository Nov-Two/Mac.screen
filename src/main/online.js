'use strict';

/**
 * 在线素材库。
 *
 * 原项目把动态壁纸素材放在 GitHub 仓库的 AuthorVideos/ 目录下，单个文件
 * 5~47MB，全部内置进安装包会让体积膨胀到 400MB 以上。这里改成
 * 「内置清单 + 按需下载」：应用自带一份素材清单，用户点选后流式下载到
 * 本地素材库，下载完成即可直接应用。
 *
 * 清单可以离线使用；联网时也能尝试从 GitHub API 拉取最新目录（受
 * 匿名调用频率限制，失败则静默回退到本地清单）。
 */

const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const { net } = require('electron');

const config = require('./config');

const MANIFEST_PATH = path.join(__dirname, '..', '..', 'assets', 'materials.json');

function formatSize(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) return '--';
  const units = ['B', 'KB', 'MB', 'GB'];
  let value = bytes;
  let index = 0;
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index += 1;
  }
  return `${value.toFixed(index === 0 ? 0 : 1)} ${units[index]}`;
}

class OnlineMaterials {
  constructor({ library, emit, settings }) {
    this.library = library;
    this.emit = emit || (() => {});
    this.settings = settings;
    this.activeDownloads = new Map();
  }

  /** 读取本地清单 */
  list() {
    let manifest;
    try {
      manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
    } catch (error) {
      return { ok: false, reason: 'manifest-missing', message: error.message, items: [] };
    }

    const items = (manifest.items || []).map((entry) => {
      const rawUrl = `${config.MATERIALS_RAW_BASE}/${entry.folder}/${encodeURIComponent(entry.name)}`;
      return {
        id: `${entry.folder}/${entry.name}`,
        name: entry.name,
        title: entry.name.replace(/\.[^.]+$/, ''),
        folder: entry.folder,
        size: entry.size,
        sizeText: formatSize(entry.size),
        rawUrl,
        pageUrl: config.MATERIALS_PAGE_URL,
      };
    });

    return {
      ok: true,
      repository: manifest.repository || config.MATERIALS_REPOSITORY,
      branch: manifest.branch || config.MATERIALS_BRANCH,
      generatedAt: manifest.generatedAt || null,
      pageUrl: config.MATERIALS_PAGE_URL,
      websiteUrl: config.WALLPAPER_WEBSITE_URL,
      totalSize: items.reduce((sum, item) => sum + (item.size || 0), 0),
      items,
    };
  }

  /** 尝试从 GitHub API 获取最新目录（失败静默回退） */
  async refreshFromRemote() {
    return new Promise((resolve) => {
      const url = `https://api.github.com/repos/${config.MATERIALS_REPOSITORY}/contents/AuthorVideos`;
      const request = net.request({ url, redirect: 'follow' });
      let body = '';
      let settled = false;
      const finish = (payload) => {
        if (settled) return;
        settled = true;
        resolve(payload);
      };

      const timer = setTimeout(() => {
        try {
          request.abort();
        } catch {
          /* 忽略 */
        }
        finish({ ok: false, reason: 'timeout' });
      }, 12000);

      request.on('response', (response) => {
        if (response.statusCode !== 200) {
          clearTimeout(timer);
          finish({ ok: false, reason: `http-${response.statusCode}` });
          response.on('data', () => {});
          return;
        }
        response.on('data', (chunk) => {
          body += chunk.toString('utf8');
        });
        response.on('end', () => {
          clearTimeout(timer);
          try {
            const parsed = JSON.parse(body);
            if (!Array.isArray(parsed)) {
              finish({ ok: false, reason: 'unexpected-payload' });
              return;
            }
            finish({
              ok: true,
              items: parsed
                .filter((entry) => entry.type === 'file')
                .map((entry) => ({
                  name: entry.name,
                  folder: 'AuthorVideos',
                  size: entry.size,
                  sha: entry.sha,
                })),
            });
          } catch (error) {
            finish({ ok: false, reason: `parse-error: ${error.message}` });
          }
        });
      });

      request.on('error', (error) => {
        clearTimeout(timer);
        finish({ ok: false, reason: error.message });
      });

      request.end();
    });
  }

  /**
   * 下载一个素材到用户素材库。
   * @param {{name:string, rawUrl:string, size:number}} payload
   */
  async download(payload) {
    if (!payload || !payload.rawUrl || !payload.name) {
      return { ok: false, reason: 'invalid-payload' };
    }

    await fsp.mkdir(config.downloadDirectory(), { recursive: true });
    await fsp.mkdir(this.library.userDirectory, { recursive: true });

    const safeName = payload.name.replace(/[\\/:*?"<>|]/g, '_');
    const tempPath = path.join(config.downloadDirectory(), `${Date.now()}-${safeName}`);

    this.emit('online:progress', {
      name: payload.name,
      received: 0,
      total: payload.size || 0,
      state: 'downloading',
    });

    try {
      await this._fetchToFile(payload.rawUrl, tempPath, payload);
    } catch (error) {
      await fsp.rm(tempPath, { force: true }).catch(() => {});
      this.emit('online:progress', { name: payload.name, state: 'error', message: error.message });
      return { ok: false, reason: 'download-failed', message: error.message };
    }

    let destination = path.join(this.library.userDirectory, safeName);
    try {
      destination = await uniquePath(this.library.userDirectory, safeName);
      await fsp.rename(tempPath, destination).catch(async () => {
        // 跨盘符时 rename 会失败，退回复制
        await fsp.copyFile(tempPath, destination);
        await fsp.rm(tempPath, { force: true });
      });
    } catch (error) {
      this.emit('online:progress', { name: payload.name, state: 'error', message: error.message });
      return { ok: false, reason: 'move-failed', message: error.message };
    }

    if (this.settings.get('cleansDownloadedResourcesAfterImport')) {
      await fsp.rm(tempPath, { force: true }).catch(() => {});
    }

    this.emit('online:progress', {
      name: payload.name,
      state: 'done',
      path: destination,
    });

    return { ok: true, path: destination };
  }

  _fetchToFile(url, targetPath, payload) {
    return new Promise((resolve, reject) => {
      const request = net.request({ url, redirect: 'follow' });
      const chunks = [];
      let received = 0;
      let lastEmit = 0;

      request.on('response', (response) => {
        if (response.statusCode !== 200) {
          reject(new Error(`HTTP ${response.statusCode}`));
          response.on('data', () => {});
          return;
        }
        const total = Number(response.headers['content-length']) || payload.size || 0;

        response.on('data', (chunk) => {
          chunks.push(chunk);
          received += chunk.length;
          const now = Date.now();
          if (now - lastEmit > 200) {
            lastEmit = now;
            this.emit('online:progress', {
              name: payload.name,
              received,
              total,
              state: 'downloading',
            });
          }
        });

        response.on('end', async () => {
          try {
            await fsp.writeFile(targetPath, Buffer.concat(chunks));
            this.emit('online:progress', { name: payload.name, received, total, state: 'writing' });
            resolve();
          } catch (error) {
            reject(error);
          }
        });

        response.on('error', reject);
      });

      request.on('error', reject);
      request.end();
    });
  }
}

async function uniquePath(directory, fileName) {
  const ext = path.extname(fileName);
  const base = path.basename(fileName, ext);
  let candidate = path.join(directory, fileName);
  let counter = 1;
  for (;;) {
    try {
      await fsp.access(candidate);
      candidate = path.join(directory, `${base}-${counter}${ext}`);
      counter += 1;
    } catch {
      return candidate;
    }
  }
}

module.exports = { OnlineMaterials, MANIFEST_PATH };
