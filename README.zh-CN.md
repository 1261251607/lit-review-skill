# lit-review — Claude Code 人工智能文献调研 Skill

[![Version](https://img.shields.io/badge/version-2.1.1-blue)](https://github.com/1261251607/lit-review-skill)

面向研究人员的端到端学术文献工作流：**模式选择 → 主题拆解 → Google Scholar
检索 → 全文提取 → Zotero 组织管理 → 综合报告**。双模式：**quick-catch**
（~10-15 篇，快速入门）和 **deep-search**（~50-80 篇，深度综述，含跨维度分析和
研究前瞻）。覆盖 SCI / Nature / Science / Cell 及子刊。

## 特性

- **8 阶段自动化流程** — 选模、拆解、检索、排序、DOI校验、获取、整理、综合
- **双模式** — quick-catch 快速入门（~10-15 篇）或 deep-search 深度综述（~50-80 篇）
- **AI 综合报告** — 跨维度分析、方法论比较、研究前瞻，完整报告以 Zotero note 存入分类
- **DOI 校验 (Phase 3.5)** — 绝不猜 DOI，每篇文献入 Zotero 前强制校验
- **Edge 优先路由** — Edge WebSocket DevTools (9225) 统一处理所有 CARSI 出版社；Chrome CDP (9223) 兜底
- **任务文件隔离** — 全文 MD 按任务 slug 归类至 `~/.paper-fetcher/papers/{task}/`
- **浏览器最小化** — 自动抓取时浏览器保持最小化，仅用户登录时弹出
- **自适应 fallback 链** — OA → Edge WebSocket → Chrome CDP → HTTP → 元数据，无硬编码路由
- **多浏览器架构** — Edge（反爬出版社）+ Chrome（CDP）+ Chrome（Scholar，Cookie 隔离）
- **机构访问** — CARSI SAML 联邦认证、IP 直连、EZproxy
- **反爬对抗** — Edge 原生 DevTools 协议、Scholar Cookie 阻断、域名预热
- **全文 Markdown 输出** — 完整元数据 + 全文
- **Zotero 集成** — translation-server 解析元数据，自定义分类支持

## 前置条件

- [Claude Code](https://claude.ai/code)
- Python 3.10+、Node.js 22+
- Google Chrome、Microsoft Edge
- Zotero 7+（[API Key](https://www.zotero.org/settings/keys)）
- 机构访问权限（CARSI、EZproxy 或校园网 IP）

## 安装

```bash
# 1. 安装 Skill
cp -r lit-review-skill ~/.claude/skills/lit-review/

# 2. 安装依赖组件
# paper-fetcher（全文获取引擎）
git clone https://github.com/fermionoid/paper-fetcher.git
cd paper-fetcher && pip install -e .

# zotero-cli-cc（Zotero 命令行）
pip install zotero-cli-cc

# translation-server（Zotero 元数据解析）
git clone --recurse-submodules https://github.com/zotero/translation-server.git
cd translation-server && npm install

# Google Scholar MCP
git clone https://github.com/JackKuo666/Google-Scholar-MCP-Server.git
cd Google-Scholar-MCP-Server && pip install -r requirements.txt
```

## MCP 配置

```bash
claude mcp add -s user google-scholar -- python google_scholar_server.py
claude mcp add -s user paper-fetcher -- paper-fetcher-mcp
claude mcp add -s user -e PYTHONIOENCODING=utf-8 zotero -- zot mcp serve
```

## 启动服务

每次文献调研前启动：

```powershell
# 主 Chrome（端口 9223）— 出版社访问
powershell -File start_chrome.ps1

# Scholar Chrome（端口 9224）— Google Scholar，防限流
powershell -File start_chrome.ps1 -Scholar

# Edge（端口 9225）— ScienceDirect / Wiley
powershell -File start_edge.ps1

# Translation Server（端口 1969）
cd translation-server && npm start
```

在各浏览器中通过 CARSI 登录对应出版社（sciencedirect.com → 机构登录 → SJTU → jAccount）。

## 使用

在 Claude Code 中自然语言描述需求即可：

```
帮我找空气取水超声解吸附方向的论文，要近三年的
```

Skill 会先询问 **quick-catch**（快速了解）还是 **deep-search**（深度综述），
然后拆解主题、多维度检索、展示候选文献供筛选、获取全文、完成 Zotero 入库，
最终生成一份综合分析报告存入 Zotero 同一分类中。

## 工作流

```
模式（quick-catch / deep-search）
  → 主题 → Google Scholar（端口 9224）→ 候选文献 →
  用户选择 → paper-fetcher 自适应 fallback:
    第 0 层：开放获取（Unpaywall / arXiv）
    第 1 层：Edge WebSocket（端口 9225）
    第 2 层：Chrome CDP（端口 9223）
    第 3 层：HTTP 直连 / 机构代理
    兜底：元数据
  → translation-server → Zotero（完整元数据）
  → AI 综合报告 → 存入 Zotero note
```

**自适应 fallback**：不预设出版社路由。每层尝试获取全文（> 1000 字符即成功），失败则进入下一层。Edge WebSocket 优先于 Chrome CDP，因为原生 DevTools 协议无自动化指纹——源自 `sciencedirect-live-session-fetcher`。

**Google 防限流**：Scholar Chrome（端口 9224）使用 `--block-third-party-cookies` 阻断 Google 的追踪式限流。

## 已知限制

- **ScienceDirect / Wiley**：每次会话需手动登录 + 在 Edge 中预热一次
- **DeepSeek 后端**：`WebSearch` 工具不可用——使用 CDP 浏览器代替
- **`zot add --doi`**：生成空条目——务必使用 translation-server + pyzotero

## 致谢

本 Skill 参考和学习了以下开源项目：

- [paper-harbor-skill](https://github.com/Lucaswangzcx/paper-harbor-skill) — SD 浏览器搜索预热、Zotero bridge 设计、DrissionPage 自动化
- [sciencedirect-live-session-fetcher](https://github.com/Given-Dream/sciencedirect-live-session-fetcher) — Edge + 原生 WebSocket DevTools 协议（绕过 Elsevier 反爬的关键）
- [zotero-cli-cc](https://github.com/Agents365-ai/zotero-cli-cc) — Zotero CLI 与 MCP 设计、SQLite 直读
- [asta-skill](https://github.com/Agents365-ai/asta-skill) — Semantic Scholar MCP Skill 模式
- [paper-fetcher](https://github.com/fermionoid/paper-fetcher) — 多层全文获取架构（OA → 代理 → 元数据）
- [scholar-sidekick-mcp](https://github.com/mlava/scholar-sidekick-mcp) — 引用格式化参考
- [Google-Scholar-MCP-Server](https://github.com/JackKuo666/Google-Scholar-MCP-Server) — Google Scholar MCP
- [zotero-mcp](https://github.com/kujenga/zotero-mcp) — Zotero MCP 协议参考
- [translation-server](https://github.com/zotero/translation-server) — Zotero 翻译引擎

## License

MIT
