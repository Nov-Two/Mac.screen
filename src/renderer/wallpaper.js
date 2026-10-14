'use strict';

/**
 * 壁纸播放页。
 * 只做三件事：加载视频、循环播放、响应主进程的播放指令。
 */

const params = new URLSearchParams(window.location.search);
const video = document.getElementById('stage');
const veil = document.getElementById('veil');

const initialVolume = Number(params.get('volume') || 0);
const fit = params.get('fit') || 'cover';

document.body.dataset.fit = fit;
video.volume = Math.max(0, Math.min(1, initialVolume));
video.muted = initialVolume === 0;

const source = params.get('src');
if (source) {
  video.src = source;
}

video.addEventListener('loadeddata', () => {
  veil.classList.add('is-hidden');
});

video.addEventListener('canplay', () => {
  veil.classList.add('is-hidden');
  video.play().catch((error) => {
    console.warn('[wallpaper] 自动播放失败:', error.message);
  });
});

// 万一被系统暂停（例如切换显示器），恢复后继续播放
video.addEventListener('pause', () => {
  if (!window.__manualPause) {
    setTimeout(() => {
      if (!window.__manualPause) video.play().catch(() => {});
    }, 400);
  }
});

video.addEventListener('error', () => {
  console.error('[wallpaper] 视频加载失败:', video.error && video.error.code);
});

window.wallpaperBridge.onCommand((command) => {
  if (!command || !command.type) return;

  switch (command.type) {
    case 'play':
      window.__manualPause = false;
      video.play().catch(() => {});
      break;

    case 'pause':
      window.__manualPause = true;
      video.pause();
      break;

    case 'volume': {
      const volume = Math.max(0, Math.min(1, Number(command.volume) || 0));
      video.volume = volume;
      video.muted = volume === 0;
      break;
    }

    case 'fit':
      document.body.dataset.fit = command.fit || 'cover';
      break;

    case 'load':
      if (command.src) {
        video.src = command.src;
        window.__manualPause = false;
        video.play().catch(() => {});
      }
      break;

    default:
      break;
  }
});

window.wallpaperBridge.ready();
