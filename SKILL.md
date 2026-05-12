# lit-review — AI-Powered Literature Search & Zotero Management

## What this skill does

End-to-end academic literature workflow: mode selection → topic decomposition → Google Scholar search →
full-text extraction (OA / Edge DevTools → Chrome CDP → HTTP direct) → DOI verification →
Zotero organization → synthesis report. Two modes: **quick-catch** (rapid overview, ~10-15 papers) and
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

Set task-slug from the topic (e.g. `gel-mof-awh`) for file organization.

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
- If Google Scholar MCP is available, prefer it. Otherwise use CDP.
- Domain rotation if blocked: `scholar.google.com` → `.com.pk` → `.com.pr`

**Chinese literature (知网/万方)**:
- Run a separate Chinese-only keyword search for each dimension (e.g. "植物工厂 热泵 温湿度").
  Google Scholar already indexes CNKI/Wanfang abstracts — Chinese keywords surface domestic papers.
- Chinese papers have usable abstracts in Scholar results. Include them in Phase 3 candidates.
- Metadata: Zotero plugin `jasminum` auto-fills CNKI metadata when you drag a paper into Zotero.
  For programmatic import, use paper-fetcher metadata or manual pyzotero construction.
- Full text: CNKI is accessible via SJTU campus IP (not CARSI). Manual download in browser at `cnki.net`.

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

### Phase 3.5 — DOI Verification

**BEFORE any Zotero import, verify every paper's DOI. Never guess a DOI.**

For each selected paper, use `paper-fetcher get_paper_metadata` to confirm the correct DOI.
If the DOI is uncertain, search Crossref or Semantic Scholar with the paper title.

Present a verified list:
```
DOI 校验:
  #1 ✓ 10.1038/s41578-024-00721-x
  #2 ✓ 10.1038/s44221-023-00099-0
  #3 ✗ DOI not found — needs manual lookup
  ...
```

Only papers with verified DOIs proceed to Phases 5-6. Flag unverified ones for manual resolution.

---

### Phase 4 — Full Text Fetch

Full-text scope by mode:
- **quick-catch**: top 3-5 most relevant (user selects or auto-rank)
- **deep-search**: top 2-3 per dimension + global top 5 (~15-20 total)

**CRITICAL: This phase must complete for ALL selected papers before proceeding to Phase 7.**
Do not skip paywalled papers. Attempt every paper — if a browser is needed, start it and route accordingly.
If a publisher requires CARSI login, pause and ask the user (see Service Architecture below).
Only when every paper has been attempted (success or confirmed failure) may you move on.

paper-fetcher uses an adaptive fallback chain — tries each layer, stops when it gets
> 1000 chars of full text:

```
Layer 0: Open Access (Unpaywall / arXiv)         ← free, no auth, always first
Layer 1: Edge WebSocket DevTools (port 9225)      ← all paywalled publishers
Layer 2: Chrome CDP (port 9223)                   ← fallback if Edge fails
Layer 3: HTTP direct / institutional proxy        ← Nature, Springer, IOP, RSC
Fallback: metadata only                           ← always available
```

**Publisher routing**: All CARSI-authenticated publishers (ACS, Wiley, Cell, Science, Nature, SD,
Springer, RSC) should be accessed via **Edge port 9225**. Chrome CDP (9223) is a fallback only.
Scholar Chrome (9224) is used exclusively for Google Scholar searches, never for publisher access.

Save full text as Markdown under a task-specific subdirectory:
`~/.paper-fetcher/papers/{task-slug}/—.md`

Report progress during fetching:
```
获取全文 [deep-search, 目标 ~18 篇]:
  #1 ✓ "Title" — 97,185 chars (open_access)
  #3 ✓ "Title" — 338,813 chars (sjtu_edge)
  #5 ✗ "Title" — metadata only (paywall, CARSI login needed)
  ... (N remaining)
```

### Phase 5 — Zotero Collection

**Always consult the user before writing to Zotero.**

1. `zot collection list`
2. Ask: "放入哪个分类？或输入 'new:分类名' 新建"
3. Create collection if requested

### Phase 6 — Add to Zotero

Use only verified DOIs from Phase 3.5. Never guess.

**Preferred method** — `zot add` via MCP with URL (no empty items):
```
mcp__zotero__add url="https://doi.org/10.xxx/xxx"
```

**Fallback method** — translation-server + pyzotero for batch imports:

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

For papers where translation-server fails (e.g. Elsevier/Cell DOIs), construct items manually
with pyzotero using metadata from paper-fetcher.

**Import ALL selected papers**, regardless of full-text availability. A paper with only metadata
is still a valid Zotero item with title, authors, journal, year, and DOI.

Report final summary: "M 篇入库（N 篇完整全文，K 篇元数据/摘要）".

---

### Phase 7 — Synthesis & Report

**PREREQUISITE: All full-text fetch attempts must be complete. Do not start Phase 7 until
Phase 4 is fully done.**

Transform collected papers into actionable understanding. **This phase is mandatory for both modes.**

**Use ALL available information from ALL selected papers.** Do not discard papers just because
full text was unavailable. The information hierarchy is:

| Tier | Source | Use for |
|------|--------|---------|
| Tier 1 | Complete full-text MD | Deep analysis, direct quotes, detailed methods, mechanism interpretation |
| Tier 2 | Abstract + highlights + figures | Core findings, key data, main conclusions, statistical trends |
| Tier 3 | Metadata only (title + journal + year) | Existence proof, publication venue context, timeline analysis |

