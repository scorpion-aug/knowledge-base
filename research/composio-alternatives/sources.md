---
type: research-note
status: draft
title: Composio alternatives — candidate sources
description: Screen of self-hostable OSI-licensed alternatives to Composio with health signals, verdicts and 3 selected.
date: 2026-11-10
cluster: composio-alternatives
tags:
  - composio-alternatives
  - research
  - sources
sources:
  - resource: ../../external-sources/composio-alternatives-composio-baseline.md
  - resource: ../../external-sources/composio-alternatives-contextforge.md
  - resource: ../../external-sources/composio-alternatives-activepieces.md
  - resource: ../../external-sources/composio-alternatives-docker-mcp-gateway.md
  - resource: ../../external-sources/composio-alternatives-metamcp.md
  - resource: ../../external-sources/composio-alternatives-arcade-mcp.md
  - resource: ../../external-sources/composio-alternatives-license-exclusions.md
---

## Scope

Screen of self-hostable, OSI-licensed alternatives to Composio for RESEARCH-10, screened 2026-11-10: agent connector catalogs, credential/OAuth handling for tools, and MCP gateways. Screen only (no PoC, no deep comparison). Commit activity is `unverified` unless noted; release cadence is the proxy. Downstream docs `findings.md` and `report.md` do not exist yet.

### Composio baseline

Composio is a hosted platform plus MIT-licensed SDKs: it offers 1000+ pre-authenticated toolkits, per-user sessions, authentication (OAuth and connected accounts), triggers and a sandbox, exposed either as native tools for agent frameworks or through an MCP endpoint ([Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)). The SDK is MIT, but the quickstart needs a `COMPOSIO_API_KEY` from the hosted dashboard, and the fetched pages do not show a self-hostable backend (unverified) ([same source](../../external-sources/composio-alternatives-composio-baseline.md)).

**Key finding for the owner:** the closest functional matches to Composio (a large catalog plus managed OAuth and token refresh) are Nango and Metorial, and neither passes the OSI check. See the exclusions table. Among OSI-licensed projects, the matches are partial: gateways (ContextForge, Docker MCP Gateway, MetaMCP) cover routing and governance, and Activepieces covers a connector catalog.

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| **IBM ContextForge** (SELECTED) | Registry and gateway federating MCP, A2A and REST/gRPC APIs with governance, plugins, observability | v1.1.0, 2026-10-20 | unverified; tags every 1-3 weeks in Sep-Oct 2026 | IBM | Apache-2.0 | 4,769 stars, 963 forks, 30 releases | dig deeper | Selected: best self-hosted MCP gateway with auth/OBO token-exchange plugin hooks and governance. Caveat: gateway only, no pre-built SaaS connector catalog stated. | [ContextForge](../../external-sources/composio-alternatives-contextforge.md) |
| **Activepieces** (SELECTED) | Open-source Zapier alternative; TypeScript pieces auto-exposed as MCP servers (~400 cited) | 0.92.3 line (hotfixes); dates unverified | unverified | Activepieces Inc. | MIT core; `ee/` directories under a paid enterprise license (**open-core**) | 25,437 stars, 4,445 forks, 380 releases | dig deeper | Selected: the only OSI-core candidate with a real connector catalog. Flag for res-researcher: EE features are paid-only (which ones: unverified). | [Activepieces](../../external-sources/composio-alternatives-activepieces.md) |
| **Docker MCP Gateway** (SELECTED) | `docker mcp` CLI plugin / gateway that runs MCP servers as containers behind one endpoint, with OAuth handling for MCP servers | v0.44.3, 2026-10-26 | latest commit 2026-10-26 (CI check on that commit shown as failure); 1,063 commits | Docker | MIT | 74 tags; stars unverified | dig deeper | Selected: vendor-backed, frequent releases, containerised isolation of tool servers. Caveat: SaaS credential vault scope unverified. | [Docker MCP Gateway](../../external-sources/composio-alternatives-docker-mcp-gateway.md) |
| **MetaMCP** | Self-hosted MCP aggregator/orchestrator/middleware in one Docker image | v2.4.22, 2025-12-10 | latest commit 2026-06-22 (README); 932 commits | metatool-ai, ~15+ contributors | MIT | 70 tags; stars unverified | watch | Useful gateway, but no release in about 11 months; not selected for staleness. | [MetaMCP](../../external-sources/composio-alternatives-metamcp.md) |
| **Arcade arcade-mcp** | MIT framework for building MCP tools; Arcade's hosted platform handles agent auth | no tags listed (unverified) | latest commit 2026-11-09; 749 commits | Arcade AI | MIT (framework only) | stars unverified | watch | Active, but a tool-authoring framework; self-hostable auth engine not established. Revisit if the OAuth engine is shown to be open. | [arcade-mcp](../../external-sources/composio-alternatives-arcade-mcp.md) |

### Excluded: fail the OSI check or archived

| Candidate | Why excluded | Sources |
|---|---|---|
| Nango | Elastic License 2.0 (not OSI): bars offering it as a hosted/managed service. Otherwise the closest functional match (managed OAuth, proxy, 1,000+ APIs, v0.72.2 on 2026-11-05). | [license evidence](../../external-sources/composio-alternatives-license-exclusions.md) |
| Metorial | FSL-1.1-ALv2 (not OSI until it converts; bars Competing Use). README says the Catalog is Apache-2.0. No GitHub releases. | [license evidence](../../external-sources/composio-alternatives-license-exclusions.md) |
| n8n | Sustainable Use License plus enterprise license (not OSI). | [license evidence](../../external-sources/composio-alternatives-license-exclusions.md) |
| Klavis | Apache-2.0 but deprecated and archived by owner on 2026-11-05. | [license evidence](../../external-sources/composio-alternatives-license-exclusions.md) |

Mark any cell you could not verify as `unverified`.

## Selected (3)

1. **IBM ContextForge**: Apache-2.0 gateway with governance and token-exchange plugin hooks, actively released ([source](../../external-sources/composio-alternatives-contextforge.md)).
2. **Activepieces**: MIT-core connector catalog exposed as MCP servers; open-core, so check paid-only features ([source](../../external-sources/composio-alternatives-activepieces.md)).
3. **Docker MCP Gateway**: MIT, Docker-backed, container-isolated MCP servers with frequent releases ([source](../../external-sources/composio-alternatives-docker-mcp-gateway.md)).

Only 3 of the 3-5 allowed were selected; the rest fail on licence, freshness or fit. Not screened (no sources fetched): other OSS MCP gateways and connector projects.

## Preserved sources

- [Composio baseline](../../external-sources/composio-alternatives-composio-baseline.md)
- [IBM ContextForge](../../external-sources/composio-alternatives-contextforge.md)
- [Activepieces](../../external-sources/composio-alternatives-activepieces.md)
- [Docker MCP Gateway](../../external-sources/composio-alternatives-docker-mcp-gateway.md)
- [MetaMCP](../../external-sources/composio-alternatives-metamcp.md)
- [arcade-mcp](../../external-sources/composio-alternatives-arcade-mcp.md)
- [License evidence for excluded candidates](../../external-sources/composio-alternatives-license-exclusions.md)
