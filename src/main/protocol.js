'use strict';

/**
 * 自定义协议 wsmedia://
 *
 * 把「应用页面」和「本地媒体文件」统一收拢到同一个安全来源下，好处有三：
 *  1. 页面与视频同源，canvas 不会被污染，缩略图可以正常导出；
 *  2. 不需要把 webSecurity 关掉（那是常见的安全隐患）；
 *  3. 自己实现 HTTP Range，让几十 MB 的大视频可以边播边下、随意拖动进度。
 *
 * URL 形态：
 *   wsmedia://app/index.html            界面静态文件（src/renderer）
 *   wsmedia://app/@asset/icon.png       资源文件（assets）
 *   wsmedia://app/@media/<编码后的绝对路径>   本地视频 / 缩略图
 *
 * 注意：媒体与界面刻意放在**同一个 host**（app）下，只是路径前缀不同。
 * 因为注册成 standard 协议后，origin = scheme://host，把媒体放到 media host
 * 会让它变成跨域资源，canvas 被污染后 toDataURL() 会直接抛 SecurityError。
 */

const fs = require('fs');
const path = require('path');
const { Readable } = require('stream');
const { protocol } = require('electron');

const SCHEME = 'wsmedia';
const MEDIA_PREFIX = '@media/';
const ASSET_PREFIX = '@asset/';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.htm': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.mp4': 'video/mp4',
  '.m4v': 'video/mp4',
  '.mov': 'video/quicktime',
  '.webm': 'video/webm',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.txt': 'text/plain; charset=utf-8',
  '.md': 'text/markdown; charset=utf-8',
};

function mimeFor(filePath) {
  return MIME_TYPES[path.extname(filePath).toLowerCase()] || 'application/octet-stream';
}

/** 必须在 app ready 之前调用 */
function registerScheme() {
  protocol.registerSchemesAsPrivileged([
    {
      scheme: SCHEME,
      privileges: {
        standard: true,
        secure: true,
        supportFetchAPI: true,
        stream: true,
        bypassCSP: false,
        corsEnabled: true,
      },
    },
  ]);
}

/** 必须在 app ready 之后调用 */
function registerHandler({ rendererDir, assetsDir }) {
  protocol.handle(SCHEME, async (request) => {
    let url;
    try {
      url = new URL(request.url);
    } catch {
      return new Response('bad request', { status: 400 });
    }

    const host = url.hostname;
    let rawPath = url.pathname.replace(/^\//, '');
    try {
      rawPath = decodeURIComponent(rawPath);
    } catch {
      return new Response('bad encoding', { status: 400 });
    }

    let filePath;
    if (host === 'app' && rawPath.startsWith(MEDIA_PREFIX)) {
      // 本地媒体：路径本身就是绝对路径，不再拼接根目录
      filePath = path.normalize(rawPath.slice(MEDIA_PREFIX.length));
    } else if (host === 'app' && rawPath.startsWith(ASSET_PREFIX)) {
      filePath = safeJoin(assetsDir, rawPath.slice(ASSET_PREFIX.length));
    } else if (host === 'app') {
      filePath = safeJoin(rendererDir, rawPath);
    } else if (host === 'asset') {
      // 兼容旧写法
      filePath = safeJoin(assetsDir, rawPath);
    } else if (host === 'media') {
      filePath = path.normalize(rawPath);
    } else {
      return new Response('unknown host', { status: 404 });
    }

    if (!filePath) return new Response('forbidden', { status: 403 });
    return serveFile(filePath, request);
  });
}

/** 阻止 ../ 越界读取 */
function safeJoin(root, relative) {
  const resolved = path.resolve(root, relative);
  const normalizedRoot = path.resolve(root);
  if (resolved !== normalizedRoot && !resolved.startsWith(normalizedRoot + path.sep)) {
    return null;
  }
  return resolved;
}

/**
 * 带 Range 支持的文件响应。
 * 视频播放器会先发 `Range: bytes=0-`，必须回 206 才能自由拖动进度。
 */
async function serveFile(filePath, request) {
  let stat;
  try {
    stat = await fs.promises.stat(filePath);
  } catch {
    return new Response('not found', { status: 404 });
  }
  if (!stat.isFile()) return new Response('not a file', { status: 404 });

  const total = stat.size;
  const contentType = mimeFor(filePath);
  const rangeHeader = request.headers.get('range');

  const baseHeaders = {
    'Content-Type': contentType,
    'Accept-Ranges': 'bytes',
    'Cache-Control': 'no-cache',
  };

  if (request.method === 'HEAD') {
    return new Response(null, {
      status: 200,
      headers: { ...baseHeaders, 'Content-Length': String(total) },
    });
  }

  if (!rangeHeader) {
    const stream = fs.createReadStream(filePath);
    return new Response(Readable.toWeb(stream), {
      status: 200,
      headers: { ...baseHeaders, 'Content-Length': String(total) },
    });
  }

  const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader.trim());
  if (!match) {
    return new Response(null, {
      status: 416,
      headers: { ...baseHeaders, 'Content-Range': `bytes */${total}` },
    });
  }

  let start;
  let end;
  if (match[1] === '' && match[2] !== '') {
    // bytes=-N 表示最后 N 字节
    const suffixLength = Number(match[2]);
    start = Math.max(0, total - suffixLength);
    end = total - 1;
  } else {
    start = Number(match[1] || 0);
    end = match[2] === '' ? total - 1 : Math.min(Number(match[2]), total - 1);
  }

  if (Number.isNaN(start) || Number.isNaN(end) || start > end || start >= total) {
    return new Response(null, {
      status: 416,
      headers: { ...baseHeaders, 'Content-Range': `bytes */${total}` },
    });
  }

  const stream = fs.createReadStream(filePath, { start, end });
  return new Response(Readable.toWeb(stream), {
    status: 206,
    headers: {
      ...baseHeaders,
      'Content-Range': `bytes ${start}-${end}/${total}`,
      'Content-Length': String(end - start + 1),
    },
  });
}

/**
 * 把本地绝对路径转成协议 URL，供渲染进程使用。
 * 与界面同源（wsmedia://app），因此 canvas 可以正常导出缩略图。
 */
function toMediaUrl(filePath) {
  const normalized = path.resolve(filePath).split(path.sep).join('/');
  return `${SCHEME}://app/${MEDIA_PREFIX}${encodeURIComponent(normalized)}`;
}

/** 资源文件（图标等）的协议 URL */
function toAssetUrl(relativePath) {
  const normalized = String(relativePath).split(path.sep).join('/').replace(/^\/+/, '');
  return `${SCHEME}://app/${ASSET_PREFIX}${encodeURIComponent(normalized)}`;
}

module.exports = { SCHEME, registerScheme, registerHandler, toMediaUrl, toAssetUrl, mimeFor };
