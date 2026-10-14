'use strict';

/**
 * 渲染进程主逻辑。
 * 与主进程的所有交互都通过 preload 暴露的 window.winscreen 完成。
 */

const api = window.winscreen;

/* ------------------------------------------------------------------ *
 * 状态
 * ------------------------------------------------------------------ */

const state = {
  items: [],
  selectedPath: null,
  activePath: null,
  isPaused: false,
  volume: 0,
  search: '',
  category: '全部',
  favoritesOnly: false,
  view: 'library',
  settings: {},
  appInfo: null,
  online: null,
  onlineProgress: new Map(),
  enrich: { done: 0, total: 0 },
  contextItem: null,
};

const CATEGORIES = ['全部', '二次元', '风景', '人物', '其他'];

const SETTINGS_SCHEMA = [
  {
    group: '播放',
    desc: '控制动态壁纸在桌面上的呈现方式',
    rows: [
      {
        key: 'videoFit',
        type: 'select',
        title: '画面铺满方式',
        desc: '素材比例与屏幕不一致时的处理方式',
        options: [
          ['cover', '裁剪铺满（推荐）'],
          ['contain', '完整显示（留黑边）'],
          ['fill', '拉伸填满'],
        ],
      },
      {
        key: 'spanAllDisplays',
        type: 'switch',
        title: '铺满所有显示器',
        desc: '开启后一个壁纸横跨全部显示器；关闭时只在主显示器播放',
      },
      {
        key: 'wallpaperVolume',
        type: 'range',
        title: '全局音量',
        desc: '默认静音。调高后托盘与主窗口都会同步',
      },
      {
        key: 'restoresLastWallpaperOnLaunch',
        type: 'switch',
        title: '启动时恢复上次壁纸',
        desc: '默认关闭，避免一开机就自动播放大视频',
      },
      {
        key: 'pausesOnLowBattery',
        type: 'switch',
        title: '低电量时暂停并提醒',
        desc: '使用电池且电量低于 20% 时自动暂停并弹窗询问',
      },
    ],
  },
  {
    group: '素材',
    desc: '导入、清理与素材目录',
    rows: [
      {
        key: 'skipResolutionCheck',
        type: 'switch',
        title: '跳过分辨率校验',
        desc: '默认只接受 1920x1080 及以上的视频；开启后任何分辨率都能导入',
      },
      {
        key: 'cleansDownloadedResourcesAfterImport',
        type: 'switch',
        title: '导入后清理下载源文件',
        desc: '在线素材下载完成并导入后，删除临时下载文件',
      },
    ],
  },
  {
    group: '外观与启动',
    desc: '界面与系统集成',
    rows: [
      {
        key: 'theme',
        type: 'select',
        title: '界面主题',
        desc: '深色更适合浏览视频素材',
        options: [
          ['dark', '深色'],
          ['light', '浅色'],
        ],
      },
      {
        key: 'enableCardHoverEffect',
        type: 'switch',
        title: '卡片 3D 悬停动效',
        desc: '鼠标划过素材卡片时的立体跟随效果，卡顿时可以关掉',
      },
      {
        key: 'opensAtLogin',
        type: 'switch',
        title: '开机自动启动',
        desc: '开机后静默驻留托盘（便携版不支持，需使用安装版）',
      },
      {
        key: 'closeToTray',
        type: 'switch',
        title: '关闭窗口时最小化到托盘',
        desc: '关闭后应用继续在托盘运行，通过托盘菜单退出',
      },
    ],
  },
];

/* ------------------------------------------------------------------ *
 * DOM
 * ------------------------------------------------------------------ */

const $ = (id) => document.getElementById(id);

const els = {
  grid: $('grid'),
  chips: $('chips'),
  search: $('search'),
  emptyLibrary: $('empty-library'),
  navCountLibrary: $('nav-count-library'),
  statusDot: $('status-dot'),
  statusText: $('status-text'),
  statusMeta: $('status-meta'),
  statusHint: $('status-hint'),
  detail: $('detail'),
  detailEmpty: $('detail-empty'),
  detailBody: $('detail-body'),
  detailVideo: $('detail-video'),
  detailBadge: $('detail-badge'),
  detailTitle: $('detail-title'),
  detailTags: $('detail-tags'),
  detailMeta: $('detail-meta'),
  btnApply: $('btn-apply'),
  btnFavorite: $('btn-favorite'),
  btnReveal: $('btn-reveal'),
  btnDelete: $('btn-delete'),
  playerTitle: $('player-title'),
  btnPrevState: $('btn-prev-state'),
  iconPlayPause: $('icon-playpause'),
  btnNext: $('btn-next'),
  btnStop: $('btn-stop'),
  btnMute: $('btn-mute'),
  iconVolume: $('icon-volume'),
  volume: $('volume'),
  volumeValue: $('volume-value'),
  toasts: $('toasts'),
  contextMenu: $('context-menu'),
  dropOverlay: $('drop-overlay'),
  settings: $('settings'),
  onlineList: $('online-list'),
  emptyOnline: $('empty-online'),
  onlineSubtitle: $('online-subtitle'),
};

