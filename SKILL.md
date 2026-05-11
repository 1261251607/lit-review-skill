# lit-review — AI-Powered Literature Search & Zotero Management

## What this skill does

End-to-end academic literature workflow: decomposes research topics, searches
Google Scholar, fetches full text via institutional access, resolves complete
metadata, and organizes papers into Zotero — all through natural language.

## When to trigger

User asks to search for papers, do a literature review, find references, or
"帮我找文献/搜论文/lit review/literature search/文献调研".

## Workflow

### Phase 1 — Topic Decomposition

Decompose the research topic into 3-5 search dimensions before searching.

Example: "超疏水表面减阻"
→ Dimension 1: superhydrophobic surface drag reduction (core concept)
→ Dimension 2: slip length measurement techniques (method)
→ Dimension 3: micro/nano structured surfaces for flow control (materials)
→ Dimension 4: turbulent drag reduction hydrophobic (applications)

Present dimensions briefly, then proceed to search.

### Phase 2 — Search

Search Google Scholar via CDP browser on port 9224 (Scholar Chrome with
`--block-third-party-cookies` to prevent rate-limiting).
6-8 results per dimension, plus one broader "母主题" search (8-10 results).
Use both English and Chinese keywords when the topic spans Chinese literature.

If Google Scholar MCP is available, prefer it. Otherwise use CDP.

### Phase 3 — Deduplicate & Rank

Merge results, deduplicate by DOI/title. Rank by:
1. Journal quality (Nature/Science/Cell/PNAS/学科顶刊 first)
2. Citation count
3. Relevance to the stated topic
4. Recency

Present a structured table:
```
## 候选文献 (N 篇)
| # | Title | Journal | Year | Cited | DOI |
|---|-------|---------|------|-------|-----|
| 1 | ...   | ...     | 2024 | 156   | 10.xxx/yyy |

简要概述：该领域主要集中在 [X] 个方向...
```

Ask: "要哪几篇？(输入编号，如 1,3,5-7) 还是全部保留？"

### Phase 4 — Full Text Fetch

Use paper-fetcher with publisher-aware routing:

| Publisher | Route | Method |
|-----------|-------|--------|
| Nature, Springer, IOP, RSC, APS, AIP | direct | HTTP (on-campus IP) |
| ACS, Wiley, Cell, Science | CDP | Chrome browser (port 9223) |
| ScienceDirect (Elsevier) | CDP+search | SD search page warmup → article |
| OA/preprint | OA | Unpaywall / arXiv |

Save full text as Markdown to `~/.paper-fetcher/papers/{slug}.md`.

Report:
```
获取全文:
  #1 ✓ "Title" — 97,185 chars (open_access) → papers/xxx.md
  #3 ✗ "Title" — metadata only
```

### Phase 5 — Zotero Collection

**Always consult the user before adding papers.**

1. `zot collection list`
2. Ask: "放入哪个分类？或输入 'new:分类名' 新建"
3. Create new collection if requested

### Phase 6 — Add to Zotero

Do NOT use `zot add --doi` (empty items). Use translation-server + pyzotero:

```bash
curl -s http://localhost:1969/web -X POST \
  -H "Content-Type: application/json" \
  -d '{"url":"https://doi.org/DOI","session":"lit-review"}'
```
Then create items with pyzotero, attach the collection key, and report summary.

## Required Services

1. **Main Chrome** (port 9223) — publisher access via CARSI
   `powershell -File start_chrome.ps1`
2. **Scholar Chrome** (port 9224) — Google Scholar with cookie blocking
   `powershell -File start_chrome.ps1 -Scholar`
3. **Translation-server** (port 1969) — Zotero metadata resolution
   `cd translation-server && npm start`

## Important Rules

- **Scholar rate-limiting**: Always use port 9224 (blocks third-party cookies).
  If still blocked, rotate domains: `scholar.google.com` → `.com.pk` → `.com.pr`.
- **SD anti-captcha**: Navigate `sciencedirect.com/search` first (human-like),
  then to the article — avoids cross-domain redirect detection.
- **Always consult** before Zotero writes.
- **Don't get stuck**: if full text fails, save metadata and move on.
- **Wiley JS content**: articles may lazy-load sections via JS.
