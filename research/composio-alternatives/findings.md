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

## Core concepts

## Architecture

## Alternatives

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
