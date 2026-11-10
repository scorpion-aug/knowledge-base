---
author: res-writer
cluster: composio-alternatives
date: 2026-11-10
description: "ContextForge, Activepieces and Docker MCP Gateway compared with Composio: fit by use case, parity matrix, license caveats."
sources:
  - resource: ../../external-sources/composio-alternatives-composio-baseline.md
  - resource: ../../external-sources/composio-alternatives-contextforge.md
  - resource: ../../external-sources/composio-alternatives-contextforge-readme.md
  - resource: ../../external-sources/composio-alternatives-activepieces.md
  - resource: ../../external-sources/composio-alternatives-activepieces-pricing.md
  - resource: ../../external-sources/composio-alternatives-activepieces-install.md
  - resource: ../../external-sources/composio-alternatives-docker-mcp-gateway.md
  - resource: ../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md
  - resource: ../../external-sources/composio-alternatives-license-exclusions.md
status: draft
tags:
  - research
  - provisional
  - research-team
  - report
  - composio-alternatives
title: Composio alternatives — report
type: research-note
---
> **Draft.** Built from [findings.md](./findings.md) and [sources.md](./sources.md). No PoC was run (the owner said one is not needed), so nothing here was installed or measured. Every fact comes from preserved project pages fetched 2026-11-10. Open items are under [Gaps](#gaps).

## Problem

Composio gives AI agents 1000+ pre-authenticated toolkits, per-user sessions, authentication, triggers and a sandbox ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)). Its SDK is MIT, but the quickstart needs a `COMPOSIO_API_KEY` from the hosted dashboard. The fetched pages don't show a self-hostable backend, so we treat Composio as hosted-only (unverified beyond those pages) ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)).

This report answers one question: for a team that can't route end-user tokens and tool traffic through a third-party SaaS, which self-hostable, OSI-licensed tool fits which use case, and how far short of Composio does each fall? The screen selected three candidates: IBM ContextForge, Activepieces and Docker MCP Gateway ([sources.md](./sources.md)).

**Headline:** none of the three is a drop-in replacement. The closest functional matches, Nango and Metorial, fail the OSI license check ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)). The OSI field splits into *gateways* (ContextForge, Docker MCP Gateway) and one *connector catalog* (Activepieces) ([findings](./findings.md#problem-solved)).

## Concepts

- **MCP (Model Context Protocol):** an open protocol for connecting AI applications to external tools and data. All three candidates expose or consume MCP servers ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md), [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- **Gateway vs catalog:** a *gateway* puts existing MCP servers and APIs behind one endpoint. A *connector catalog* ships ready-made integrations to SaaS apps such as Gmail or Slack. Composio does both. Of the three candidates, ContextForge and Docker MCP Gateway are gateways and Activepieces is the catalog ([findings](./findings.md#core-concepts)).
- **Per-user credentials / connected accounts:** Composio's `composio.create(user_id)` creates a per-user session that handles tool discovery, authentication and toolkit versioning for each end user ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)). This layer is the hardest part to replace (opinion, from [findings](./findings.md#core-concepts)).
- **OBO (on-behalf-of) token exchange:** a gateway swaps the caller's token for a credential to a downstream service. ContextForge added an opt-in OBO bearer bridge for plugins on 2026-10-15 ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)).
- **Open-core:** most of the code is under an OSI license, and some parts need a paid license. Activepieces is MIT except `packages/ee/` and `packages/server/api/src/app/ee`, which need an enterprise subscription for production use ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)).
- **OSI license:** a license approved by the Open Source Initiative. Elastic License 2.0 (Nango), FSL-1.1 (Metorial) and n8n's Sustainable Use License are not OSI-approved ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## Options

### IBM ContextForge: governed MCP/API gateway (Apache-2.0)

- A registry and proxy that puts MCP, A2A and REST/gRPC APIs behind one endpoint, with central governance, discovery and observability. It also acts as a standard MCP server ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- Python 3.11+. Ships as a PyPI package, a container image, Helm charts and Ansible ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)). It won't start without `JWT_SECRET_KEY` and `AUTH_ENCRYPTION_SECRET` ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- It has no pre-built SaaS catalog. Instead it wraps your own REST/gRPC APIs as MCP tools. Auth includes user-scoped OAuth tokens and `X-Upstream-Authorization` header support. There are 40+ plugins, OpenTelemetry tracing, and support for air-gapped deployment ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).
- Latest release v1.1.0 (2026-10-20). 4,769 stars. Repo created 2025-05-08 ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)).

### Activepieces: connector catalog and automation (MIT core plus paid EE)

- Describes itself as "an open source replacement for Zapier". Contributed TypeScript "pieces" automatically become MCP servers. The repo cites about 400 MCP servers ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)). The pricing page says "770+ integrations" ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)); the findings treat ~400 as the conservative figure ([findings](./findings.md#conflicting-sources)).
- Recommended self-host is Docker Compose with PostgreSQL and Redis. There is a Helm chart for Kubernetes. Community one-click templates install the free Community edition and can lag behind ([Activepieces install docs](../../external-sources/composio-alternatives-activepieces-install.md)).
- 25,437 stars, 380 releases ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)).

