# lit-review — AI-Powered Literature Search & Zotero Management

## What this skill does

End-to-end academic literature workflow: mode selection → topic decomposition → Google Scholar search →
full-text extraction (OA / IP-direct / Edge / Chrome CDP) → Zotero organization with
complete metadata → synthesis report. Two modes: **quick-catch** (rapid overview, ~10-15 papers) and
**deep-search** (comprehensive review, ~50-80 papers).

## When to trigger

User says "帮我找文献 / 搜论文 / lit review / literature search / 文献调研" or asks
to find papers on a specific topic.

---

## Workflow

### Phase 0 — Mode Selection

**Always ask the user before any searching:**

> 这次调研是想 **快速了解 (quick-catch)** 还是 **深度综述 (deep-search)**？
>
> - **quick-catch**: 10-15 篇，读 top 3-5 全文，快速建立领域认知框架
> - **deep-search**: 50-80 篇，读每维度 top 2-3 + 全局 top 5（~15-20 篇全文），产出分维度深度解析 + 跨维度逻辑连接 + 前瞻

Derive mode-specific parameters:

| Parameter | quick-catch | deep-search |
|-----------|-------------|-------------|
| Sub-dimensions | 3 | 5-6 |
| Papers per dimension | 6-8 | 10-15 |
| Broad "母主题" search | 8-10 | 15-20 |
| Full-text scope | top 3-5 overall | top 2-3 per dim + top 5 globally (~15-20) |
| Report depth | ~800-1200 字 | ~3000-5000 字 |

### Phase 1 — Topic Decomposition

Decompose the research topic into logical sub-dimensions. Number of dimensions depends on mode
(3 for quick-catch, 5-6 for deep-search).

Example (deep-search: "空气取水超声解吸附超越热极限"):
→ D1: ultrasonic desorption atmospheric water harvesting (core)
→ D2: non-thermal sorbent regeneration acoustic cavitation (mechanism)
→ D3: beyond latent heat vaporization limit AWH energy efficiency (performance)
→ D4: MOF hydrogel sorbent ultrasonic-assisted desorption (materials)
→ D5: next-generation atmospheric water harvesting review 2024-2026 (context)

Present dimensions to the user, then search.

### Phase 2 — Search

