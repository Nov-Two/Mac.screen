'use strict';

/**
 * 全局静态配置。对应 Mac 版 Sources/MacScreen/AppConfiguration.swift。
 * 所有路径相关的常量集中在此，方便打包后定位资源。
 */

const path = require('path');
const { app } = require('electron');

const APP_NAME = 'WinScreen';
const APP_ID = 'com.novtwo.winscreen';

/** 支持的视频扩展名（Chromium 解码能力内） */
const SUPPORTED_VIDEO_EXTENSIONS = ['mp4', 'mov', 'm4v', 'webm'];
/** 支持的压缩包扩展名（导入时自动解包） */
const SUPPORTED_ARCHIVE_EXTENSIONS = ['zip'];

/** 导入素材的最低分辨率门槛，低于此值直接拒绝 */
const MIN_VIDEO_WIDTH = 1920;
const MIN_VIDEO_HEIGHT = 1080;

/** 缩略图生成时的最大边长 */
const THUMBNAIL_MAX_WIDTH = 480;
/** 缩略图截取的时间点（秒） */
const THUMBNAIL_SEEK_SECONDS = 3;

/** 低电量暂停阈值 */
const LOW_BATTERY_THRESHOLD = 20;
const LOW_BATTERY_INTERVAL = 60 * 1000;

/** 在线素材来源：原项目作者的素材仓库 */
const MATERIALS_REPOSITORY = 'Nov-Two/Mac.screen';
const MATERIALS_BRANCH = 'master';
const MATERIALS_RAW_BASE = `https://raw.githubusercontent.com/${MATERIALS_REPOSITORY}/${MATERIALS_BRANCH}`;
const MATERIALS_PAGE_URL = `https://github.com/${MATERIALS_REPOSITORY}/tree/${MATERIALS_BRANCH}/AuthorVideos`;
const WALLPAPER_WEBSITE_URL = 'https://haowallpaper.com/';

/**
 * 资源根目录。
 *  - 已打包：extraResources 把 videos/ 放到 process.resourcesPath 下
 *  - 未打包：直接指向工程根目录
 */
function resourcesRoot() {
  return app.isPackaged ? process.resourcesPath : path.join(__dirname, '..', '..');
}

function bundledVideoDirectory() {
  return path.join(resourcesRoot(), 'videos');
}

function assetsDirectory() {
  return path.join(__dirname, '..', '..', 'assets');
}

/** 用户导入的素材目录：%APPDATA%/WinScreen/Videos */
function userVideoDirectory() {
  return path.join(app.getPath('userData'), 'Videos');
}

/** 缩略图缓存目录 */
function thumbnailDirectory() {
  return path.join(app.getPath('userData'), 'Thumbnails');
}

/** 元数据缓存文件（时长 / 分辨率 / 体积） */
function metadataCacheFile() {
  return path.join(app.getPath('userData'), 'metadata.json');
}

/** 用户设置文件 */
function settingsFile() {
  return path.join(app.getPath('userData'), 'settings.json');
}

/** 在线素材下载的临时目录 */
function downloadDirectory() {
  return path.join(app.getPath('userData'), 'Downloads');
}

function isSupportedVideo(filePath) {
  const ext = path.extname(filePath).slice(1).toLowerCase();
  return SUPPORTED_VIDEO_EXTENSIONS.includes(ext);
}

function isSupportedArchive(filePath) {
  const ext = path.extname(filePath).slice(1).toLowerCase();
  return SUPPORTED_ARCHIVE_EXTENSIONS.includes(ext);
}

module.exports = {
  APP_NAME,
  APP_ID,
  SUPPORTED_VIDEO_EXTENSIONS,
  SUPPORTED_ARCHIVE_EXTENSIONS,
  MIN_VIDEO_WIDTH,
  MIN_VIDEO_HEIGHT,
  THUMBNAIL_MAX_WIDTH,
  THUMBNAIL_SEEK_SECONDS,
  LOW_BATTERY_THRESHOLD,
  LOW_BATTERY_INTERVAL,
  MATERIALS_REPOSITORY,
  MATERIALS_BRANCH,
  MATERIALS_RAW_BASE,
  MATERIALS_PAGE_URL,
  WALLPAPER_WEBSITE_URL,
  resourcesRoot,
  bundledVideoDirectory,
  assetsDirectory,
  userVideoDirectory,
  thumbnailDirectory,
  metadataCacheFile,
  settingsFile,
  downloadDirectory,
  isSupportedVideo,
  isSupportedArchive,
};
