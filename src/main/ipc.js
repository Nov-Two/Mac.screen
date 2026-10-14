'use strict';

/**
 * 主进程 IPC 路由。渲染进程只能通过 preload 暴露的白名单接口触达这里。
 */

const path = require('path');
const { ipcMain, dialog, shell, app, BrowserWindow } = require('electron');

const config = require('./config');
const loginItem = require('./login-item');

function registerIpc({
  service,
  settings,
  online,
  updater,
  power,
  tray,
  getMainWindow,
  showMainWindow,
  hideMainWindow,
  quitApp,
}) {
  const send = (channel, payload) => {
    const win = getMainWindow();
    if (win && !win.isDestroyed()) win.webContents.send(channel, payload);
  };

  const toast = (type, message) => send('toast', { type, message });

  /* ---------------- 应用信息 ---------------- */

  ipcMain.handle('app:info', () => ({
    name: config.APP_NAME,
    version: app.getVersion(),
    platform: process.platform,
    arch: process.arch,
    isPackaged: app.isPackaged,
    electron: process.versions.electron,
    chrome: process.versions.chrome,
    directories: {
      bundled: config.bundledVideoDirectory(),
      user: config.userVideoDirectory(),
      downloads: config.downloadDirectory(),
      userData: app.getPath('userData'),
    },
    capabilities: {
      desktopLayer: require('./win32').describe(),
      autoUpdate: app.isPackaged,
    },
  }));

  ipcMain.handle('app:openExternal', async (_event, url) => {
    if (typeof url !== 'string' || !/^https?:\/\//i.test(url)) return false;
    await shell.openExternal(url);
    return true;
  });

  /* ---------------- 素材库 ---------------- */

  ipcMain.handle('library:list', async () => ({
    items: await service.listItems(),
  }));

  ipcMain.handle('library:import', async () => {
    const win = getMainWindow();
    const result = await dialog.showOpenDialog(win || undefined, {
      title: '选择动态壁纸视频',
      properties: ['openFile', 'multiSelections'],
      filters: [
        { name: '视频文件', extensions: config.SUPPORTED_VIDEO_EXTENSIONS },
        { name: '全部文件', extensions: ['*'] },
      ],
    });
    if (result.canceled || result.filePaths.length === 0) {
      return { canceled: true };
    }
    return runImport(result.filePaths);
  });

  ipcMain.handle('library:importPaths', async (_event, paths) => {
    if (!Array.isArray(paths) || paths.length === 0) return { canceled: true };
    return runImport(paths.filter((p) => typeof p === 'string'));
  });

  async function runImport(paths) {
    const result = await service.importResources(paths);
    await service.refresh();

    const parts = [];
    if (result.imported.length > 0) {
      parts.push(`已导入 ${result.imported.length} 个视频。`);
    } else {
      parts.push('没有导入支持的视频文件。');
    }
    if (result.rejected.length > 0) {
      const names = result.rejected.slice(0, 3).join('、');
      const suffix = result.rejected.length > 3 ? ` 等 ${result.rejected.length} 个文件` : '';
      parts.push(
        `已跳过低分辨率视频：${names}${suffix}。请使用至少 ${config.MIN_VIDEO_WIDTH}x${config.MIN_VIDEO_HEIGHT} 的视频。`
      );
    }
    if (result.failed.length > 0) {
      parts.push(`有 ${result.failed.length} 个文件导入失败。`);
    }

    const message = parts.join(' ');
    toast(result.imported.length > 0 ? 'success' : 'warning', message);

    return {
      canceled: false,
      imported: result.imported,
      rejected: result.rejected,
      failed: result.failed,
      message,
    };
  }

  ipcMain.handle('library:delete', async (_event, paths) => {
    const result = await service.deleteItems(Array.isArray(paths) ? paths : []);
    toast('info', result.message);
    return result;
  });

  ipcMain.handle('library:restoreBundled', async () => {
    const message = await service.restoreBundledVideos();
    toast('success', message);
    return { message };
  });

  ipcMain.handle('library:toggleFavorite', async (_event, itemPath) => {
    const isFavorite = service.toggleFavorite(itemPath);
    return { isFavorite };
  });

  ipcMain.handle('library:reveal', async (_event, target) => service.reveal(target));

  ipcMain.handle('library:openFolder', async (_event, kind) => service.openFolder(kind));

  /* ---------------- 壁纸控制 ---------------- */

  ipcMain.handle('wallpaper:apply', async (_event, itemPath) => {
    const result = await service.applyPath(itemPath);
    tray.refresh();
    if (!result.ok) {
      const reasons = {
        'file-not-found': '素材文件不存在，可能已被移动或删除。',
        'load-failed': '壁纸页面加载失败。',
        'window-destroyed': '壁纸窗口创建失败。',
      };
      toast('error', reasons[result.reason] || '应用壁纸失败。');
    } else if (result.mode === 'bottom') {
      toast(
        'warning',
        '未能挂到桌面图标层，已退化为置底窗口播放。请确认系统为 Windows 10/11 且未运行冲突的美化软件。'
      );
    } else {
      toast('success', `已应用到桌面：${result.title}`);
    }
    return result;
  });

  ipcMain.handle('wallpaper:pause', async () => {
    service.controller.pause();
    tray.refresh();
    return service.getState();
  });

  ipcMain.handle('wallpaper:resume', async () => {
    service.controller.resume();
    tray.refresh();
    return service.getState();
  });

  ipcMain.handle('wallpaper:toggle', async () => {
    service.controller.togglePause();
    tray.refresh();
    return service.getState();
  });

  ipcMain.handle('wallpaper:stop', async () => {
    service.controller.stop();
    settings.set('lastWallpaperPath', null);
    tray.refresh();
    return service.getState();
  });

  ipcMain.handle('wallpaper:next', async () => {
    const result = await service.next();
    tray.refresh();
    if (result.ok) toast('success', `已切换到：${result.title}`);
    else toast('warning', '素材库为空，无法切换。');
    return result;
  });

  ipcMain.handle('wallpaper:state', async () => service.getState());

  ipcMain.handle('wallpaper:setVolume', async (_event, volume) => {
    const value = service.controller.setVolume(volume);
    tray.refresh();
    return { volume: value };
  });

  ipcMain.handle('wallpaper:setFit', async (_event, fit) => {
    service.controller.setFit(fit);
    tray.refresh();
    return { fit };
  });

  ipcMain.handle('wallpaper:probe', async (_event, itemPath) => {
    if (typeof itemPath !== 'string' || !itemPath) return { ok: false };
    const item = service.findItem(itemPath);
    if (!item) return { ok: false, reason: 'not-found' };
    return {
      ok: true,
      path: item.path,
      thumbnailPath: item.thumbnailPath,
      width: item.width,
      height: item.height,
      duration: item.duration,
    };
  });

  /* ---------------- 设置 ---------------- */

  ipcMain.handle('settings:all', async () => {
    const all = settings.all();
    return { ...all, opensAtLogin: loginItem.isEnabled() };
  });

  ipcMain.handle('settings:set', async (_event, { key, value }) => {
    if (key === 'opensAtLogin') {
      try {
        loginItem.setEnabled(Boolean(value));
        settings.set('opensAtLogin', loginItem.isEnabled());
      } catch (error) {
        return { ok: false, message: `更新开机启动失败：${error.message}` };
      }
      tray.refresh();
      return { ok: true, value: settings.get('opensAtLogin') };
    }

    settings.set(key, value);

    if (key === 'wallpaperVolume') {
      service.controller.setVolume(value);
    }
    if (key === 'videoFit') {
      service.controller.setFit(value);
    }
    tray.refresh();
    return { ok: true, value };
  });

  ipcMain.handle('settings:toggle', async (_event, key) => {
    if (key === 'opensAtLogin') {
      const next = !loginItem.isEnabled();
      try {
        loginItem.setEnabled(next);
      } catch (error) {
        return { ok: false, message: `更新开机启动失败：${error.message}` };
      }
      settings.set('opensAtLogin', loginItem.isEnabled());
      tray.refresh();
      return { ok: true, value: settings.get('opensAtLogin') };
    }

    const value = settings.toggle(key);
    if (key === 'wallpaperVolume') service.controller.setVolume(value);
    tray.refresh();
    return { ok: true, value };
  });

  /* ---------------- 在线素材 ---------------- */

  ipcMain.handle('online:list', async (_event, { refresh = false } = {}) => {
    const local = online.list();
    if (!refresh) return local;

    const remote = await online.refreshFromRemote();
    if (!remote.ok) {
      return { ...local, remoteError: remote.reason };
    }

    const localById = new Map(local.items.map((item) => [item.id, item]));
    const items = remote.items
      .map((entry) => {
        const id = `${entry.folder}/${entry.name}`;
        const known = localById.get(id);
        return (
          known || {
            id,
            name: entry.name,
            title: entry.name.replace(/\.[^.]+$/, ''),
            folder: entry.folder,
            size: entry.size,
            sizeText: '--',
            rawUrl: `${config.MATERIALS_RAW_BASE}/${entry.folder}/${encodeURIComponent(entry.name)}`,
            pageUrl: config.MATERIALS_PAGE_URL,
          }
        );
      })
      .sort((a, b) => a.title.localeCompare(b.title, 'zh-Hans-CN', { numeric: true }));

    return { ...local, items, refreshedAt: new Date().toISOString() };
  });

  ipcMain.handle('online:download', async (_event, payload) => {
    const result = await online.download(payload);
    if (result.ok) {
      await service.refresh();
      toast('success', `已下载并导入：${path.basename(result.path)}`);
    } else {
      toast('error', `下载失败：${result.message || result.reason}`);
    }
    return result;
  });

  ipcMain.handle('online:openPage', async () => {
    await shell.openExternal(config.MATERIALS_PAGE_URL);
    return true;
  });

  /* ---------------- 更新 ---------------- */

  ipcMain.handle('updater:check', async () => {
    const result = await updater.check();
    if (!result.ok) toast('info', result.message || '暂时无法检查更新。');
    return result;
  });

  /* ---------------- 窗口控制 ---------------- */

  ipcMain.handle('window:minimize', () => {
    const win = getMainWindow();
    if (win && !win.isDestroyed()) win.minimize();
  });

  ipcMain.handle('window:hide', () => hideMainWindow());

  ipcMain.handle('window:toggleMaximize', () => {
    const win = getMainWindow();
    if (!win || win.isDestroyed()) return false;
    if (win.isMaximized()) win.unmaximize();
    else win.maximize();
    return win.isMaximized();
  });

  ipcMain.handle('window:close', () => {
    const win = getMainWindow();
    if (!win || win.isDestroyed()) return;
    if (settings.get('closeToTray') === false) quitApp();
    else hideMainWindow();
  });

  /* ---------------- 渲染层主动上报 ---------------- */

  ipcMain.on('sensor:battery', (_event, payload) => {
    power.handleReport(payload);
  });

  ipcMain.on('wallpaper:ready', () => {
    tray.refresh();
  });

  ipcMain.on('ui:selection', (_event, selectedPath) => {
    tray.setSelectedPath(selectedPath);
  });

  ipcMain.on('ui:state', (_event, payload) => {
    if (payload && typeof payload === 'object') {
      settings.patch(payload);
    }
  });

  return { send, toast };
}

module.exports = { registerIpc };
