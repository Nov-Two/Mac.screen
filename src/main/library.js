'use strict';

/**
 * 素材库。
 * 对应 Mac 版 WallpaperLibrary.swift + WallpaperItem.swift + FileSystemHelper.swift。
 *
 * 职责：
 *  - 扫描「内置素材目录」与「用户素材目录」，产出素材卡片数据
 *  - 维护元数据缓存（时长 / 分辨率 / 体积 / 缩略图），避免每次启动都重新解码
 *  - 导入本地视频 / zip 资源包，做分辨率校验与重名处理
 *  - 删除用户素材、隐藏内置素材、恢复内置素材
 */

const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const crypto = require('crypto');

const config = require('./config');
const protocol = require('./protocol');
const { thumbnailPathFor } = require('./media-probe');

/* ------------------------------------------------------------------ *
 * 标题 / 标签 / 分类推导（移植自 Mac 版 WallpaperItem）
 * ------------------------------------------------------------------ */

const TAG_SEPARATORS = /[\s\-_\[\]【】()（）·]+/;
const DROPPED_TAGS = new Set(['哲风壁纸', '动态壁纸']);

function makeDisplayTags(title) {
  return title
    .split(TAG_SEPARATORS)
    .map((tag) => tag.trim())
    .filter((tag) => tag.length > 0 && !DROPPED_TAGS.has(tag))
    .slice(0, 6);
}

function makeMainCategory(title, displayTags) {
  const text = `${title} ${displayTags.join(' ')}`.toLowerCase();

  if (['二次元', '动漫', '动画', '线稿', 'kuroha'].some((k) => text.includes(k))) return '二次元';
  if (['风景', '云', '山', '海', '户外', '露营', '星空', '城市'].some((k) => text.includes(k))) return '风景';
  if (['少女', '甜妹', '人物', '原神', '女神', '精灵'].some((k) => text.includes(k))) return '人物';
  return '其他';
}