- **Full-text MDs** under `~/.paper-fetcher/papers/{task-slug}/` are the primary source.
- **Abstracts and metadata** from Phase 3 Scholar results supplement gaps and broaden coverage.
- In the report, cite each paper with its tier: `[n]` = full text, `[n]*` = abstract, `[n]†` = metadata.
- A deep-search report with 42 candidates should engage with all 42 — not just the ~20 with full text.
- Do not mix in papers from other tasks.

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

**Citation style**: `[n]` = full text, `[n]*` = abstract only, `[n]†` = metadata. Distinguish tier in every reference.

**Key constraint**: 每个判断都要有文献支撑。基于全文优于摘要，摘要优于元数据。不要因为某篇只有摘要就放弃引用。

#### Store report in Zotero

After generating the report, create a standalone note item in the target Zotero collection
containing the **complete, unabridged** synthesis report (all four layers for deep-search,
all sections for quick-catch). Do NOT store a simplified or abbreviated version.

```python
from pyzotero import zotero
zot = zotero.Zotero('14349762', 'user', 'KEY')

note = {
    'itemType': 'note',
    'note': f'<h2>Literature Review: {主题}</h2>\n\n{report_html}',
    'collections': [COLLECTION_KEY],
}
zot.create_items([note])
```

The note appears alongside the papers in the same collection in Zotero.

---

## Service Architecture

### Before any session

Start all four services:

| Service | Port | Command | Purpose |
|---------|------|---------|---------|
| Edge (primary publisher access) | 9225 | `start_edge.ps1` | All CARSI-authenticated publishers |
| Chrome CDP (publisher fallback) | 9223 | `start_chrome.ps1` | Fallback for publishers Edge can't handle |
| Scholar Chrome | 9224 | `start_chrome.ps1 -Scholar` | Google Scholar only (cookie-blocked) |
| Translation | 1969 | `cd translation-server && npm start` | Zotero metadata resolution |

### CARSI login flow

1. Start all browser services. Browsers should open **minimized** — do not bring to front
   during automated fetching.
2. **Immediately remind the user:**
   > "请在 **Edge (9225)** 中打开以下出版社网站，走 SJTU CARSI 登录：
   > `sciencedirect.com` `onlinelibrary.wiley.com` `nature.com`
   > `pubs.acs.org` `cell.com` `link.springer.com` `pubs.rsc.org`
   >
   > 完成后告诉我。"
3. **STOP. Wait for the user to confirm login is done.** Do not search, fetch, or scrape
   until the user signals completion.
4. Only after user confirmation, proceed with paywalled paper fetching.
5. All automated fetching should use the browser in minimized state. Only bring a browser
   window to front when the user needs to interact with it (login, captcha).

---

## Full-Text Fallback Chain

paper-fetcher doesn't hardcode publisher routes. It tries layers in priority order,
stopping when it gets usable full text (> 1000 chars):

```
Layer 0 — OA: Unpaywall / arXiv (free, no auth, always first)
Layer 1 — Edge WebSocket: port 9225, raw DevTools protocol (zero automation fingerprint, all paywalled publishers)
Layer 2 — Chrome CDP: port 9223, DrissionPage (fallback for publishers Edge fails on)
Layer 3 — HTTP direct: institutional IP / proxy (for IP-authenticated publishers)
Fallback — metadata only (always available via Semantic Scholar / Crossref)
```

Edge WebSocket is prioritized over Chrome CDP because raw `Runtime.evaluate`
has no automation markers — learned from `sciencedirect-live-session-fetcher`.

---

## File Organization

- Full-text MDs: `~/.paper-fetcher/papers/{task-slug}/` (one subdirectory per task)
- Batch import scripts: `~/cc-massages/batch_import_{task-slug}.py` (clean up after use)

---

## Zotero Config

- Data dir: `C:/Users/Scholar/Zotero`
- Library ID: 14349762
- Read: SQLite direct (offline, millisecond)
- Write: Web API with pyzotero or MCP `zot add`

## Important Rules

- **Mode first**: Always ask quick-catch vs deep-search before Phase 1. Never assume.
- **Phase gate: Phase 4 must complete before Phase 7**: Do not start synthesis until all full-text attempts are done.
- **Never guess a DOI**: Always verify via Phase 3.5. A wrong DOI breaks the Zotero pipeline.
- **Never skip paywalled papers**: Attempt every paper. Start browsers, pause for login, try every layer.
- **Login comes before fetching, and wait for the user**: Start browsers → remind → STOP → wait for "done" → then fetch.
- **Browsers run minimized** during automated fetching. Only bring to front for user interaction.
- **All publisher CARSI login via Edge (9225)**. Chrome CDP (9223) is fallback only. Scholar Chrome (9224) is for Google Scholar only.
- **Synthesis is not optional**: Phase 7 is mandatory for both modes. Don't skip it.
- **Read full text, not abstracts**: Phase 7 analysis must be based on full-text MD files in the task subdirectory.
- **Complete report in Zotero**: Store the full unabridged synthesis report, not a summary.
- **Always consult** before Zotero writes — never auto-add without collection confirmation.
- **Don't get stuck**: if full text fails after exhausting all layers, save metadata and flag it.
- **Translation-server must be running** before Phase 6.
- **Import all papers, not just full-text ones**: Phase 6 imports every selected paper. Metadata-only items are valid Zotero entries.
- **Use all information tiers in synthesis**: Full text > abstract > metadata. Don't discard papers without full text — their abstracts still carry findings.