/* ------------------------------------------------------------------ *
 * 工具
 * ------------------------------------------------------------------ */

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])
  );
}

function toast(type, message) {
  const node = document.createElement('div');
  node.className = `toast is-${type || 'info'}`;
  node.textContent = message;
  els.toasts.appendChild(node);
  setTimeout(() => {
    node.style.transition = 'opacity .25s, transform .25s';
    node.style.opacity = '0';
    node.style.transform = 'translateY(6px)';
    setTimeout(() => node.remove(), 260);
  }, 4200);
}

const PLAY_ICON = '<path d="M5 3.5l8 4.5-8 4.5z" />';
const PAUSE_ICON = '<path d="M6 3.5v9M10 3.5v9" />';
const VOLUME_ICONS = {
  muted: '<path d="M3 6h2.4L8.5 3.4v9.2L5.4 10H3z" /><path d="M11 6.5l3 3M14 6.5l-3 3" />',
  low: '<path d="M3 6h2.4L8.5 3.4v9.2L5.4 10H3z" /><path d="M11 6.2a2.6 2.6 0 010 3.6" />',
  high: '<path d="M3 6h2.4L8.5 3.4v9.2L5.4 10H3z" /><path d="M11 6.2a2.6 2.6 0 010 3.6" /><path d="M12.9 4.4a5 5 0 010 7.2" />',
};

/* ------------------------------------------------------------------ *
 * 过滤与渲染：素材墙
 * ------------------------------------------------------------------ */

function visibleItems() {
  const keyword = state.search.trim().toLowerCase();
  return state.items.filter((item) => {
    if (state.favoritesOnly && !item.isFavorite) return false;
    if (state.category !== '全部' && item.category !== state.category) return false;
    if (!keyword) return true;
    const haystack = `${item.title} ${item.tags.join(' ')} ${item.fileName}`.toLowerCase();
    return haystack.includes(keyword);
  });
}

function renderChips() {
  const counts = state.items.reduce((acc, item) => {
    acc[item.category] = (acc[item.category] || 0) + 1;
    return acc;
  }, {});
  const favoriteCount = state.items.filter((item) => item.isFavorite).length;

  const chips = [
    ...CATEGORIES.map((name) => ({
      name,
      label: name === '全部' ? `全部 ${state.items.length}` : `${name} ${counts[name] || 0}`,
      active: !state.favoritesOnly && state.category === name,
      onClick: () => {
        state.category = name;
        state.favoritesOnly = false;
        renderChips();
        renderGrid();
      },
    })),
    {
      name: '__fav__',
      label: `★ 收藏 ${favoriteCount}`,
      active: state.favoritesOnly,
      onClick: () => {
        state.favoritesOnly = !state.favoritesOnly;
        renderChips();
        renderGrid();
      },
    },
  ];

  els.chips.innerHTML = chips
    .map((chip) => `<button class="chip${chip.active ? ' is-active' : ''}">${esc(chip.label)}</button>`)
    .join('');
  [...els.chips.children].forEach((node, index) => {
    node.addEventListener('click', chips[index].onClick);
  });
}

function renderGrid() {
  const items = visibleItems();
  els.navCountLibrary.textContent = String(state.items.length);

  if (state.items.length === 0) {
    els.grid.innerHTML = '';
    els.emptyLibrary.hidden = false;
    return;
  }
  els.emptyLibrary.hidden = true;

  if (items.length === 0) {
    els.grid.innerHTML = `<div class="empty" style="grid-column:1/-1"><h3>没有匹配的素材</h3><p>换个关键词或分类试试。</p></div>`;
    return;
  }

  els.grid.innerHTML = items.map(cardTemplate).join('');

  els.grid.querySelectorAll('.card').forEach((card) => {
    const path = card.dataset.path;
    const item = state.items.find((i) => i.path === path);
    if (!item) return;

    card.addEventListener('click', (event) => {
      if (event.target.closest('.card-apply') || event.target.closest('.card-favorite')) return;
      selectItem(item);
    });
    card.addEventListener('dblclick', () => applyItem(item));
    card.addEventListener('contextmenu', (event) => {
      event.preventDefault();
      selectItem(item);
      openContextMenu(event.clientX, event.clientY, item);
    });

    const applyBtn = card.querySelector('.card-apply');
    if (applyBtn) {
      applyBtn.addEventListener('click', (event) => {
        event.stopPropagation();
        applyItem(item);
      });
    }

    const favBtn = card.querySelector('.card-favorite');
    if (favBtn) {
      favBtn.addEventListener('click', async (event) => {
        event.stopPropagation();
        const result = await api.library.toggleFavorite(item.path);
        item.isFavorite = result.isFavorite;
        favBtn.classList.toggle('is-on', result.isFavorite);
        renderChips();
        if (state.favoritesOnly) renderGrid();
        if (state.selectedPath === item.path) renderDetail();
      });
    }

    if (state.settings.enableCardHoverEffect) bindCardTilt(card);
  });
}

