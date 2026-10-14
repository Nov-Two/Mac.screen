'use strict';

/**
 * 生成应用图标与托盘图标。
 *
 * 完全不依赖任何图形库：直接把图标画进 RGBA 缓冲区（4 倍超采样后降采样
 * 得到抗锯齿边缘），再手写 PNG 与 ICO 容器。这样在任何平台、任何
 * Node 版本上都能重建图标，不需要额外安装 sharp / canvas / ImageMagick。
 *
 * 产物：
 *   build/icon.ico      Windows 安装包与可执行文件图标（含 16~256 多尺寸）
 *   build/icon.png      512x512 备用（macOS / Linux 打包用）
 *   assets/tray.png     32x32 托盘图标
 */

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const ROOT = path.join(__dirname, '..');
const BUILD_DIR = path.join(ROOT, 'build');
const ASSETS_DIR = path.join(ROOT, 'assets');

const SUPERSAMPLE = 4;

/* ------------------------------------------------------------------ *
 * 颜色
 * ------------------------------------------------------------------ */

const COLOR_TOP = [0x4f, 0x7d, 0xff];
const COLOR_BOTTOM = [0x8b, 0x5c, 0xf6];
const COLOR_ACCENT = [0x2a, 0xd4, 0xee];
const COLOR_WHITE = [0xff, 0xff, 0xff];

function mix(a, b, t) {
  const k = Math.max(0, Math.min(1, t));
  return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];
}

/* ------------------------------------------------------------------ *
 * 画布
 * ------------------------------------------------------------------ */

class Canvas {
  constructor(size) {
    this.size = size;
    this.data = new Float32Array(size * size * 4);
  }

  /** 标准 over 合成 */
  blend(x, y, color, alpha) {
    if (alpha <= 0 || x < 0 || y < 0 || x >= this.size || y >= this.size) return;
    const index = (y * this.size + x) * 4;
    const dstA = this.data[index + 3];
    const outA = alpha + dstA * (1 - alpha);
    if (outA <= 0) return;
    for (let c = 0; c < 3; c += 1) {
      const src = color[c] * alpha;
      const dst = this.data[index + c] * dstA * (1 - alpha);
      this.data[index + c] = (src + dst) / outA;
    }
    this.data[index + 3] = outA;
  }

  /** 圆角矩形，colorAt(x, y) 返回 [r,g,b] 或 [r,g,b,a] */
  roundRect(x0, y0, x1, y1, radius, colorAt) {
    for (let y = Math.floor(y0); y < Math.ceil(y1); y += 1) {
      for (let x = Math.floor(x0); x < Math.ceil(x1); x += 1) {
        const cx = Math.min(Math.max(x + 0.5, x0 + radius), x1 - radius);
        const cy = Math.min(Math.max(y + 0.5, y0 + radius), y1 - radius);
        const dx = x + 0.5 - cx;
        const dy = y + 0.5 - cy;
        const distance = Math.sqrt(dx * dx + dy * dy);
        // 边缘 1px 过渡，配合超采样得到平滑边界
        let alpha = Math.max(0, Math.min(1, radius + 0.5 - distance));
        if (alpha <= 0) continue;
        const color = colorAt(x + 0.5, y + 0.5);
        if (color.length > 3) alpha *= color[3];
        if (alpha > 0) this.blend(x, y, color, alpha);
      }
    }
  }

  triangle(p0, p1, p2, color) {
    const minX = Math.floor(Math.min(p0[0], p1[0], p2[0]));
    const maxX = Math.ceil(Math.max(p0[0], p1[0], p2[0]));
    const minY = Math.floor(Math.min(p0[1], p1[1], p2[1]));
    const maxY = Math.ceil(Math.max(p0[1], p1[1], p2[1]));

    const edge = (a, b, px, py) => (b[0] - a[0]) * (py - a[1]) - (b[1] - a[1]) * (px - a[0]);
    const area = edge(p0, p1, p2[0], p2[1]);
    if (Math.abs(area) < 1e-6) return;

    for (let y = minY; y <= maxY; y += 1) {
      for (let x = minX; x <= maxX; x += 1) {
        const px = x + 0.5;
        const py = y + 0.5;
        const w0 = edge(p1, p2, px, py) / area;
        const w1 = edge(p2, p0, px, py) / area;
        const w2 = edge(p0, p1, px, py) / area;
        if (w0 >= -0.002 && w1 >= -0.002 && w2 >= -0.002) {
          this.blend(x, y, color, 1);
        }
      }
    }
  }

  /** 降采样到目标尺寸 */
  downsample(factor) {
    const outSize = this.size / factor;
    const out = Buffer.alloc(outSize * outSize * 4);
    for (let y = 0; y < outSize; y += 1) {
      for (let x = 0; x < outSize; x += 1) {
        let r = 0;
        let g = 0;
        let b = 0;
        let a = 0;
        for (let sy = 0; sy < factor; sy += 1) {
          for (let sx = 0; sx < factor; sx += 1) {
            const index = ((y * factor + sy) * this.size + (x * factor + sx)) * 4;
            const alpha = this.data[index + 3];
            r += this.data[index] * alpha;
            g += this.data[index + 1] * alpha;
            b += this.data[index + 2] * alpha;
            a += alpha;
          }
        }
        const count = factor * factor;
        const outIndex = (y * outSize + x) * 4;
        if (a > 0) {
          out[outIndex] = Math.round(Math.max(0, Math.min(255, r / a)));
          out[outIndex + 1] = Math.round(Math.max(0, Math.min(255, g / a)));
          out[outIndex + 2] = Math.round(Math.max(0, Math.min(255, b / a)));
        }
        out[outIndex + 3] = Math.round(Math.max(0, Math.min(255, (a / count) * 255)));
      }
    }
    return { width: outSize, height: outSize, data: out };
  }
}

