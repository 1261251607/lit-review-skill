# lit-review — Claude Code Skill for AI-Powered Literature Review

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/1261251607/lit-review-skill)

End-to-end academic literature workflow for Claude Code: **topic decomposition →
Google Scholar search → full-text extraction → Zotero organization**.
Built for researchers who need broad coverage across SCI/Nature/Science/Cell
and their sub-journals.

## Features

- **6-phase automated workflow** — decompose, search, rank, fetch, organize, archive
- **Publisher-aware routing** — different access strategies for Nature/ACS/ScienceDirect/Wiley/etc.
- **Institutional access** — leverages CARSI (Chinese university SAML federation) or IP-based access
- **Anti-bot countermeasures** — domain warmup, tab reuse, third-party cookie blocking to bypass captcha
- **Full-text extraction** — OA → institutional IP → CDP browser, with Markdown output
- **Zotero integration** — complete metadata via translation-server, custom collection support

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
  User selects → paper-fetcher:
    ├─ OA? → Unpaywall/arXiv
    ├─ Direct IP? → Nature/Springer/IOP/RSC
    ├─ CDP browser? → ACS/Wiley/Cell/Science
    └─ CDP+search? → ScienceDirect (special anti-captcha)
  → translation-server → Zotero (complete metadata)
```

**Publisher routing**: Direct IP access works for publishers that authenticate
by IP (Nature, Springer). CDP browser access works for publishers with aggressive
anti-bot but institutional login (ACS, Wiley). ScienceDirect gets special
treatment: search page warmup before article navigation.

**Anti-SD-captcha trick** (learned from paper-harbor): navigate to
`sciencedirect.com/search` first, then to the article — staying within
the same domain avoids the bot-detection redirect chain.

**Anti-Google-rate-limit**: a dedicated Chrome instance on port 9224 with
`--block-third-party-cookies` prevents Google's tracking-based throttling.

## Known Limitations

- **ScienceDirect**: needs one-time manual warmup per session (30s browsing)
- **Wiley**: articles with JS-lazy-loaded content may get partial extraction
- **DeepSeek backend**: `WebSearch` tool unavailable — uses CDP browser instead
- **`zot add --doi`**: produces empty items — always use translation-server + pyzotero

## License

MIT
