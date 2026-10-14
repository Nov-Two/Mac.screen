'use strict';

/**
 * 把在线素材清单里的视频全部下载到 videos/ 目录，用于「内置素材」打包。
 *
 * 用法：
 *   node scripts/fetch-materials.js            下载缺失的文件
 *   node scripts/fetch-materials.js --force    全部重新下载
 *   node scripts/fetch-materials.js --limit 3  只下载前 3 个（快速验证）
 *
 * 注意：全部素材约 460MB，打包进安装包会显著增大体积。
 * 默认分发方式建议使用应用内的「在线素材」按需下载。
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT = path.join(__dirname, '..');
const MANIFEST = path.join(ROOT, 'assets', 'materials.json');
const TARGET_DIR = path.join(ROOT, 'videos');

const RAW_BASE = 'https://raw.githubusercontent.com/Nov-Two/Mac.screen/master';

function parseArgs(argv) {
  const args = { force: false, limit: Infinity };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--force') args.force = true;
    else if (argv[i] === '--limit') args.limit = Number(argv[++i]) || Infinity;
  }
  return args;
}

function download(url, targetPath, onProgress) {
  return new Promise((resolve, reject) => {
    const request = https.get(url, { headers: { 'User-Agent': 'winscreen-build-script' } }, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        resolve(download(response.headers.location, targetPath, onProgress));
        return;
      }
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode}`));
        response.resume();
        return;
      }

      const total = Number(response.headers['content-length']) || 0;
      let received = 0;
      const file = fs.createWriteStream(targetPath);

      response.on('data', (chunk) => {
        received += chunk.length;
        if (onProgress) onProgress(received, total);
      });
      response.pipe(file);
      file.on('finish', () => file.close(() => resolve()));
      file.on('error', reject);
    });
    request.on('error', reject);
  });
}

function human(bytes) {
  return `${(bytes / 1048576).toFixed(1)} MB`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (!fs.existsSync(MANIFEST)) {
    throw new Error('缺少 assets/materials.json，请先执行 npm run materials');
  }
  const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
  fs.mkdirSync(TARGET_DIR, { recursive: true });

  const targets = manifest.items.slice(0, args.limit);
  console.log(`共 ${targets.length} 个素材，目标目录：${path.relative(ROOT, TARGET_DIR)}`);

  let downloaded = 0;
  let skipped = 0;

  for (const item of targets) {
    const targetPath = path.join(TARGET_DIR, item.name);

    if (!args.force && fs.existsSync(targetPath)) {
      const size = fs.statSync(targetPath).size;
      if (size === item.size) {
        skipped += 1;
        console.log(`  跳过（已存在） ${item.name}`);
        continue;
      }
    }

    const url = `${RAW_BASE}/${item.folder}/${encodeURIComponent(item.name)}`;
    process.stdout.write(`  下载 ${item.name} … `);
    try {
      await download(url, targetPath, (received, total) => {
        if (total) {
          process.stdout.write(`\r  下载 ${item.name} … ${Math.round((received / total) * 100)}%   `);
        }
      });
      downloaded += 1;
      process.stdout.write(`\r  完成 ${item.name} (${human(fs.statSync(targetPath).size)})        \n`);
    } catch (error) {
      process.stdout.write(`\r  失败 ${item.name}: ${error.message}\n`);
    }
  }

  console.log(`\n完成：新下载 ${downloaded} 个，跳过 ${skipped} 个。`);
  console.log('这些视频会通过 extraResources 一起打进安装包。');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
