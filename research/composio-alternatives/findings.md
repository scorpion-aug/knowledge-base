---
title: "<Topic> — findings"
description: "Concepts, architecture and trade-offs for <topic>."
type: research-note
status: draft
date: 2026-11-10
author: res-researcher
cluster: <topic>
tags: [research, provisional, research-team, findings, <topic>]
sources: []
---

## Question

Headless mode: rubric proposed and auto-confirmed per the res-lead dispatch (RESEARCH-11).

**Question:** For a team replacing or avoiding Composio's hosted platform, which of the three OSI-licensed, self-hostable candidates — IBM ContextForge, Activepieces, Docker MCP Gateway — fits which use case, and how far does each fall short of Composio's baseline (1000+ pre-authenticated toolkits, managed OAuth with per-user sessions, triggers, sandbox, MCP endpoint)?

**Dimensions investigated** (from res-lead `needed:` and the RESEARCH-11 description):
1. Architecture and self-hosting footprint
2. Connector/tool coverage
3. OAuth and per-user credential handling
4. MCP and agent-framework integration
5. Governance / security
6. License caveats — including which Activepieces features are paid-only and whether Docker MCP Gateway has a SaaS credential vault
7. Feature-parity matrix vs Composio + fit by use case

**Candidate sources:** the 7 preserved docs in `external-sources/composio-alternatives-*` (baseline, 3 selected, 2 watch-list, license exclusions), plus 2-4 supplementary fetches where the scout marked gaps `unverified` (Activepieces paid-only tiers; Docker MCP catalog/credential scope).

**Success criteria:** every selected candidate covered on all 7 dimensions; parity matrix vs Composio; FACT lines cite a local `external-sources/` doc; OPINION lines labeled; no PoC requests (owner decision); audit clean.

**Output format:** Path A — `research/composio-alternatives/findings.md` from the `topic-findings` template.

## Context

Decision this informs: the owner is evaluating self-hostable, OSI-licensed replacements for Composio's hosted tool/credential layer for AI agents (see [sources](./sources.md) for the screen). res-scout's key finding ([sources](./sources.md)): the closest functional matches to Composio — Nango and Metorial — fail the OSI license check, so among OSI projects the match is partial: gateways cover routing/governance, Activepieces covers a connector catalog. The reader is the engineering owner deciding whether to adopt one of these, combine them, or stay on Composio. No PoC this round (owner call).

## Problem solved

Composio sells a hosted tool-and-credential layer for AI agents: 1000+ pre-authenticated toolkits, per-user sessions, OAuth/connected-account management, triggers and a sandbox, consumed either as native framework tools or over MCP ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)). The SDK is MIT but the backend is hosted-only — the quickstart requires a `COMPOSIO_API_KEY` from the hosted dashboard, and the fetched pages show no self-hostable backend (unverified) ([same source](../../external-sources/composio-alternatives-composio-baseline.md)). Teams that cannot send end-user OAuth tokens and tool traffic through a third-party SaaS (data-residency, air-gap, procurement, or license policy) need a self-hostable, OSI-licensed equivalent.

