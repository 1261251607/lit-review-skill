# lit-review — AI-Powered Literature Search & Zotero Management

## What this skill does

End-to-end academic literature workflow: topic decomposition → Google Scholar search →
full-text extraction (OA / IP-direct / Edge / Chrome CDP) → Zotero organization with
complete metadata. Designed for researchers needing broad coverage across SCI / Nature /
Science / Cell and their sub-journals.

## When to trigger

User says "帮我找文献 / 搜论文 / lit review / literature search / 文献调研" or asks
to find papers on a specific topic.

---

## Workflow

### Phase 1 — Topic Decomposition

Decompose the research topic into 3–5 logical sub-dimensions before searching.

Example: "空气取水超声解吸附超越热极限"
→ D1: ultrasonic desorption atmospheric water harvesting (core)
→ D2: non-thermal sorbent regeneration acoustic cavitation (mechanism)
→ D3: beyond latent heat vaporization limit AWH energy efficiency (performance)
→ D4: MOF hydrogel sorbent ultrasonic-assisted desorption (materials)
→ D5: next-generation atmospheric water harvesting review 2024–2026 (context)

Present dimensions to the user, then search.

### Phase 2 — Search

Search Google Scholar via CDP browser on **port 9224** (Scholar Chrome with
`--block-third-party-cookies` to prevent Google's tracking-based rate limiting).

- 6–8 results per dimension
- One broader "母主题" search with 8–10 results
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

### Phase 4 — Full Text Fetch

paper-fetcher uses an adaptive fallback chain — tries each layer in order,
stops when it gets > 1000 chars of full text:

```
Layer 0: Open Access (Unpaywall / arXiv)         ← free, no auth
Layer 1: Edge + WebSocket DevTools (port 9225)   ← SD, Wiley, any anti-bot
Layer 2: Chrome CDP (port 9223)                  ← ACS, Cell, Science, etc.
Layer 3: HTTP direct / institutional proxy       ← Nature, Springer, IOP, RSC
Fallback: metadata only                          ← always available
```

Each layer either succeeds (> 1000 chars) or passes to the next.
No hardcoded publisher routes — the chain self-adapts.

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

- **Scholar rate-limiting**: Always use port 9224 (blocks third-party cookies).
- **SD/Wiley**: Always use Edge port 9225 (native DevTools, no DrissionPage).
- **Always consult** before Zotero writes — never auto-add without collection confirmation.
- **Don't get stuck**: if full text fails, save metadata and flag it.
- **Translation-server must be running** before Phase 6.
