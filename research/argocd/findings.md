---
title: "<Topic> — findings"
description: "Concepts, architecture and trade-offs for <topic>."
type: research-note
status: draft
date: 2026-11-03
author: res-researcher
cluster: <topic>
tags: [research, provisional, research-team, findings, <topic>]
sources: []
---

## Question

Should Argo CD or Flux v2 be the GitOps core (reconciler) for Kubernetes delivery, and is Kargo the right layer on top for stage-to-stage promotion? Sub-question: which image-update mechanism fits: Argo CD Image Updater, Flux image automation, or Kargo?

**Rubric (headless, auto-confirmed 2026-11-03):**

1. Problem solved and core concepts (Application / ApplicationSet vs Kustomization / HelmRelease vs Stage / Freight / Warehouse)
2. Architecture: components, where state lives, UI, multi-cluster model
3. ApplicationSet (generators, multi-cluster, security caveats), covered inside Argo CD
4. Image-update options compared: Argo CD Image Updater vs Flux image automation vs Kargo
5. Current release deltas: Argo CD 3.6 (RC), Flux v2.10
6. Trade-offs: operating cost, lock-in, governance, migration path

**Success criteria:** every FACT cites a local `external-sources/` doc; OPINION lines are labeled; conflicts and unknowns are explicit; PoC requests have a success criterion and pinned versions.

## Context

res-scout screened six candidates in [sources](./sources.md). Argo CD, Flux and Kargo got dig deeper; Argo Rollouts, ApplicationSet and Image Updater got watch. This doc informs one decision: which GitOps core to adopt, and whether to add a promotion layer. Readers are platform engineers. Sources are dated 2026-11-03 unless noted.

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
