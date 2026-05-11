# lit-review — Claude Code Skill for AI-Powered Literature Review

[![Version](https://img.shields.io/badge/version-1.1.1-blue)](https://github.com/1261251607/lit-review-skill)
[![中文](https://img.shields.io/badge/README-中文-red)](README.zh-CN.md)

End-to-end academic literature workflow for Claude Code: **topic decomposition →
Google Scholar search → full-text extraction → Zotero organization**.
Built for researchers who need broad coverage across SCI/Nature/Science/Cell
and their sub-journals.

## Features

- **6-phase automated workflow** — decompose, search, rank, fetch, organize, archive
- **Adaptive fallback chain** — OA → Edge WebSocket → Chrome CDP → HTTP → metadata, no hardcoded routes
- **Multi-browser architecture** — Edge (anti-bot publishers) + Chrome (CDP) + Chrome (Scholar, cookie-blocked)
- **Institutional access** — CARSI SAML federation, IP-based, and EZproxy support
- **Anti-bot countermeasures** — Edge raw DevTools protocol, Scholar cookie blocking, domain warmup
- **Full-text extraction** — Markdown output with complete metadata
- **Zotero integration** — translation-server for complete metadata, custom collection support

## Prerequisites

- [Claude Code](https://claude.ai/code)
- Python 3.10+, Node.js 22+
- Google Chrome
- Zotero 7+ with [API key](https://www.zotero.org/settings/keys)
- Institutional access (CARSI, EZproxy, or on-campus IP)

## Installation

```bash
# 1. Install the skill
cp -r lit-review-skill ~/.claude/skills/lit-review/

# 2. Install dependencies
# paper-fetcher (full-text engine)
git clone https://github.com/fermionoid/paper-fetcher.git
cd paper-fetcher && pip install -e .

# zotero-cli-cc (Zotero CLI)
pip install zotero-cli-cc

# translation-server (Zotero metadata)
git clone --recurse-submodules https://github.com/zotero/translation-server.git
cd translation-server && npm install

# Google Scholar MCP
git clone https://github.com/JackKuo666/Google-Scholar-MCP-Server.git
cd Google-Scholar-MCP-Server && pip install -r requirements.txt
```

## MCP Configuration

```bash
claude mcp add -s user google-scholar -- python google_scholar_server.py
claude mcp add -s user paper-fetcher -- paper-fetcher-mcp
claude mcp add -s user -e PYTHONIOENCODING=utf-8 zotero -- zot mcp serve
```

## Startup

Before each lit-review session, start these services:

```powershell
# Main Chrome (port 9223) — publisher access
powershell -File start_chrome.ps1

# Scholar Chrome (port 9224) — Google Scholar, no rate-limiting
powershell -File start_chrome.ps1 -Scholar

# Translation server (port 1969)
cd translation-server && npm start
```

Log into CARSI in the Main Chrome: sciencedirect.com → Sign in via institution → select your university → login.

## Usage

In Claude Code, just describe what you need:

```
帮我找空气取水超声解吸附方向的论文，要近三年的
```

The skill will decompose the topic, search across dimensions, present results,
fetch full text where possible, and add everything to Zotero (after asking
which collection to use).

## How It Works

```
Topic → Google Scholar (port 9224) → candidates →
  User selects → paper-fetcher adaptive fallback:
    Layer 0: Open Access (Unpaywall/arXiv)
    Layer 1: Edge WebSocket (port 9225)
    Layer 2: Chrome CDP (port 9223)
    Layer 3: HTTP direct / proxy
    Fallback: metadata only
  → translation-server → Zotero (complete metadata)
```

**Adaptive fallback**: No hardcoded publisher routes. Each layer tries, succeeds
(> 1000 chars), or passes to the next. Edge WebSocket is prioritized over Chrome
CDP because raw DevTools protocol has zero automation fingerprint — learned from
`sciencedirect-live-session-fetcher`.

**Anti-Google-rate-limit**: a dedicated Chrome instance on port 9224 with
`--block-third-party-cookies` prevents Google's tracking-based throttling.

## Known Limitations

- **ScienceDirect / Wiley**: need one-time per-session login + manual warmup in Edge
- **DeepSeek backend**: `WebSearch` tool unavailable — uses CDP browser instead
- **`zot add --doi`**: produces empty items — always use translation-server + pyzotero

## Acknowledgments

This skill builds on ideas and code from the open-source community:

- [paper-harbor-skill](https://github.com/Lucaswangzcx/paper-harbor-skill) — ScienceDirect CDP search-warmup pattern, Zotero bridge design, DrissionPage browser automation
- [sciencedirect-live-session-fetcher](https://github.com/Given-Dream/sciencedirect-live-session-fetcher) — Edge + native WebSocket DevTools protocol (the key to bypassing Elsevier bot detection)
- [zotero-cli-cc](https://github.com/Agents365-ai/zotero-cli-cc) — Zotero CLI and MCP server design, SQLite direct read
- [asta-skill](https://github.com/Agents365-ai/asta-skill) — Semantic Scholar MCP skill pattern
- [paper-fetcher](https://github.com/fermionoid/paper-fetcher) — multi-layer full-text fetching architecture (OA → proxy → metadata)
- [scholar-sidekick-mcp](https://github.com/mlava/scholar-sidekick-mcp) — citation formatting and Zotero RDF export reference
- [Google-Scholar-MCP-Server](https://github.com/JackKuo666/Google-Scholar-MCP-Server) — Google Scholar MCP server
- [zotero-mcp](https://github.com/kujenga/zotero-mcp) — Zotero MCP protocol reference
- [translation-server](https://github.com/zotero/translation-server) — Zotero translator engine

## License

MIT