function cardTemplate(item) {
  const isActive = state.activePath === item.path;
  const isSelected = state.selectedPath === item.path;
  const media = item.thumbnailUrl
    ? `<img src="${esc(item.thumbnailUrl)}" alt="" loading="lazy" draggable="false" />`
    : `<div class="placeholder"><svg viewBox="0 0 24 24"><rect x="2.5" y="5" width="19" height="13" rx="2" /><path d="M10 9.5l5 2.5-5 2.5z" /></svg><span>生成缩略图中…</span></div>`;

  return `
    <article class="card${isSelected ? ' is-selected' : ''}${isActive ? ' is-active' : ''}${item.needsProbe ? ' is-probing' : ''}" data-path="${esc(item.path)}">
      <div class="card-media">
        ${media}
        <div class="card-scrim"></div>
        <div class="card-badges">
          <span class="badge badge-accent">${esc(item.category)}</span>
          <span class="badge">${esc(item.resolutionText)}</span>
          <span class="badge">${esc(item.durationText)}</span>
          ${isActive ? '<span class="badge badge-success">桌面上</span>' : ''}
        </div>
        <button class="card-favorite${item.isFavorite ? ' is-on' : ''}" title="收藏">
          <svg viewBox="0 0 16 16"><path d="M8 2.6l1.7 3.5 3.8.5-2.8 2.7.7 3.8L8 11.3 4.6 13.1l.7-3.8L2.5 6.6l3.8-.5z" /></svg>
        </button>
        <button class="card-apply">应用</button>
      </div>
      <div class="card-info">
        <div class="card-title" title="${esc(item.fileName)}">${esc(item.title)}</div>
        <div class="card-sub">
          <span>${esc(item.sizeText)}</span>
          <span>${item.kind === 'user' ? '自定义' : '内置'}</span>
        </div>
      </div>
    </article>
  `;
}

/* ------------------------------------------------------------------ *
 * 卡片 3D 悬停
 * ------------------------------------------------------------------ */

function bindCardTilt(card) {
  const MAX_TILT = 7.5;
  const DEAD_ZONE = 0.16;

  const onMove = (event) => {
    const rect = card.getBoundingClientRect();
    const px = (event.clientX - rect.left) / rect.width - 0.5;
    const py = (event.clientY - rect.top) / rect.height - 0.5;
    const dx = Math.abs(px) < DEAD_ZONE ? 0 : px;
    const dy = Math.abs(py) < DEAD_ZONE ? 0 : py;
    card.style.transform = `rotateY(${dx * MAX_TILT * 2}deg) rotateX(${-dy * MAX_TILT * 2}deg) translateY(-4px) scale(1.022)`;
  };

  const onLeave = () => {
    card.style.transform = '';
  };

  card.addEventListener('mousemove', onMove);
  card.addEventListener('mouseleave', onLeave);
}

/* ------------------------------------------------------------------ *
 * 详情面板
 * ------------------------------------------------------------------ */

function selectItem(item) {
  state.selectedPath = item.path;
  api.ui.setSelection(item.path);

  els.grid.querySelectorAll('.card').forEach((card) => {
    card.classList.toggle('is-selected', card.dataset.path === item.path);
  });

  renderDetail();
  playDetailPreview(item);
}

function currentItem() {
  return state.items.find((item) => item.path === state.selectedPath) || null;
}

function renderDetail() {
  const item = currentItem();
  if (!item) {
    els.detailEmpty.hidden = false;
    els.detailBody.hidden = true;
    return;
  }

  els.detailEmpty.hidden = true;
  els.detailBody.hidden = false;

  els.detailTitle.textContent = item.title;
  els.detailBadge.textContent = state.activePath === item.path ? '桌面上播放中' : '预览';

  // 分类名可能同时出现在标签里（例如「二次元」），去重后再展示
  const tagSet = [item.category, ...item.tags].filter(
    (tag, index, list) => tag && list.indexOf(tag) === index
  );
  els.detailTags.innerHTML = tagSet
    .slice(0, 8)
    .map((tag) => `<span class="tag">${esc(tag)}</span>`)
    .join('');

  const rows = [
    ['分辨率', item.resolutionText],
    ['时长', item.durationText],
    ['体积', item.sizeText],
    ['来源', item.kind === 'user' ? '自定义素材' : '内置素材'],
    ['收藏', item.isFavorite ? '已收藏' : '未收藏'],
  ];
  els.detailMeta.innerHTML = rows
    .map(([key, value]) => `<dt>${esc(key)}</dt><dd>${esc(value)}</dd>`)
    .join('');

  els.btnFavorite.textContent = item.isFavorite ? '取消收藏' : '收藏';
  els.btnFavorite.classList.toggle('is-on', item.isFavorite);
  els.btnDelete.textContent = item.kind === 'user' ? '删除素材' : '从列表移除';
}