### Docker MCP Gateway: containerised MCP servers behind one endpoint (MIT)

- A `docker mcp` CLI plugin written in Go. Each MCP server runs in its own isolated container with minimal host privileges, behind one gateway. It works with or without Docker Desktop ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- Servers come from the OCI-based Docker MCP Catalog (default image `mcp/docker-mcp-catalog`), OCI image refs, MCP Registry refs or local files. You can build your own catalog with `docker mcp catalog create` ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- Has built-in OAuth flows for MCP servers that need OAuth tokens ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)). v0.40.4 fixed problems in the OAuth callback server ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)).
- Latest release v0.44.3 (2026-10-26). The CI check on that day's merge commit shows as failed ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)).

### Screened out

MetaMCP (no release in about 11 months) and Arcade arcade-mcp (no self-hostable auth engine established) are on the watch list. Nango, Metorial and n8n fail the OSI check, and Klavis was archived on 2026-11-05 ([sources.md](./sources.md), [license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## Trade-offs

Nothing was measured. Everything below comes from the sources and was not tested.

### Parity matrix against Composio

Legend: ✅ present per source · ⚠️ partial or do-it-yourself · ❌ absent or not stated. The matrix is reproduced from [findings](./findings.md#feature-parity-matrix-vs-composio), where each cell is backed by a FACT line with its source. The Composio column comes from the [Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md).

| Capability | Composio | ContextForge | Activepieces (self-host Community) | Docker MCP Gateway |
|---|---|---|---|---|
| Pre-built SaaS connector catalog | ✅ 1000+ toolkits | ❌ none stated; wrap your own REST/gRPC | ✅ ~400 pieces as MCP servers (770+ in marketing copy) | ⚠️ Docker MCP Catalog plus OCI/registry/local refs; size unverified |
| Managed OAuth (consent, token refresh) | ✅ | ⚠️ user-scoped OAuth tokens plus OBO hook; per-app setup and refresh are DIY | ⚠️ connections model; global connections need Team tier; per-user OAuth not described | ⚠️ built-in OAuth flows; local secrets, no vault stated |
| Per-user / multi-tenant sessions | ✅ `user_id` sessions | ⚠️ user-scoped tokens, no connected-account store shown | ❌ not described | ❌ single-tenant workstation shape (opinion) |
| MCP endpoint | ✅ | ✅ multi-transport MCP server | ✅ pieces exposed as MCP servers | ✅ single endpoint; stdio/sse/streaming |
| Native agent-framework adapters | ✅ OpenAI Agents, Claude Agent SDK, Vercel AI SDK, LangChain and others | ⚠️ A2A plus OpenAI-compatible/Anthropic routing | ❌ MCP plus API/SDK only | ❌ MCP only |
| Triggers / event automation | ✅ | ❌ not stated | ✅ flows engine (core product) | ❌ not stated |
| Sandbox / code execution | ✅ | ❌ not stated | ❌ not stated | ⚠️ container isolation of servers, not a code sandbox |
| Governance (RBAC, audit, policy) | not assessed | ✅ guardrails, plugins, rate limits, OTel | ❌ in Community; SSO/RBAC/audit are paid | ❌ none stated |
| Self-host, OSI license end to end | ❌ hosted backend (unverified) | ✅ Apache-2.0 | ⚠️ MIT core; EE directories need a subscription in production | ✅ MIT |

### License caveats

- **ContextForge:** Apache-2.0. The fetched pages show no open-core split ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)).
- **Activepieces is open-core.** The `ee/` directories need a valid enterprise subscription for production use (dev and test are allowed). The rest is MIT ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md)). Features you only get on paid plans ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)):
  - **Team ($200/month flat):** SSO, standard roles, global connections, unlimited projects.
  - **Ultimate (custom pricing):** SCIM, custom RBAC, secret managers, audit logs, event streaming, private pieces, releases and Git Sync, priority execution, branding, platform governance.
  - All tiers can be hosted in the cloud or on-prem.
- **Docker MCP Gateway:** MIT, copyright 2025 Docker ([Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)). The secret handling described is local, through Docker Desktop. No hosted credential vault is shown ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md)).
- **Composio itself:** the SDK is MIT, but that says nothing about the hosted backend's license or whether it can be self-hosted ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)).
- **Excluded near-matches:** Nango's ELv2 says "You may not provide the software to third parties as a hosted or managed service". Metorial's FSL-1.1-ALv2 bars Competing Use until it converts to Apache-2.0, and the conversion delay is unverified ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)).

## How to use

How to migrate off Composio, by use case. This is the findings' migration path, an opinion grounded in the facts above ([findings](./findings.md#migration-path)). None of it was tested.

