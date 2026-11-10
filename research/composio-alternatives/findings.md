---
title: "Composio alternatives — findings"
description: "ContextForge, Activepieces and Docker MCP Gateway vs Composio: architecture, connectors, OAuth, MCP, governance, license caveats, parity matrix."
type: research-note
status: draft
date: 2026-11-10
author: res-researcher
cluster: composio-alternatives
tags: [ composio-alternatives, findings, provisional, research, research-team ]
sources: [ { resource: ../../external-sources/composio-alternatives-composio-baseline.md }, { resource: ../../external-sources/composio-alternatives-contextforge.md }, { resource: ../../external-sources/composio-alternatives-contextforge-readme.md }, { resource: ../../external-sources/composio-alternatives-activepieces.md }, { resource: ../../external-sources/composio-alternatives-activepieces-pricing.md }, { resource: ../../external-sources/composio-alternatives-activepieces-install.md }, { resource: ../../external-sources/composio-alternatives-docker-mcp-gateway.md }, { resource: ../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md }, { resource: ../../external-sources/composio-alternatives-metamcp.md }, { resource: ../../external-sources/composio-alternatives-arcade-mcp.md }, { resource: ../../external-sources/composio-alternatives-license-exclusions.md } ]
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

### Feature-parity matrix vs Composio

Legend: ✅ present per source · ⚠️ partial / DIY · ❌ absent or not stated · Sources in the Architecture section rows above.

| Composio capability (baseline: [Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)) | ContextForge | Activepieces (self-host Community) | Docker MCP Gateway |
|---|---|---|---|
| Pre-built SaaS connector catalog (Composio: 1000+) | ❌ none stated; virtualize your own REST/gRPC | ✅ ~400 pieces as MCP servers (repo); "770+" in marketing copy — see Conflicting sources | ⚠️ Docker MCP Catalog + OCI/registry/local refs; catalog size unverified |
| Managed OAuth for SaaS tools (consent, token refresh) | ⚠️ user-scoped OAuth tokens + OBO token-exchange hook; per-app registration/refresh DIY | ⚠️ connections model; Global connections Team-tier+; per-user OAuth not described (unverified) | ⚠️ built-in OAuth flows for OAuth-capable MCP servers; local secrets, no vault stated |
| Per-user / multi-tenant sessions (Composio `user_id`) | ⚠️ user-scoped tokens, but no connected-account store shown | ❌ not described in fetched sources | ❌ single-tenant workstation shape (OPINION) |
| MCP endpoint for any client | ✅ fully compliant MCP server, multi-transport | ✅ pieces auto-exposed as MCP servers | ✅ single gateway endpoint; stdio/sse/streaming |
| Native agent-framework adapters (OpenAI/LangChain/Vercel etc.) | ⚠️ A2A + OpenAI-compatible/Anthropic routing; MCP for the rest | ❌ MCP + API/SDK only (per pricing table) | ❌ MCP only |
| Triggers / event automation | ❌ not stated | ✅ flows/automation engine (core product) | ❌ not stated |
| Sandbox / code execution | ❌ not stated | ❌ not stated | ⚠️ container isolation of servers (isolation, not a code sandbox) |
| Governance (RBAC, audit logs, policy) | ✅ guardrails, plugins, rate-limit, OTel observability | ❌ Community: none; SSO/RBAC/audit paid (Team/Ultimate) | ❌ none stated |
| Self-host, OSI license end-to-end | ✅ Apache-2.0 | ⚠️ MIT core; EE dirs require paid subscription in production | ✅ MIT |

### Options table

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|
| ContextForge | Apache-2.0 end-to-end; strongest governance/observability; REST/gRPC virtualization; K8s-scale federation ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)) | No connector catalog; per-SaaS OAuth lifecycle DIY; young project (created 2025-05-08, 4.8k stars) ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)) | One Python process + Redis (multi-cluster); mandatory secrets bootstrap; PyPI/Docker/Helm/Ansible artifacts | Low license lock-in; moderate API-surface lock-in to its plugin/registry model (OPINION) |
| Activepieces | Only OSI-core catalog (~400-770 pieces); MCP exposure free even on Free tier; simple Compose/Helm self-host ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md), [install docs](../../external-sources/composio-alternatives-activepieces-install.md)) | Open-core: SSO, RBAC, audit logs, secret managers, private pieces, global connections all paid; per-user OAuth model unverified; EE production use requires subscription ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)) | Compose: app + PostgreSQL + Redis; Helm for K8s; license-key activation step for EE | Moderate: EE features create upgrade pressure; MIT core forkable (OPINION) |
| Docker MCP Gateway | MIT; Docker-backed release cadence (v0.44.3, 2026-10-26); container isolation + Desktop secrets; catalog extensible via OCI/registry/local ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md), [README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)) | No governance/RBAC/audit; no SaaS credential vault stated; catalog size unverified; Docker Desktop dependency for secrets ergonomics | Docker daemon + CLI plugin; per-server containers | Low license lock-in; ecosystem pull toward Docker Desktop/Hub (OPINION) |