function playDetailPreview(item) {
  const video = els.detailVideo;
  if (video.dataset.path !== item.path) {
    video.dataset.path = item.path;
    video.src = item.videoUrl;
  }
  video.volume = 0;
  video.play().catch(() => {
    /* 预览自动播放被拦截时忽略 */
  });
}

/* ------------------------------------------------------------------ *
 * 应用 / 删除
 * ------------------------------------------------------------------ */

async function applyItem(item) {
  const result = await api.wallpaper.apply(item.path);
  if (result.ok) {
    state.activePath = item.path;
    state.isPaused = false;
  }
  renderGrid();
  renderDetail();
}

async function deleteItem(item) {
  const label = item.kind === 'user' ? '删除' : '从列表移除';
  if (!window.confirm(`确定要${label}「${item.title}」吗？`)) return;

  await api.library.remove([item.path]);
  if (state.selectedPath === item.path) {
    state.selectedPath = null;
    els.detailVideo.removeAttribute('src');
    els.detailVideo.load();
  }
  await reloadLibrary();
}

/* ------------------------------------------------------------------ *
 * 右键菜单
 * ------------------------------------------------------------------ */

function openContextMenu(x, y, item) {
  const isActive = state.activePath === item.path;
  const entries = [
    { label: '应用到桌面', onClick: () => applyItem(item) },
    { label: state.isPaused ? '继续播放' : '暂停播放', disabled: !isActive, onClick: () => api.wallpaper.toggle() },
    { label: '停止播放', disabled: !state.activePath, onClick: () => api.wallpaper.stop() },
    { separator: true },
    {
      label: item.isFavorite ? '取消收藏' : '收藏',
      onClick: async () => {
        await api.library.toggleFavorite(item.path);
        await reloadLibrary();
      },
    },
    { label: '在文件夹中显示', onClick: () => api.library.reveal(item.path) },
    { separator: true },
    {
      label: item.kind === 'user' ? '删除素材' : '从列表移除',
      danger: true,
      onClick: () => deleteItem(item),
    },
  ];

  els.contextMenu.innerHTML = entries
    .map((entry) =>
      entry.separator
        ? '<hr />'
        : `<button class="${entry.danger ? 'is-danger' : ''}" ${entry.disabled ? 'disabled' : ''}>${esc(entry.label)}</button>`
    )
    .join('');

  const clickable = entries.filter((entry) => !entry.separator);
  [...els.contextMenu.querySelectorAll('button')].forEach((node, index) => {
    node.addEventListener('click', () => {
      closeContextMenu();
      clickable[index].onClick();
    });
  });

  els.contextMenu.hidden = false;
  const rect = els.contextMenu.getBoundingClientRect();
  els.contextMenu.style.left = `${Math.min(x, window.innerWidth - rect.width - 8)}px`;
  els.contextMenu.style.top = `${Math.min(y, window.innerHeight - rect.height - 8)}px`;
}

function closeContextMenu() {
  els.contextMenu.hidden = true;
}

/* ------------------------------------------------------------------ *
 * 播放条与状态
 * ------------------------------------------------------------------ */

function renderPlayer() {
  const hasActive = Boolean(state.activePath);
  const active = state.items.find((item) => item.path === state.activePath);

  els.playerTitle.textContent = hasActive ? active?.title || '未知素材' : '未播放';
  els.btnPrevState.disabled = !hasActive;
  els.btnNext.disabled = state.items.length === 0;
  els.btnStop.disabled = !hasActive;

  els.iconPlayPause.innerHTML = state.isPaused ? PLAY_ICON : PAUSE_ICON;

  const percent = Math.round(state.volume * 100);
  els.volume.value = String(percent);
  els.volumeValue.textContent = `${percent}%`;
  els.iconVolume.innerHTML =
    state.volume === 0 ? VOLUME_ICONS.muted : state.volume < 0.5 ? VOLUME_ICONS.low : VOLUME_ICONS.high;

  // 侧边栏状态
  els.statusDot.className = 'status-dot';
  if (hasActive && !state.isPaused) {
    els.statusDot.classList.add('is-playing');
    els.statusText.textContent = '播放中';
  } else if (hasActive && state.isPaused) {
    els.statusDot.classList.add('is-paused');
    els.statusText.textContent = '已暂停';
  } else {
    els.statusText.textContent = '空闲';
  }
  els.statusMeta.textContent = hasActive ? active?.title || '未知素材' : '尚未应用动态壁纸';

  const capability = state.appInfo?.capabilities;
  if (state.appInfo && state.appInfo.platform === 'win32' && capability && !capability.desktopLayer.available) {
    els.statusHint.textContent = '桌面层接口不可用，壁纸将退化为置底窗口。';
  } else if (state.appInfo && state.appInfo.platform !== 'win32') {
    els.statusHint.textContent = '当前为开发预览模式（非 Windows），壁纸以全屏窗口呈现。';
  } else {
    els.statusHint.textContent = '';
  }
}