1. **You only need an MCP endpoint** (your tools are already MCP servers or internal APIs): stand up ContextForge or Docker MCP Gateway, then point agent clients at the gateway instead of Composio's `session.mcp.url` ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)).
2. **You need connector breadth:** self-host Activepieces (Compose with PostgreSQL and Redis) ([Activepieces install docs](../../external-sources/composio-alternatives-activepieces-install.md)), rebuild the Composio toolkits you use as pieces, and give agents access through its MCP servers. Budget for Team if you need SSO or global connections ([Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)).
3. **You need per-user OAuth:** this is the biggest gap. ContextForge's OBO hook is the only primitive that ships ([ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)). Otherwise you build a token vault yourself (opinion).

The preserved sources don't include step-by-step install commands for any of the three, so none are reproduced here.

## Examples

No PoC exists for this topic, so there are no run examples.

## Conclusion / Recommendation

**Tentative.** This is a document review only; nothing was installed. Pick by use case:

| Use case | Fit | Why |
|---|---|---|
| Govern and federate internal APIs and MCP servers for agents | **ContextForge** | Apache-2.0, governance and observability, REST/gRPC wrapping, OBO hook ([ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md), [ContextForge repo](../../external-sources/composio-alternatives-contextforge.md)) |
| Wide range of business-SaaS connectors and automations | **Activepieces** (self-host) | The only OSI-core catalog. Plan for Team or Ultimate if you need SSO, audit or global connections ([Activepieces repo](../../external-sources/composio-alternatives-activepieces.md), [Activepieces pricing](../../external-sources/composio-alternatives-activepieces-pricing.md)) |
| Developer workstations: isolated tool servers, one clean MCP endpoint | **Docker MCP Gateway** | MIT, a container per server, frequent releases ([Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md), [Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md)) |
| Per-user managed OAuth at scale is a hard requirement | **None of the three.** Stay on Composio, or reopen Nango/Metorial if license policy allows | The closest functional matches are non-OSI ([license evidence](../../external-sources/composio-alternatives-license-exclusions.md)) |

The realistic end state is a mix: Activepieces as the catalog behind ContextForge for governance, with Docker MCP Gateway on dev machines (opinion, from [findings](./findings.md#tentative-recommendation)).

What could change this:

- An answer to the per-user OAuth questions below.
- A PoC showing the Activepieces-behind-ContextForge combination doesn't work.

## Gaps

### Residual open questions (block the per-user OAuth decision)

1. **Activepieces:** does self-hosted Community support per-end-user OAuth delegation (Composio-style connected accounts), or only owner-level connections? The fetched sources don't describe it ([findings](./findings.md#open-questions)).
2. **ContextForge:** what do the 40+ plugins cover? Is there a plugin for storing SaaS OAuth tokens on top of the OBO hook? The README capture is partial, roughly 15k of 40.7k characters ([findings](./findings.md#open-questions), [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md)).

### Other unknowns recorded in findings

These don't change the use-case fit, but they are still unverified ([findings](./findings.md#open-questions)):

- The size of the Docker MCP Catalog, and how many of its servers support OAuth.
- Whether Composio has a self-host or VPC option.
- When Metorial's license converts from FSL to Apache-2.0.

### Owners

- **res-researcher:** the two residual questions; Docker catalog size; Metorial conversion date.
- **res-lab:** none this round (the owner said no PoC). If one is wanted later, the Activepieces-behind-ContextForge combination is the one to test.
- **Owner:**
  - Is per-user OAuth a hard requirement? If yes, the answer is "stay on Composio or revisit non-OSI licenses".
  - Is a PoC wanted?

## Sources and versions

All fetched 2026-11-10.

- [Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md): SDK monorepo, MIT, 1,214 releases.
- [IBM ContextForge repo](../../external-sources/composio-alternatives-contextforge.md): v1.1.0 (2026-10-20). Also the [ContextForge README](../../external-sources/composio-alternatives-contextforge-readme.md), a partial capture.
- [Activepieces repo](../../external-sources/composio-alternatives-activepieces.md): 0.92.3 line (dates unverified, per [sources.md](./sources.md)). Also the [pricing](../../external-sources/composio-alternatives-activepieces-pricing.md) and [install docs](../../external-sources/composio-alternatives-activepieces-install.md).
- [Docker MCP Gateway repo](../../external-sources/composio-alternatives-docker-mcp-gateway.md): v0.44.3 (2026-10-26). Also the [Docker MCP README](../../external-sources/composio-alternatives-docker-mcp-gateway-readme.md).
- [License evidence for excluded candidates](../../external-sources/composio-alternatives-license-exclusions.md): Nango, Metorial, n8n, Klavis.

## Related

- [Sources (screen)](./sources.md)
- [Findings](./findings.md)
- PoC: none (the owner said a PoC is not needed).