/* ------------------------------------------------------------------ *
 * 图标绘制
 * ------------------------------------------------------------------ */

/**
 * 画一个「显示器 + 播放键」的图标：
 * 圆角渐变底 + 白色屏幕轮廓 + 屏幕内的播放三角。
 */
function drawIcon(size) {
  const S = size * SUPERSAMPLE;
  const canvas = new Canvas(S);

  const pad = S * 0.085;
  const box = [pad, pad, S - pad, S - pad];
  const radius = S * 0.225;

  // 背景渐变
  canvas.roundRect(box[0], box[1], box[2], box[3], radius, (x, y) => {
    const t = (x / S) * 0.45 + (y / S) * 0.55;
    return mix(COLOR_TOP, COLOR_BOTTOM, t);
  });

  // 右下角一抹青色高光，增加层次
  canvas.roundRect(box[0], box[1], box[2], box[3], radius, (x, y) => {
    const d = Math.hypot(x - S * 0.92, y - S * 0.96) / (S * 0.75);
    const alpha = Math.max(0, 1 - d) ** 2 * 0.5;
    return [...COLOR_ACCENT, alpha];
  });

  // 屏幕外框（白色圆角矩形）
  const screen = [S * 0.235, S * 0.255, S * 0.765, S * 0.63];
  canvas.roundRect(screen[0], screen[1], screen[2], screen[3], S * 0.055, () => COLOR_WHITE);

  // 屏幕内部挖空成底色，形成描边效果
  const inner = [S * 0.283, S * 0.303, S * 0.717, S * 0.582];
  canvas.roundRect(inner[0], inner[1], inner[2], inner[3], S * 0.032, () => [0x11, 0x16, 0x22]);

  // 播放三角
  canvas.triangle(
    [S * 0.432, S * 0.362],
    [S * 0.432, S * 0.524],
    [S * 0.575, S * 0.443],
    COLOR_WHITE
  );

  // 底座支架
  canvas.roundRect(S * 0.44, S * 0.645, S * 0.56, S * 0.7, S * 0.02, () => COLOR_WHITE);
  canvas.roundRect(S * 0.355, S * 0.7, S * 0.645, S * 0.752, S * 0.026, () => COLOR_WHITE);

  return canvas.downsample(SUPERSAMPLE);
}

/* ------------------------------------------------------------------ *
 * PNG 编码（colorType 6 = RGBA，无隔行）
 * ------------------------------------------------------------------ */

function crc32(buffer) {
  let crc = 0xffffffff;
  for (let i = 0; i < buffer.length; i += 1) {
    crc ^= buffer[i];
    for (let bit = 0; bit < 8; bit += 1) {
      crc = crc & 1 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const typeBuffer = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 0);
  return Buffer.concat([length, typeBuffer, data, crc]);
}

function encodePng(image) {
  const { width, height, data } = image;

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type: RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace

  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y += 1) {
    raw[y * (stride + 1)] = 0; // filter type 0
    data.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/* ------------------------------------------------------------------ *
 * ICO 打包（内嵌 PNG，Vista 以后系统都支持）
 * ------------------------------------------------------------------ */

function encodeIco(images) {
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type: icon
  header.writeUInt16LE(images.length, 4);

  const entries = [];
  let offset = 6 + images.length * 16;

  const payloads = images.map(({ size, png }) => {
    const entry = Buffer.alloc(16);
    entry[0] = size >= 256 ? 0 : size;
    entry[1] = size >= 256 ? 0 : size;
    entry[2] = 0; // palette
    entry[3] = 0; // reserved
    entry.writeUInt16LE(1, 4); // color planes
    entry.writeUInt16LE(32, 6); // bits per pixel
    entry.writeUInt32LE(png.length, 8);
    entry.writeUInt32LE(offset, 12);
    offset += png.length;
    entries.push(entry);
    return png;
  });

  return Buffer.concat([header, ...entries, ...payloads]);
}

/* ------------------------------------------------------------------ *
 * 入口
 * ------------------------------------------------------------------ */

function main() {
  fs.mkdirSync(BUILD_DIR, { recursive: true });
  fs.mkdirSync(ASSETS_DIR, { recursive: true });

  const icoSizes = [256, 128, 64, 48, 32, 16];
  const icoImages = icoSizes.map((size) => ({
    size,
    png: encodePng(drawIcon(size)),
  }));

  const icoPath = path.join(BUILD_DIR, 'icon.ico');
  fs.writeFileSync(icoPath, encodeIco(icoImages));

  const pngPath = path.join(BUILD_DIR, 'icon.png');
  fs.writeFileSync(pngPath, encodePng(drawIcon(512)));

  const trayPath = path.join(ASSETS_DIR, 'tray.png');
  fs.writeFileSync(trayPath, encodePng(drawIcon(32)));

  const tray2xPath = path.join(ASSETS_DIR, 'tray@2x.png');
  fs.writeFileSync(tray2xPath, encodePng(drawIcon(64)));

  const report = [
    [icoPath, fs.statSync(icoPath).size],
    [pngPath, fs.statSync(pngPath).size],
    [trayPath, fs.statSync(trayPath).size],
    [tray2xPath, fs.statSync(tray2xPath).size],
  ];
  console.log('图标生成完成：');
  for (const [file, size] of report) {
    console.log(`  ${path.relative(ROOT, file).padEnd(22)} ${(size / 1024).toFixed(1)} KB`);
  }
}

if (require.main === module) {
  main();
}

module.exports = { drawIcon, encodePng, encodeIco };