Search Google Scholar via CDP browser on **port 9224** (Scholar Chrome with
`--block-third-party-cookies` to prevent Google's tracking-based rate limiting).

- Papers per dimension: 6-8 (quick-catch) / 10-15 (deep-search)
- One broader "母主题" search: 8-10 (quick-catch) / 15-20 (deep-search)
- English + Chinese keywords when the topic spans Chinese literature
- If Google Scholar MCP is available, prefer it. Otherwise use CDP.
- Domain rotation if blocked: `scholar.google.com` → `.com.pk` → `.com.pr`

### Phase 3 — Deduplicate & Rank

Merge all results, deduplicate by DOI/title. Rank by:
1. Journal quality (Nature/Science/Cell/学科顶刊 first)
2. Citation count
3. Relevance
4. Recency

Present a structured table:
```
## 候选文献 (N 篇)
| # | Title | Journal | Year | DOI |
|---|-------|---------|------|-----|
| 1 | ...   | ...     | 2025 | 10.xxx |

简要概述：核心发现, 主流方向, 值得关注的趋势...
```

Ask: "要哪几篇？(输入编号) 还是全部保留？"

For **quick-catch**: remind the user we'll only fetch full text for the most relevant ~5.
For **deep-search**: ask which papers to prioritize, or approve auto-selection of
top 2-3 per dimension + top 5 globally.

### Phase 4 — Full Text Fetch

Full-text scope by mode:
- **quick-catch**: top 3-5 most relevant (user selects or auto-rank)
- **deep-search**: top 2-3 per dimension + global top 5 (~15-20 total)

paper-fetcher uses an adaptive fallback chain — tries each layer, stops when it gets
> 1000 chars of full text:

```
Layer 0: Open Access (Unpaywall / arXiv)         ← free, no auth
Layer 1: Edge + WebSocket DevTools (port 9225)   ← SD, Wiley, any anti-bot
Layer 2: Chrome CDP (port 9223)                  ← ACS, Cell, Science, etc.
Layer 3: HTTP direct / institutional proxy       ← Nature, Springer, IOP, RSC
Fallback: metadata only                          ← always available
```

Save full text as Markdown: `~/.paper-fetcher/papers/{slug}.md`

Report:
```
获取全文:
  #1 ✓ "Title" — 97,185 chars (open_access)
  #3 ✓ "Title" — 338,813 chars (sjtu_edge)
  #5 ✗ "Title" — metadata only
```

### Phase 5 — Zotero Collection

**Always consult the user before writing to Zotero.**

1. `zot collection list`
2. Ask: "放入哪个分类？或输入 'new:分类名' 新建"
3. Create collection if requested

### Phase 6 — Add to Zotero

Do NOT use `zot add --doi` (produces empty items). Use the two-step pipeline:

**Step A — Resolve metadata via translation-server (port 1969):**
```bash
curl -s http://localhost:1969/web -X POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://doi.org/DOI","session":"lit-review"}'
```

**Step B — Create items with pyzotero:**
```python
from pyzotero import zotero
zot = zotero.Zotero('14349762', 'user', 'KEY')
template['collections'] = [COLLECTION_KEY]
zot.create_items([template])
```

**Step C — Attach full-text MD as note:**
```bash
zot note KEY --add "Full text: ~/.paper-fetcher/papers/{slug}.md"
```

Report final summary with full-text coverage stats.

### Phase 7 — Synthesis & Report

Transform collected papers into actionable understanding. **This phase is mandatory for both modes.**

Read full-text MD files in `~/.paper-fetcher/papers/` — not just abstracts. If a paper has only
metadata, flag it and exclude from deep analysis.

#### quick-catch report (~800-1200 字中文)

Read top 3-5 full-text MDs. Structure:

1. **核心问题** (1-2 段): 这个领域要解决什么问题？为什么重要？
2. **主流路线** (2-3 条): 当前主要的解决思路，每条一句话讲清楚逻辑
3. **关键共识与争议**: 学界普遍认同什么？哪里还在打架？
4. **代表作一句话** (按 [n] 编号): 每篇文献一句核心发现

Tone: 让不懂这个领域的人 10 分钟建立 mental model。术语首次出现时解释。

#### deep-search report (~3000-5000 字中文)

Read top 2-3 per dimension + global top 5 (~15-20 full-text MDs). Structure in four layers:

**Layer 1 — 逐维度深析** (~300-500 字/维度): 每个子维度的核心进展、代表性方法、关键数据、当前瓶颈。不是文献摘要排排坐——是对该维度研究图景的**重构**。

**Layer 2 — 跨维度逻辑连接**: 不同维度之间的内在关系——哪些发现互相印证？哪些结论相互矛盾？哪些技术路线存在依赖或竞争？哪条路线可能最终统一其他路线？这是综述区别于摘要的核心。

**Layer 3 — 方法论比较**: 实验设计、表征手段、理论框架、模拟方法的横向对比。不只说"X 方法好"——说明白 trade-off：什么条件下适用，固有局限是什么。

**Layer 4 — 前瞻与空白**: 基于最新文献趋势，推演 2-3 个可能研究方向和关键科学问题。不能泛泛"还需要更多研究"——要具体到能写进 proposal 的程度："因为 A 和 B 在机制上互斥但实验结果都成立，说明中间可能有未被表征的中间态，建议用 X 方法探测"。

**Citation style**: 正文引用用 [n]（对应 Phase 3 表格编号），方便对照回查。

**Key constraint**: 基于全文 MD 写作，不是抽象。每个判断都要有文献支撑。

#### Store report in Zotero

After generating the report, create a standalone note item in the target Zotero collection:

```python
from pyzotero import zotero
zot = zotero.Zotero('14349762', 'user', 'KEY')

note = {
    'itemType': 'note',
    'note': f'<h2>Literature Review: {主题}</h2>\n\n' + report_html,
    'collections': [COLLECTION_KEY],
}
zot.create_items([note])
```

The note appears alongside the papers in the same collection in Zotero.

---

## Service Architecture

Start these before a session:

| Service | Port | Command | Purpose |
|---------|------|---------|---------|
| Main Chrome | 9223 | `start_chrome.ps1` | CDP publishers (ACS, Cell, Science) |
| Scholar Chrome | 9224 | `start_chrome.ps1 -Scholar` | Google Scholar (cookie-blocked) |
| Edge | 9225 | `start_edge.ps1` | SD + Wiley (WebSocket DevTools) |
| Translation | 1969 | `cd translation-server && npm start` | Zotero metadata resolution |

One-time per session in each browser: CARSI login to the relevant publishers.

---

## Full-Text Fallback Chain

paper-fetcher doesn't hardcode publisher routes. It tries layers in priority order,
stopping when it gets usable full text (> 1000 chars):

```
Layer 0 — OA: Unpaywall / arXiv (free, no auth, always first)
Layer 1 — Edge WebSocket: port 9225, raw DevTools protocol (zero automation fingerprint, handles anti-bot publishers)
Layer 2 — Chrome CDP: port 9223, DrissionPage (for publishers that don't detect automation)
Layer 3 — HTTP direct: institutional IP / proxy (for IP-authenticated publishers)
Fallback — metadata only (always available via Semantic Scholar / Crossref)
```

Edge WebSocket is prioritized over Chrome CDP because raw `Runtime.evaluate`
has no automation markers — learned from `sciencedirect-live-session-fetcher`.

---

## Zotero Config

- Data dir: `C:/Users/Scholar/Zotero`
- Library ID: 14349762
- Read: SQLite direct (offline, millisecond)
- Write: Web API with pyzotero

## Important Rules

- **Mode first**: Always ask quick-catch vs deep-search before Phase 1. Never assume.
- **Synthesis is not optional**: Phase 7 is mandatory for both modes. Don't skip it.
- **Read full text, not abstracts**: Phase 7 analysis must be based on full-text MD files.
- **Scholar rate-limiting**: Always use port 9224 (blocks third-party cookies).
- **SD/Wiley**: Always use Edge port 9225 (native DevTools, no DrissionPage).
- **Always consult** before Zotero writes — never auto-add without collection confirmation.
- **Don't get stuck**: if full text fails, save metadata and flag it.
- **Translation-server must be running** before Phase 6.