FACT: The scout's screen found no single OSI project that reproduces Composio's full bundle (large catalog + managed OAuth + token refresh); the closest functional matches (Nango, Metorial) fail the OSI check, so the field splits into gateways (routing/governance) and one connector catalog ([sources screen](./sources.md), [license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## Core concepts

- **MCP (Model Context Protocol):** open protocol standardising how AI applications connect to external tools/data; all three selected candidates expose or consume MCP servers ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md), [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- **Gateway vs catalog:** a *gateway* federates/proxies existing MCP servers and APIs behind one endpoint (ContextForge, Docker MCP Gateway); a *connector catalog* ships pre-built integrations to SaaS apps (Activepieces' pieces, Composio's toolkits). Composio is both; none of the three selected candidates is ([sources screen](./sources.md)).
- **Per-user credentials / connected accounts:** Composio's `composio.create(user_id)` session handles tool discovery, authentication and toolkit versioning per end-user ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)). This per-user OAuth-with-refresh layer is the hardest part to replace — OPINION: it is the main reason teams stay on Composio even when a gateway is available.
- **Open-core:** Activepieces' repo is MIT except `packages/ee/` and `packages/server/api/src/app/ee`, which require a paid enterprise subscription for production use ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)).
- **Container isolation of tool servers:** Docker MCP Gateway runs each MCP server as an isolated container with minimal host privileges, secrets held in Docker Desktop's secrets management rather than env vars ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).

## Architecture

### IBM ContextForge (Apache-2.0)

- **Architecture & self-hosting:** FACT: single gateway process, Python ≥3.11, distributed via PyPI (`mcp-contextforge-gateway`), container image (`ghcr.io/ibm/mcp-context-forge`), Helm charts and Ansible; scales to multi-cluster Kubernetes with Redis-backed federation and caching ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md), [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)). FACT: it runs as a fully compliant MCP server itself while federating MCP, A2A, REST and gRPC backends ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)). FACT: two secrets (`JWT_SECRET_KEY`, `AUTH_ENCRYPTION_SECRET`) are mandatory in every environment — the gateway refuses to start without them ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- **Connector coverage:** FACT: no catalog of pre-built SaaS connectors with managed OAuth is stated on the fetched pages; instead it *virtualizes* existing REST/gRPC APIs as MCP tools via a REST-to-MCP adapter (JSON Schema extraction, headers/tokens/custom auth, retry/timeout/rate-limit policies) and gRPC reflection ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md), [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)). OPINION: you bring your own APIs or MCP servers; ContextForge does not get you Gmail/GitHub/Slack connectors out of the box.
- **OAuth & per-user credentials:** FACT: built-in auth with *user-scoped OAuth tokens* plus unconditional `X-Upstream-Authorization` header support; Admin UI auth via Basic, JWT or custom schemes ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)). FACT: an opt-in on-behalf-of (OBO) bearer bridge (Oct 15, 2026) lets a plugin exchange the caller token for a downstream credential ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)). OPINION: the token-exchange hook is the right shape for Composio-style per-user auth, but the actual per-SaaS OAuth app registration, consent flow and refresh-token store is left to you/plugins — not shipped.
- **MCP & agent-framework integration:** FACT: transports HTTP, JSON-RPC, WebSocket, SSE (configurable keepalive) and Streamable HTTP; stdio server-side; selectable MCP protocol version (e.g. `2025-11-25`); Agent Gateway routes A2A plus OpenAI-compatible and Anthropic agents ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- **Governance:** FACT: centralized governance/discovery/observability positioning; 40+ plugins; guardrails; rate limiting, retries, reverse proxy; Admin UI (HTMX/Alpine) with real-time log viewer; OpenTelemetry tracing (Phoenix, Jaeger, Zipkin, Tempo, DataDog, New Relic) with LLM metrics (token usage, cost); air-gapped deployment supported ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- **License caveats:** FACT: Apache-2.0, no open-core split observed on the fetched pages ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)).

### Activepieces (MIT core + paid EE, open-core)

- **Architecture & self-hosting:** FACT: self-host recommended via Docker Compose with PostgreSQL and Redis; Helm chart for Kubernetes; community one-click templates (AWS/Pulumi, GCP, Railway, Elestio, Easypanel, PikaPods, RepoCloud, Zeabur) install the free Community edition and can lag ([Activepieces install docs](../../external-sources/composio-alternatives-activepieces-install.md)).
- **Connector coverage:** FACT: TypeScript "pieces" contributed to Activepieces automatically become available as MCP servers usable from Claude Desktop, Cursor or Windsurf; the repo description cites ~400 MCP servers ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)). FACT: the pricing page's Embed tier copy says "770+ integrations" ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)) — see Conflicting sources. FACT: it is the only OSI-core candidate with a real connector catalog ([sources screen](./sources.md)).
- **OAuth & per-user credentials:** FACT: "Global connections" (shared org-wide connections) is a Team-tier-and-up feature; Community/Free self-host does not include it per the pricing feature table ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)). FACT: pieces use "connections" (stored auth credentials) — but per-end-user OAuth delegation (Composio-style connected accounts) is not described in the fetched sources (TODO: needs source). OPINION: Activepieces connections are closer to Zapier's owner-shared model than to Composio's per-user model; verify before committing to a per-user product.
- **MCP & agent-framework integration:** FACT: pieces auto-exposed as MCP servers for MCP clients; MCPs and API access included even on the Free tier ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md), [Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)).
- **Governance:** FACT: SSO and standard roles from Team tier up; SCIM, custom RBAC, audit logs, secret managers, event streaming, private pieces, releases/Git Sync are Ultimate-only ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)).
- **License caveats (paid-only features):** FACT: `packages/ee/` and `packages/server/api/src/app/ee` are under a separate enterprise license requiring a valid Activepieces enterprise subscription for production use (dev/test allowed); everything else is MIT Expat ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)). FACT: the paid-only feature rows per the pricing page are: SSO + standard roles (Team), global connections (Team), unlimited projects (Team), and Ultimate-only: SCIM, custom RBAC, audit logs, secret managers, event streaming, private pieces, Git Sync/releases, priority execution, branding, platform governance ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)).