/* ------------------------------------------------------------------ *
 * 设置页
 * ------------------------------------------------------------------ */

function renderSettings() {
  const groups = SETTINGS_SCHEMA.map((group) => {
    const rows = group.rows
      .map((row) => {
        const value = state.settings[row.key];
        let control = '';
        if (row.type === 'switch') {
          control = `<button class="switch${value ? ' is-on' : ''}" data-key="${esc(row.key)}" data-type="switch" aria-pressed="${value ? 'true' : 'false'}"></button>`;
        } else if (row.type === 'select') {
          control = `<select data-key="${esc(row.key)}" data-type="select">${row.options
            .map(
              ([val, label]) =>
                `<option value="${esc(val)}"${String(value) === val ? ' selected' : ''}>${esc(label)}</option>`
            )
            .join('')}</select>`;
        } else if (row.type === 'range') {
          control = `<input type="range" min="0" max="100" value="${Math.round((value || 0) * 100)}" data-key="${esc(row.key)}" data-type="range" style="width:160px" />`;
        }
        return `
          <div class="setting-row">
            <div class="setting-row-main">
              <div class="setting-row-title">${esc(row.title)}</div>
              ${row.desc ? `<div class="setting-row-desc">${esc(row.desc)}</div>` : ''}
            </div>
            ${control}
          </div>`;
      })
      .join('');
    return `<section class="setting-group"><h3>${esc(group.group)}</h3><p>${esc(group.desc)}</p>${rows}</section>`;
  });

  const dirs = state.appInfo?.directories || {};
  groups.push(`
    <section class="setting-group">
      <h3>目录</h3>
      <p>素材与数据的存放位置</p>
      <div class="setting-row">
        <div class="setting-row-main">
          <div class="setting-row-title">我的素材目录</div>
          <div class="setting-row-desc"><code>${esc(dirs.user || '')}</code></div>
        </div>
        <button class="btn btn-ghost" data-action="open-user">打开</button>
      </div>
      <div class="setting-row">
        <div class="setting-row-main">
          <div class="setting-row-title">内置素材目录</div>
          <div class="setting-row-desc"><code>${esc(dirs.bundled || '')}</code></div>
        </div>
        <button class="btn btn-ghost" data-action="open-bundled">打开</button>
      </div>
      <div class="setting-row">
        <div class="setting-row-main">
          <div class="setting-row-title">恢复内置素材</div>
          <div class="setting-row-desc">把之前从列表中移除的内置素材重新显示出来</div>
        </div>
        <button class="btn btn-ghost" data-action="restore-bundled">恢复</button>
      </div>
    </section>
  `);

  groups.push(`
    <section class="setting-group">
      <h3>关于</h3>
      <p>${esc(state.appInfo?.name || 'WinScreen')} ${esc(state.appInfo?.version || '')} · Electron ${esc(
        state.appInfo?.electron || ''
      )} · Chromium ${esc(state.appInfo?.chrome || '')}</p>
      <div class="setting-row">
        <div class="setting-row-main">
          <div class="setting-row-title">检查更新</div>
          <div class="setting-row-desc">${
            state.appInfo?.isPackaged ? '从配置的发布地址检查新版本' : '开发模式下不检查更新'
          }</div>
        </div>
        <button class="btn btn-ghost" data-action="check-update">检查更新</button>
      </div>
      <div class="setting-row">
        <div class="setting-row-main">
          <div class="setting-row-title">项目来源</div>
          <div class="setting-row-desc">设计参考 MacScreen（SwiftUI 版），本项目为 Electron 跨平台重写</div>
        </div>
        <button class="btn btn-ghost" data-action="open-repo">打开仓库</button>
      </div>
    </section>
  `);

  els.settings.innerHTML = groups.join('');
  bindSettingsControls();
}

