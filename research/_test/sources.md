---
title: "_test (kubernetes-gitops-tools) — candidate sources"
description: "Dry-test screen of 3 Kubernetes GitOps tools (Argo CD, Flux, Kargo) with health signals and verdicts."
type: research-note
status: draft
date: 2026-11-03
author: res-scout
cluster: _test
tags: [ research, provisional, research-team, sources, _test, kubernetes-gitops-tools, gitops, kubernetes ]
sources: []
---

## Scope

Dry test of the research team setup. Theme: kubernetes-gitops-tools. Screened exactly 3 candidates: Argo CD, Flux, and one emerging tool (Kargo, chosen as a promotion-orchestration layer built on GitOps). Search/fetch date: 2026-11-03. Signals taken from GitHub repo and releases pages; star counts are a point-in-time snapshot. Links below are bare URLs = TODO citations (ingest skipped for this dry test).

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| Argo CD | Declarative, pull-based GitOps continuous delivery controller + UI for Kubernetes | v3.5.7, 2026-11-02 | Active: 1,018 commits on master since v3.5.7 tag (GitHub release page, 2026-11-03) | MAINTAINERS.md + CODEOWNERS present; count unverified | Apache-2.0 | ~24.4k stars, ~8.0k forks; USERS.md present; CNCF status unverified | dig deeper | De-facto standard GitOps CD with very active releases; baseline for comparison | repo https://github.com/argoproj/argo-cd (fetched 2026-11-03); release https://github.com/argoproj/argo-cd/releases/tag/v3.5.7 (2026-11-02) |
| Flux | GitOps Toolkit: set of controllers (source, kustomize, helm, notification, image) for continuous delivery on Kubernetes | v2.10.0, 2026-10-26 (feature release) | Active: feature release with 25+ contributors listed; commit cadence unverified | MAINTAINERS file present; count unverified | Apache-2.0 | ~8.5k stars, ~0.8k forks; CNCF status unverified | dig deeper | Main alternative to Argo CD; v2.10 adds SPIFFE mTLS, OCIRepository as HelmRelease chart source | repo https://github.com/fluxcd/flux2 (fetched 2026-11-03); release https://github.com/fluxcd/flux2/releases/tag/v2.10.0 (2026-10-26) |
| Kargo (emerging) | Akuity's application lifecycle / promotion orchestration across stages, built on GitOps principles (pairs with Argo CD) | v1.12.5, 2026-10-27 (patch) | Active: frequent backport patch releases; 243 releases since 2022-07-14 | Vendor-led (Akuity); CODEOWNERS present; count unverified | Apache-2.0 | ~3.7k stars, ~0.5k forks; production adoption unverified | watch | Fills the multi-stage promotion gap but single-vendor; revisit after Argo CD/Flux comparison | repo https://github.com/akuity/kargo (fetched 2026-11-03); release https://github.com/akuity/kargo/releases/tag/v1.12.5 (2026-10-27) |

Mark any cell you could not verify as `unverified`.

## Preserved sources

Ingest skipped for the dry test: no files written to `external-sources/`. In a real run, Argo CD and Flux (dig deeper) would get repo README + latest release notes captured as `external-sources/_test-argo-cd-*.md` and `external-sources/_test-flux-*.md`. Until then, all URLs in the table count as TODO citations.

## Related

- Findings: not created in this dry test (would be research/_test/findings.md, owned by res-researcher)
- Report: not created in this dry test (would be research/_test/report.md, owned by res-writer)
