'use strict';

/**
 * 从 GitHub 重新生成 assets/materials.json（在线素材清单）。
 *
 * 用法：
 *   npm run materials
 *   node scripts/build-materials.js --repo Nov-Two/Mac.screen --dir AuthorVideos
 *
 * 匿名调用 GitHub API 有 60 次/小时限制。失败时不会覆盖已有清单，
 * 保证应用始终有一份可用的离线清单。
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT = path.join(__dirname, '..');
const OUTPUT = path.join(ROOT, 'assets', 'materials.json');

function parseArgs(argv) {
  const args = { repo: 'Nov-Two/Mac.screen', dir: 'AuthorVideos', branch: 'master', token: null };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (key === '--repo') args.repo = argv[++i];
    else if (key === '--dir') args.dir = argv[++i];
    else if (key === '--branch') args.branch = argv[++i];
    else if (key === '--token') args.token = argv[++i];
  }
  args.token = args.token || process.env.GITHUB_TOKEN || null;
  return args;
}

function requestJson(url, token) {
  return new Promise((resolve, reject) => {
    const headers = {
      'User-Agent': 'winscreen-build-script',
      Accept: 'application/vnd.github+json',
    };
    if (token) headers.Authorization = `Bearer ${token}`;

    https
      .get(url, { headers }, (response) => {
        let body = '';
        response.on('data', (chunk) => {
          body += chunk;
        });
        response.on('end', () => {
          if (response.statusCode !== 200) {
            reject(new Error(`HTTP ${response.statusCode}: ${body.slice(0, 200)}`));
            return;
          }
          try {
            resolve(JSON.parse(body));
          } catch (error) {
            reject(error);
          }
        });
      })
      .on('error', reject);
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const url = `https://api.github.com/repos/${args.repo}/contents/${args.dir}?ref=${args.branch}`;

  console.log(`拉取目录：${args.repo}/${args.dir}@${args.branch}`);
  const entries = await requestJson(url, args.token);

  if (!Array.isArray(entries)) {
    throw new Error('接口返回格式异常');
  }

  const items = entries
    .filter((entry) => entry.type === 'file' && /\.(mp4|mov|m4v|webm)$/i.test(entry.name))
    .map((entry) => ({
      name: entry.name,
      folder: args.dir,
      size: entry.size,
      sha: entry.sha,
    }))
    .sort((a, b) => a.name.localeCompare(b.name, 'zh-Hans-CN', { numeric: true }));

  const manifest = {
    generatedAt: new Date().toISOString().replace(/\.\d+Z$/, 'Z'),
    repository: args.repo,
    branch: args.branch,
    sourceDirectory: args.dir,
    note: '素材来自原项目仓库，未随安装包分发，由应用按需下载到用户素材目录。',
    items,
  };

  fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
  fs.writeFileSync(OUTPUT, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');

  const total = items.reduce((sum, item) => sum + item.size, 0);
  console.log(`已写入 ${path.relative(ROOT, OUTPUT)}`);
  console.log(`条目 ${items.length} 个，合计 ${(total / 1048576).toFixed(1)} MB`);
}

main().catch((error) => {
  console.error('生成素材清单失败：', error.message);
  console.error('（未修改已有清单，应用仍可使用上一次的结果）');
  process.exitCode = 1;
});