### Docker MCP Gateway (MIT)

- **Architecture & self-hosting:** FACT: a `docker-mcp` CLI plugin (Go, 97.9%) that runs each MCP server as an isolated Docker container with minimal host privileges, behind one gateway endpoint; works inside Docker Desktop or standalone; build from source via `make docker-mcp` into `~/.docker/cli-plugins/` ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md), [Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- **Connector coverage:** FACT: servers come from the OCI-based Docker MCP Catalog (default image `mcp/docker-mcp-catalog`, browsable at hub.docker.com/mcp), from OCI image references, from MCP Registry references, or from local `file://` server definitions; users can author their own catalogs via `docker mcp catalog create` ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)). FACT: the number of servers in the default catalog is not stated in the fetched text (unverified).
- **OAuth & per-user credentials:** FACT: built-in OAuth flows "for MCPs that require OAuth access token service connections"; secrets kept out of env vars via Docker Desktop's secrets management; v0.40.4 fixed OAuth callback-server issues (IPv6/AirPlay port-5000 conflict, stale DCR cache), showing the OAuth path is exercised ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md), [Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)). FACT: **whether Docker MCP Gateway offers a SaaS credential vault is not stated on the fetched pages — no hosted/managed vault is shown; secrets handling described is local (Docker Desktop)** ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md), [Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)). OPINION: per-user multi-tenant token stores are not its model — it is a single-developer-workstation/single-tenant deployment shape; serving many end-users' OAuth tokens through one gateway would need custom work (unverified).
- **MCP & agent-framework integration:** FACT: every MCP client (VS Code, Cursor, Claude Desktop, etc.) connects to the same gateway configuration; stdio by default, `sse` or `streaming` transports for multiple clients; profiles scope tool sets, with per-server tool enable/disable ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- **Governance:** FACT: container isolation and secrets management are the security story; no RBAC/audit-log/policy features appear in the fetched text ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- **License caveats:** FACT: MIT, copyright 2025 Docker ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)).

## Alternatives

Watch-list and excluded candidates from the screen, for completeness:

- **MetaMCP** (MIT): aggregator/orchestrator/middleware/gateway in one Docker image; last release v2.4.22 on 2025-12-10, last code-bearing commit 2026-06-16 — ~11 months stale at screen time, hence watch not selected ([MetaMCP source](../../external-sources/composio-alternatives-metamcp.md)).
- **Arcade arcade-mcp** (MIT): Python tool-authoring framework; auth handled by Arcade's hosted platform, self-hostable OSI auth engine not established (unverified) ([arcade-mcp source](../../external-sources/composio-alternatives-arcade-mcp.md)).
- **Nango** (Elastic License 2.0, not OSI): the closest functional match — managed OAuth/API-key auth with token refresh, proxy, 1,000+ APIs; ELv2 bars offering it as a hosted/managed service to third parties ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).
- **Metorial** (FSL-1.1-ALv2, not OSI until conversion): identity/access layer for agents, 1200+ integrations, OAuth/token lifecycle, RBAC, audit; Competing Use barred; catalog is Apache-2.0 ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).
- **n8n** (Sustainable Use License, not OSI) and **Klavis** (Apache-2.0 but archived by owner 2026-11-05) ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|

## Migration path

## Conflicting sources

## Open questions

## Requests for res-lab

- Question: … | Success criterion: … | Pinned versions: …

## Tentative recommendation

OPINION: …

## Related

- [Sources](./sources.md)
- [PoC](./poc/README.md)
- [Report](./report.md)