function formatDuration(seconds) {
  if (!Number.isFinite(seconds) || seconds <= 0) return '--';
  if (seconds < 60) return `${seconds.toFixed(1)}s`;
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

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

/* ------------------------------------------------------------------ *
 * 元数据缓存
 * ------------------------------------------------------------------ */

class MetadataCache {
  constructor(filePath) {
    this.filePath = filePath;
    this.data = {};
    this._timer = null;
    this._load();
  }

  _load() {
    try {
      this.data = JSON.parse(fs.readFileSync(this.filePath, 'utf8')) || {};
    } catch {
      this.data = {};
    }
  }

  get(filePath, stat) {
    const entry = this.data[filePath];
    if (!entry) return null;
    if (entry.size !== stat.size || entry.mtimeMs !== Math.round(stat.mtimeMs)) return null;
    return entry;
  }

  set(filePath, stat, patch) {
    this.data[filePath] = {
      size: stat.size,
      mtimeMs: Math.round(stat.mtimeMs),
      ...patch,
    };
    this._scheduleSave();
  }

  remove(filePath) {
    if (this.data[filePath]) {
      delete this.data[filePath];
      this._scheduleSave();
    }
  }

  prune(existingPaths) {
    let changed = false;
    for (const key of Object.keys(this.data)) {
      if (!existingPaths.has(key)) {
        delete this.data[key];
        changed = true;
      }
    }
    if (changed) this._scheduleSave();
  }

  _scheduleSave() {
    if (this._timer) return;
    this._timer = setTimeout(() => {
      this._timer = null;
      this.flush();
    }, 800);
  }

  flush() {
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
    try {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      const tmp = `${this.filePath}.tmp`;
      fs.writeFileSync(tmp, JSON.stringify(this.data), 'utf8');
      fs.renameSync(tmp, this.filePath);
    } catch (error) {
      console.error('[metadata] 写入失败:', error.message);
    }
  }
}

/* ------------------------------------------------------------------ *
 * 素材库
 * ------------------------------------------------------------------ */

class WallpaperLibrary {
  /**
   * @param {object} deps
   * @param {import('./settings').SettingsStore} deps.settings
   * @param {import('./media-probe').MediaProbe} deps.probe
   * @param {(channel:string, payload:any)=>void} deps.emit
   */
  constructor({ settings, probe, emit }) {
    this.settings = settings;
    this.probe = probe;
    this.emit = emit || (() => {});
    this.cache = new MetadataCache(config.metadataCacheFile());
    this._enriching = false;
    this._pendingEnrich = new Set();
  }

  get bundledDirectory() {
    return config.bundledVideoDirectory();
  }

  get userDirectory() {
    return config.userVideoDirectory();
  }

  /* ---------------- 扫描 ---------------- */

  /**
   * 立即返回素材列表（优先使用缓存），未命中缓存的条目会带上 needsProbe 标记。
   * 调用方随后应调用 enrich() 在后台补齐。
   */
  async listItems() {
    const hidden = new Set(this.settings.get('hiddenWallpaperPaths') || []);
    const favorites = new Set(this.settings.get('favoriteWallpaperPaths') || []);

    const seen = new Set();
    const items = [];

    for (const [directory, kind] of [
      [this.bundledDirectory, 'bundled'],
      [this.userDirectory, 'user'],
    ]) {
      const files = await this._videoFilesIn(directory);
      for (const filePath of files) {
        if (hidden.has(filePath) || seen.has(filePath)) continue;
        seen.add(filePath);

        let stat;
        try {
          stat = await fsp.stat(filePath);
        } catch {
          continue;
        }

        const cached = this.cache.get(filePath, stat);
        const thumbnailPath = thumbnailPathFor(filePath);
        const hasThumbnail = fs.existsSync(thumbnailPath);

        items.push(
          this._buildItem({
            filePath,
            kind,
            stat,
            metadata: cached,
            thumbnailPath: hasThumbnail ? thumbnailPath : null,
            isFavorite: favorites.has(filePath),
          })
        );
      }
    }

    this.cache.prune(seen);

    items.sort((a, b) =>
      a.title.localeCompare(b.title, 'zh-Hans-CN', { numeric: true, sensitivity: 'base' })
    );
    return items;
  }

  async _videoFilesIn(directory) {
    let entries;
    try {
      entries = await fsp.readdir(directory, { withFileTypes: true });
    } catch {
      return [];
    }
    return entries
      .filter((entry) => entry.isFile() && config.isSupportedVideo(entry.name))
      .map((entry) => path.join(directory, entry.name))
      .sort((a, b) =>
        path.basename(a).localeCompare(path.basename(b), 'zh-Hans-CN', {
          numeric: true,
          sensitivity: 'base',
        })
      );
  }

  _buildItem({ filePath, kind, stat, metadata, thumbnailPath, isFavorite }) {
    const title = path.basename(filePath, path.extname(filePath));
    const tags = makeDisplayTags(title);
    const width = metadata?.width || 0;
    const height = metadata?.height || 0;

    return {
      id: filePath,
      path: filePath,
      videoUrl: protocol.toMediaUrl(filePath),
      fileName: path.basename(filePath),
      title,
      tags,
      category: makeMainCategory(title, tags),
      kind,
      isUserVideo: kind === 'user',
      isFavorite: Boolean(isFavorite),
      size: stat.size,
      sizeText: formatSize(stat.size),
      mtimeMs: Math.round(stat.mtimeMs),
      duration: metadata?.duration ?? null,
      durationText: formatDuration(metadata?.duration),
      width,
      height,
      resolutionText: width && height ? `${width}x${height}` : '--',
      thumbnailPath: thumbnailPath || null,
      thumbnailUrl: thumbnailPath ? protocol.toMediaUrl(thumbnailPath) : null,
      needsProbe: !metadata,
    };
  }

  /* ---------------- 后台补齐元数据 ---------------- */

  /**
   * 对缺少元数据的素材逐个探测，边探测边通过事件推给界面。
   * @param {Array<object>} items
   */
  async enrich(items, { force = false } = {}) {
    const targets = items.filter((item) => force || item.needsProbe);
    if (targets.length === 0) return;

    this.emit('library:enrich:start', { total: targets.length });

    let done = 0;
    for (const item of targets) {
      if (this._pendingEnrich.has(item.path)) continue;
      this._pendingEnrich.add(item.path);
      try {
        const result = await this._probeItem(item.path);
        done += 1;
        this.emit('library:enrich:item', { path: item.path, ...result, done, total: targets.length });
      } finally {
        this._pendingEnrich.delete(item.path);
      }
    }

    this.emit('library:enrich:end', { total: targets.length });
  }

  async _probeItem(filePath) {
    let stat;
    try {
      stat = await fsp.stat(filePath);
    } catch {
      return { ok: false, error: 'not-found' };
    }

    const result = await this.probe.probeAndCache(filePath);
    if (!result.ok) {
      // 至少记录时长/分辨率，避免反复重试
      if (result.width && result.height) {
        this.cache.set(filePath, stat, {
          width: result.width,
          height: result.height,
          duration: result.duration ?? null,
        });
      }
      return { ok: false, error: result.error };
    }

    this.cache.set(filePath, stat, {
      width: result.width,
      height: result.height,
      duration: result.duration ?? null,
      thumbnailPath: result.thumbnailPath,
    });

    return {
      ok: true,
      width: result.width,
      height: result.height,
      duration: result.duration,
      durationText: formatDuration(result.duration),
      resolutionText: `${result.width}x${result.height}`,
      thumbnailPath: result.thumbnailPath,
      thumbnailUrl: protocol.toMediaUrl(result.thumbnailPath),
    };
  }

  /* ---------------- 导入 ---------------- */

  /**
   * 导入本地视频。
   * @returns {Promise<{imported:string[], rejected:string[], failed:string[]}>}
   */
  async importVideos(sourcePaths) {
    await fsp.mkdir(this.userDirectory, { recursive: true });

    const imported = [];
    const rejected = [];
    const failed = [];
    const skipCheck = Boolean(this.settings.get('skipResolutionCheck'));

    for (const sourcePath of sourcePaths) {
      if (!config.isSupportedVideo(sourcePath)) continue;

      if (!skipCheck) {
        const meta = await this._metadataForImport(sourcePath);
        if (!meta || !meetsResolutionRequirement(meta.width, meta.height)) {
          rejected.push(path.basename(sourcePath));
          continue;
        }
      }

      try {
        const destination = await uniquePath(this.userDirectory, path.basename(sourcePath));
        await fsp.copyFile(sourcePath, destination);
        imported.push(destination);
        // 顺手把探测结果写进缓存，导入后立刻能看到缩略图
        try {
          const stat = await fsp.stat(destination);
          const meta = await this._metadataForImport(destination, { force: true });
          if (meta) {
            this.cache.set(destination, stat, {
              width: meta.width,
              height: meta.height,
              duration: meta.duration ?? null,
            });
          }
        } catch {
          /* 元数据补齐失败不影响导入 */
        }
      } catch (error) {
        console.error('[library] 导入失败:', sourcePath, error.message);
        failed.push(path.basename(sourcePath));
      }
    }

    return { imported, rejected, failed };
  }

  /** 导入视频或 zip 资源包 */
  async importResources(sourcePaths) {
    const imported = [];
    const rejected = [];
    const failed = [];

    for (const sourcePath of sourcePaths) {
      if (config.isSupportedVideo(sourcePath)) {
        const result = await this.importVideos([sourcePath]);
        imported.push(...result.imported);
        rejected.push(...result.rejected);
        failed.push(...result.failed);
      } else if (config.isSupportedArchive(sourcePath)) {
        const result = await this.importArchive(sourcePath);
        imported.push(...result.imported);
        rejected.push(...result.rejected);
        failed.push(...result.failed);
      }
    }

    return { imported, rejected, failed };
  }

  /** 解包 zip 并导入其中的视频 */
  async importArchive(archivePath) {
    const extractZip = require('extract-zip');
    const tempDir = await fsp.mkdtemp(path.join(require('os').tmpdir(), 'winscreen-unzip-'));
    try {
      await extractZip(archivePath, { dir: tempDir });
      const videos = await collectFilesRecursive(tempDir, config.isSupportedVideo);
      return await this.importVideos(videos);
    } catch (error) {
      console.error('[library] 解包失败:', archivePath, error.message);
      return { imported: [], rejected: [], failed: [path.basename(archivePath)] };
    } finally {
      await fsp.rm(tempDir, { recursive: true, force: true }).catch(() => {});
    }
  }

  async _metadataForImport(filePath, { force = false } = {}) {
    try {
      const stat = await fsp.stat(filePath);
      if (!force) {
        const cached = this.cache.get(filePath, stat);
        if (cached?.width && cached?.height) return cached;
      }
    } catch {
      return null;
    }
    const result = await this.probe.probe(filePath, { seekSeconds: 0 });
    if (!result.ok || !result.width || !result.height) return null;
    return { width: result.width, height: result.height, duration: result.duration };
  }

  /* ---------------- 删除 / 隐藏 / 恢复 ---------------- */

  /**
   * 删除素材。用户素材真删，内置素材只从列表隐藏。
   * @param {Array<{path:string, kind:string}>} items
   */
  async deleteItems(items) {
    let removedUser = 0;
    let hiddenBundled = 0;
    const hidden = new Set(this.settings.get('hiddenWallpaperPaths') || []);

    for (const item of items) {
      if (item.kind === 'user') {
        try {
          await fsp.rm(item.path, { force: true });
          this.cache.remove(item.path);
          await fsp.rm(thumbnailPathFor(item.path), { force: true }).catch(() => {});
          removedUser += 1;
        } catch (error) {
          console.error('[library] 删除失败:', item.path, error.message);
        }
      } else {
        hidden.add(item.path);
        hiddenBundled += 1;
      }
    }

    this.settings.set('hiddenWallpaperPaths', Array.from(hidden).sort());

    if (removedUser > 0 && hiddenBundled > 0) {
      return `已删除 ${removedUser} 个自定义素材，并移除 ${hiddenBundled} 个内置素材。`;
    }
    if (removedUser > 0) return `已删除 ${removedUser} 个自定义素材。`;
    if (hiddenBundled > 0) return `已从列表移除 ${hiddenBundled} 个内置素材。`;
    return '没有素材被删除。';
  }

  restoreBundledVideos() {
    this.settings.set('hiddenWallpaperPaths', []);
    return '已恢复内置素材。';
  }

  /* ---------------- 收藏 ---------------- */

  toggleFavorite(filePath) {
    const favorites = new Set(this.settings.get('favoriteWallpaperPaths') || []);
    let isFavorite;
    if (favorites.has(filePath)) {
      favorites.delete(filePath);
      isFavorite = false;
    } else {
      favorites.add(filePath);
      isFavorite = true;
    }
    this.settings.set('favoriteWallpaperPaths', Array.from(favorites).sort());
    return isFavorite;
  }

  /* ---------------- 目录 ---------------- */

  async ensureDirectories() {
    await Promise.all([
      fsp.mkdir(this.userDirectory, { recursive: true }),
      fsp.mkdir(config.thumbnailDirectory(), { recursive: true }),
      fsp.mkdir(config.downloadDirectory(), { recursive: true }),
      fsp.mkdir(this.bundledDirectory, { recursive: true }),
    ]);
  }
}

/* ------------------------------------------------------------------ *
 * 辅助函数
 * ------------------------------------------------------------------ */

/** 横屏 ≥1920x1080，或竖屏 ≥1080x1920 */
function meetsResolutionRequirement(width, height) {
  if (!width || !height) return false;
  return (
    (width >= config.MIN_VIDEO_WIDTH && height >= config.MIN_VIDEO_HEIGHT) ||
    (width >= config.MIN_VIDEO_HEIGHT && height >= config.MIN_VIDEO_WIDTH)
  );
}

/** 目标目录里若已存在同名文件，追加 -1 / -2 后缀 */
async function uniquePath(directory, fileName) {
  const ext = path.extname(fileName);
  const base = path.basename(fileName, ext);
  let candidate = path.join(directory, fileName);
  let counter = 1;
  while (await exists(candidate)) {
    candidate = path.join(directory, `${base}-${counter}${ext}`);
    counter += 1;
  }
  return candidate;
}

async function exists(target) {
  try {
    await fsp.access(target);
    return true;
  } catch {
    return false;
  }
}

async function collectFilesRecursive(directory, predicate) {
  const results = [];
  let entries;
  try {
    entries = await fsp.readdir(directory, { withFileTypes: true });
  } catch {
    return results;
  }
  for (const entry of entries) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      results.push(...(await collectFilesRecursive(full, predicate)));
    } else if (entry.isFile() && predicate(full)) {
      results.push(full);
    }
  }
  return results;
}

module.exports = {
  WallpaperLibrary,
  MetadataCache,
  makeDisplayTags,
  makeMainCategory,
  formatDuration,
  formatSize,
  meetsResolutionRequirement,
  stableId: (p) => crypto.createHash('sha1').update(p).digest('hex').slice(0, 12),
};