## Migration path

From Composio, per use case (OPINION, grounded in the FACT rows above):

1. **Replace the MCP endpoint only** (tools already exist as MCP servers or internal APIs): stand up ContextForge or Docker MCP Gateway, re-point agent clients from `session.mcp.url` to the gateway endpoint. ContextForge if you need governance/observability; Docker MCP Gateway if you want container isolation and the Docker catalog.
2. **Replace the connector catalog**: adopt Activepieces self-host; rebuild the Composio toolkits you use as Activepieces pieces/connections; expose to agents over its MCP servers. Budget for the paid tier if you need SSO/audit/global connections.
3. **Replace per-user OAuth**: hardest gap. ContextForge's OBO token-exchange plugin hook is the only shipped primitive; otherwise build a small token-vault service (OPINION) or revisit Nango/Metorial if the license posture ever changes.
4. **Hybrid** (likely the realistic path, OPINION): Activepieces for catalog + ContextForge in front for governance/routing, Docker MCP Gateway for local-dev tool isolation.

## Conflicting sources

- **Activepieces catalog size:** the repo description captured 2026-11-10 cites "~400 MCP servers" ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)); the pricing page's Embed tier copy says "770+ integrations" ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)). Likely different counts (pieces-as-MCP-servers vs total integrations marketed), not a true contradiction — but the exact current count is unverified. Treat "~400 MCP-exposed pieces" as the conservative figure.
- **Docker MCP Gateway latest-commit CI:** the repo capture shows the 2026-10-26 commit's CI check as failure while releases kept tagging (v0.44.3 same day) ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)). Recorded as a freshness caveat, not a correctness claim.
- **Composio self-hostability:** the baseline source notes the MIT SDK but no self-hostable backend shown; marked unverified beyond the fetched pages ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)).
- **ContextForge README truncation:** the ContextForge README capture is head+tail (~15k of ~40.7k chars); Installation/Configuration/Cloud-deployment sections are missing, so config-level claims rely on the captured overview/quickstart only ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).

## Open questions

- Does Activepieces self-host Community support per-end-user OAuth delegation (Composio-style connected accounts), or only owner-level connections? (TODO: needs source)
- How large is the default Docker MCP Catalog, and how many servers ship with OAuth support? (unverified in fetched text)
- Does Composio offer any self-host/VPC option not visible on the fetched pages? (unverified)
- ContextForge: what do the 40+ plugins cover — is there a community plugin for SaaS OAuth token stores? (TODO: needs source)
- Metorial's FSL→Apache-2.0 conversion date (in the omitted part of its license text) — when does it become OSI-usable? ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md))

## Requests for res-lab

None — owner said no PoC this round.

## Tentative recommendation

OPINION: There is no drop-in OSI replacement for Composio today; pick by use case. For an engineering team that mainly needs to govern and federate internal APIs/MCP servers for agents, **ContextForge** is the strongest single choice (Apache-2.0, governance, observability, OBO hook). For a team whose pain is connector breadth for business-SaaS tools, **Activepieces self-host** is the only OSI-core catalog — but price in the Team/Ultimate tiers if SSO/audit/global connections are required. **Docker MCP Gateway** is the best fit for developer-local tool isolation and a clean MCP endpoint with minimal moving parts. The realistic end-state is hybrid: Activepieces (catalog) behind ContextForge (governance), with Docker MCP Gateway on dev workstations. If per-user managed OAuth at scale is the hard requirement and licenses are negotiable, re-open the Nango/Metorial conversation — they remain the closest functional matches ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## Related

- [Sources](./sources.md)
- PoC: not requested this round (owner decision; no poc/ folder)
- Report: pending — written by res-writer as the next step (report.md does not exist yet)
