---
title: "Composio baseline (GitHub README, docs, releases)"
description: "What Composio offers: SDK monorepo (MIT) plus hosted platform with toolkits, auth, sessions, triggers, sandbox and MCP."
type: source
source_url: https://github.com/ComposioHQ/composio
media_type: text/html
date_fetched: 2026-11-10
author: Composio
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - composio-alternatives
---
> Excerpts (middle omitted by fetcher) of https://github.com/ComposioHQ/composio, https://docs.composio.dev/docs and https://github.com/ComposioHQ/composio/releases.

Repo: ComposioHQ/composio, MIT License, 30,986 stars, 4,935 forks, default branch `next`, 1,214 releases, created 2024-02-23.

"Composio gives your AI agents 1000+ pre-authenticated toolkits, per-user sessions, authentication, triggers, and a sandbox, so you can ship agents that turn intent into action." The repo is the SDK monorepo: `@composio/core` (TypeScript), `composio` (Python), a `composio` CLI, and provider adapters for OpenAI Agents, Claude Agent SDK, Vercel AI SDK, LangChain and others. A `COMPOSIO_API_KEY` from the hosted dashboard is required for the quickstart.

Docs: two integration modes, native tools (with a provider package) and MCP (`session.mcp.url` plus headers for any MCP client). `composio.create(user_id)` creates a per-user session that handles tool discovery, authentication and toolkit versioning. Terminology: toolkits (apps), tools (actions), auth config (integration), connected account (connection), user ID (entity ID). Also: agent plugins for Codex and Claude Code, a CLI, and hosted "Sessions via MCP".

Releases page (fetched 2026-11-10): frequent CLI beta releases (e.g. @composio/cli@0.6.1-beta.534) and a Python SDK 0.31.0 release prep; 66 open issues, 80 open PRs.

Note: the page shows the SDK is MIT; it does not say the hosted backend (toolkit catalog, auth and execution service) is open source or self-hostable. Treated as hosted-only (unverified beyond this page).