function bindSettingsControls() {
  els.settings.querySelectorAll('.switch[data-key]').forEach((node) => {
    node.addEventListener('click', async () => {
      const key = node.dataset.key;
      const result = await api.settings.toggle(key);
      if (!result.ok) {
        toast('error', result.message || '设置失败');
        return;
      }
      state.settings[key] = result.value;
      node.classList.toggle('is-on', Boolean(result.value));
      afterSettingChange(key, result.value);
    });
  });

  els.settings.querySelectorAll('select[data-key]').forEach((node) => {
    node.addEventListener('change', async () => {
      const key = node.dataset.key;
      const value = node.value;
      await api.settings.set(key, value);
      state.settings[key] = value;
      afterSettingChange(key, value);
    });
  });

  els.settings.querySelectorAll('input[type=range][data-key]').forEach((node) => {
    node.addEventListener('input', () => {
      const key = node.dataset.key;
      const value = Number(node.value) / 100;
      state.settings[key] = value;
      api.settings.set(key, value);
      if (key === 'wallpaperVolume') {
        state.volume = value;
        renderPlayer();
      }
    });
  });

  const actions = {
    'open-user': () => api.library.openFolder('user'),
    'open-bundled': () => api.library.openFolder('bundled'),
    'restore-bundled': async () => {
      await api.library.restoreBundled();
      await reloadLibrary();
    },
    'check-update': async () => {
      const result = await api.updater.check();
      if (!result.ok) toast('info', result.message || '暂时无法检查更新。');
      else toast('success', '已开始检查更新。');
    },
    'open-repo': () => api.app.openExternal('https://github.com/Nov-Two/Mac.screen'),
  };

  els.settings.querySelectorAll('button[data-action]').forEach((node) => {
    const handler = actions[node.dataset.action];
    if (handler) node.addEventListener('click', handler);
  });
}

function afterSettingChange(key, value) {
  if (key === 'theme') {
    document.documentElement.dataset.theme = value;
  }
  if (key === 'enableCardHoverEffect') {
    renderGrid();
  }
  if (key === 'wallpaperVolume') {
    state.volume = value;
    renderPlayer();
  }
}

/* ------------------------------------------------------------------ *
 * 在线素材
 * ------------------------------------------------------------------ */

async function loadOnline({ refresh = false } = {}) {
  els.onlineList.innerHTML = '<div class="empty"><p>正在读取素材清单…</p></div>';
  state.online = await api.online.list({ refresh });
  renderOnline();
}

function renderOnline() {
  const data = state.online;
  if (!data || !data.ok || data.items.length === 0) {
    els.onlineList.innerHTML = '';
    els.emptyOnline.hidden = false;
    return;
  }
  els.emptyOnline.hidden = true;

  const totalMb = (data.totalSize / 1048576).toFixed(0);
  els.onlineSubtitle.textContent = `${data.items.length} 个素材 · 共约 ${totalMb} MB · 下载后自动导入本地素材库${
    data.remoteError ? `（在线目录刷新失败：${data.remoteError}，显示本地清单）` : ''
  }`;

  els.onlineList.innerHTML = data.items
    .map((item) => {
      const progress = state.onlineProgress.get(item.name);
      const stateText =
        progress?.state === 'downloading'
          ? `下载中 ${formatPercent(progress.received, progress.total)}`
          : progress?.state === 'writing'
            ? '正在写入…'
            : progress?.state === 'done'
              ? '已导入'
              : progress?.state === 'error'
                ? `失败：${esc(progress.message || '')}`
                : item.sizeText;

      const bar =
        progress && progress.state === 'downloading'
          ? `<div class="online-progress"><i style="width:${progressPercent(progress)}%"></i></div>`
          : '';

      return `
        <div class="online-row" data-name="${esc(item.name)}">
          <div class="online-row-main">
            <div class="online-row-title">${esc(item.title)}</div>
            <div class="online-row-sub">${esc(stateText)}</div>
            ${bar}
          </div>
          <button class="btn btn-ghost" data-download="${esc(item.name)}">下载</button>
        </div>`;
    })
    .join('');

  els.onlineList.querySelectorAll('button[data-download]').forEach((node) => {
    node.addEventListener('click', async () => {
      const item = data.items.find((entry) => entry.name === node.dataset.download);
      if (!item) return;
      node.disabled = true;
      node.textContent = '下载中';
      state.onlineProgress.set(item.name, { state: 'downloading', received: 0, total: item.size });
      renderOnline();
      const result = await api.online.download({
        name: item.name,
        rawUrl: item.rawUrl,
        size: item.size,
      });
      if (!result.ok) {
        state.onlineProgress.set(item.name, { state: 'error', message: result.message || result.reason });
      } else {
        state.onlineProgress.set(item.name, { state: 'done' });
        await reloadLibrary();
      }
      renderOnline();
    });
  });
}

function progressPercent(progress) {
  if (!progress.total) return 8;
  return Math.min(100, Math.round((progress.received / progress.total) * 100));
}

function formatPercent(received, total) {
  if (!total) return `${(received / 1048576).toFixed(1)} MB`;
  return `${Math.round((received / total) * 100)}%（${(received / 1048576).toFixed(1)}/${(total / 1048576).toFixed(1)} MB）`;
}

/* ------------------------------------------------------------------ *
 * 数据加载
 * ------------------------------------------------------------------ */

async function reloadLibrary() {
  const { items } = await api.library.list();
  const previousSelection = state.selectedPath;
  state.items = items;

  if (previousSelection && !items.some((item) => item.path === previousSelection)) {
    state.selectedPath = null;
  }
  if (!state.selectedPath && items.length > 0) {
    state.selectedPath = items[0].path;
  }

  renderChips();
  renderGrid();
  renderDetail();
  renderPlayer();

  if (state.selectedPath) {
    const item = currentItem();
    if (item) playDetailPreview(item);
  }
}

/* ------------------------------------------------------------------ *
 * 事件绑定
 * ------------------------------------------------------------------ */

function bindUi() {
  // 窗口控制
  $('btn-minimize').addEventListener('click', () => api.window.minimize());
  $('btn-maximize').addEventListener('click', () => api.window.toggleMaximize());
  $('btn-close').addEventListener('click', () => api.window.close());

  // 导航
  document.querySelectorAll('.nav-item').forEach((node) => {
    node.addEventListener('click', () => {
      document.querySelectorAll('.nav-item').forEach((n) => n.classList.remove('is-active'));
      node.classList.add('is-active');
      const view = node.dataset.view;
      state.view = view;
      document.querySelectorAll('.view').forEach((section) => {
        section.classList.toggle('is-active', section.id === `view-${view}`);
      });
      if (view === 'online' && !state.online) loadOnline();
      if (view === 'settings') renderSettings();
    });
  });

  // 搜索
  let searchTimer = null;
  els.search.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      state.search = els.search.value;
      renderGrid();
    }, 120);
  });

  // 工具栏
  $('btn-refresh').addEventListener('click', async () => {
    await api.library.list();
    await reloadLibrary();
    toast('info', '已重新扫描素材目录。');
  });

  $('btn-add').addEventListener('click', doImport);
  $('btn-online-refresh').addEventListener('click', () => loadOnline({ refresh: true }));
  $('btn-online-page').addEventListener('click', () => api.online.openPage());

  document.querySelectorAll('[data-action="add"]').forEach((node) => node.addEventListener('click', doImport));
  document.querySelectorAll('[data-action="goto-online"]').forEach((node) =>
    node.addEventListener('click', () => document.querySelector('.nav-item[data-view="online"]').click())
  );

  // 播放条
  els.btnPrevState.addEventListener('click', () => api.wallpaper.toggle());
  els.btnNext.addEventListener('click', async () => {
    const result = await api.wallpaper.next();
    if (result.ok) {
      state.activePath = result.path || state.activePath;
      renderGrid();
    }
  });
  els.btnStop.addEventListener('click', () => api.wallpaper.stop());
  els.volume.addEventListener('input', () => {
    const value = Number(els.volume.value) / 100;
    state.volume = value;
    renderPlayer();
    api.wallpaper.setVolume(value);
  });
  els.btnMute.addEventListener('click', () => {
    const next = state.volume > 0 ? 0 : 0.6;
    state.volume = next;
    api.wallpaper.setVolume(next);
    renderPlayer();
  });

  // 详情面板
  els.btnApply.addEventListener('click', () => {
    const item = currentItem();
    if (item) applyItem(item);
  });
  els.btnFavorite.addEventListener('click', async () => {
    const item = currentItem();
    if (!item) return;
    const result = await api.library.toggleFavorite(item.path);
    item.isFavorite = result.isFavorite;
    renderDetail();
    renderGrid();
    renderChips();
  });
  els.btnReveal.addEventListener('click', () => {
    const item = currentItem();
    if (item) api.library.reveal(item.path);
  });
  els.btnDelete.addEventListener('click', () => {
    const item = currentItem();
    if (item) deleteItem(item);
  });

  // 全局点击关闭右键菜单
  document.addEventListener('click', closeContextMenu);
  document.addEventListener('contextmenu', (event) => {
    if (!event.target.closest('.card')) closeContextMenu();
  });
  window.addEventListener('blur', closeContextMenu);

  // 拖拽导入（只接管真正的文件拖拽，拖选文字之类不触发）
  let dragDepth = 0;
  const isFileDrag = (event) =>
    Boolean(event.dataTransfer && Array.from(event.dataTransfer.types || []).includes('Files'));

  window.addEventListener('dragenter', (event) => {
    if (!isFileDrag(event)) return;
    event.preventDefault();
    dragDepth += 1;
    els.dropOverlay.hidden = false;
  });
  window.addEventListener('dragover', (event) => {
    if (isFileDrag(event)) event.preventDefault();
  });
  window.addEventListener('dragleave', (event) => {
    event.preventDefault();
    dragDepth = Math.max(0, dragDepth - 1);
    if (dragDepth === 0) els.dropOverlay.hidden = true;
  });
  window.addEventListener('dragend', () => {
    dragDepth = 0;
    els.dropOverlay.hidden = true;
  });
  window.addEventListener('drop', async (event) => {
    event.preventDefault();
    dragDepth = 0;
    els.dropOverlay.hidden = true;

    const files = [...(event.dataTransfer?.files || [])];
    const paths = files.map((file) => api.pathForFile(file)).filter(Boolean);
    if (paths.length === 0) {
      toast('warning', '没有识别到文件路径，请改用「添加视频」按钮。');
      return;
    }
    const result = await api.library.importPaths(paths);
    if (!result.canceled) await reloadLibrary();
  });
}

async function doImport() {
  const result = await api.library.import();
  if (!result.canceled) await reloadLibrary();
}

/* ------------------------------------------------------------------ *
 * 主进程事件
 * ------------------------------------------------------------------ */

function bindEvents() {
  api.on('wallpaper:state', (payload) => {
    state.activePath = payload.activePath;
    state.isPaused = payload.isPaused;
    if (typeof payload.volume === 'number') state.volume = payload.volume;
    renderPlayer();
    renderGrid();
    renderDetail();
  });

  api.on('library:enrich:item', (payload) => {
    const item = state.items.find((entry) => entry.path === payload.path);
    if (!item) return;
    item.needsProbe = false;
    if (payload.ok) {
      item.thumbnailUrl = payload.thumbnailUrl;
      item.thumbnailPath = payload.thumbnailPath;
      item.width = payload.width;
      item.height = payload.height;
      item.duration = payload.duration;
      item.durationText = payload.durationText;
      item.resolutionText = payload.resolutionText;
    }
    updateCardInPlace(item);
    if (state.selectedPath === item.path) renderDetail();
  });

  api.on('library:changed', () => {
    reloadLibrary();
  });

  api.on('online:progress', (payload) => {
    state.onlineProgress.set(payload.name, payload);
    if (state.view === 'online') renderOnline();
  });

  api.on('toast', (payload) => toast(payload.type, payload.message));

  api.on('updater:status', (payload) => {
    const messages = {
      checking: '正在检查更新…',
      latest: '当前已是最新版本。',
      available: `发现新版本 ${payload.version}，正在下载…`,
      downloaded: `新版本 ${payload.version} 已下载完成，退出应用后自动安装。`,
      error: `更新失败：${payload.message}`,
    };
    if (messages[payload.state]) toast(payload.state === 'error' ? 'error' : 'info', messages[payload.state]);
  });

  api.on('power:lowBattery', (payload) => {
    if (payload.action === 'paused') toast('warning', '电量偏低，动态壁纸已暂停。');
  });
}

function updateCardInPlace(item) {
  const card = els.grid.querySelector(`.card[data-path="${CSS.escape(item.path)}"]`);
  if (!card) return;
  card.classList.remove('is-probing');

  const media = card.querySelector('.card-media');
  if (!media) return;
  const placeholder = media.querySelector('.placeholder');
  if (placeholder && item.thumbnailUrl) {
    placeholder.outerHTML = `<img src="${esc(item.thumbnailUrl)}" alt="" loading="lazy" draggable="false" />`;
  }
  const badges = card.querySelectorAll('.card-badges .badge');
  if (badges[1]) badges[1].textContent = item.resolutionText;
  if (badges[2]) badges[2].textContent = item.durationText;
}

/* ------------------------------------------------------------------ *
 * 启动
 * ------------------------------------------------------------------ */

async function boot() {
  state.appInfo = await api.app.info();
  state.settings = await api.settings.all();
  state.volume = Number(state.settings.wallpaperVolume) || 0;

  document.documentElement.dataset.theme = state.settings.theme || 'dark';

  bindUi();
  bindEvents();

  const wallpaperState = await api.wallpaper.state();
  state.activePath = wallpaperState.activePath;
  state.isPaused = wallpaperState.isPaused;
  state.volume = wallpaperState.volume;

  await reloadLibrary();
  renderPlayer();
  renderSettings();

  // 让托盘知道当前选中项
  const selected = currentItem();
  if (selected) api.ui.setSelection(selected.path);
}

boot().catch((error) => {
  console.error('界面初始化失败:', error);
  toast('error', `界面初始化失败：${error.message}`);
});
