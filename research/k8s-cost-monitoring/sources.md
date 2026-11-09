---
type: research-note
status: draft
title: Kubernetes cost monitoring — candidate sources
description: Screen of open-source Kubernetes cost-monitoring tools with health signals and 3 selected.
date: 2026-11-09
cluster: k8s-cost-monitoring
tags:
  - k8s-cost-monitoring
  - research
  - sources
sources:
  - resource: ../../external-sources/k8s-cost-monitoring-opencost-readme.md
  - resource: ../../external-sources/k8s-cost-monitoring-opencost-cncf.md
  - resource: ../../external-sources/k8s-cost-monitoring-krr-readme.md
  - resource: ../../external-sources/k8s-cost-monitoring-goldilocks-readme.md
  - resource: ../../external-sources/k8s-cost-monitoring-kepler-repo.md
  - resource: ../../external-sources/k8s-cost-monitoring-kubecost-chart.md
---

## Scope

Screen of open-source (OSI-licensed) Kubernetes cost-monitoring tools for RESEARCH-7, screened 2026-11-09. Screen only: no PoC, no architecture analysis. Owner constraints: open source only, exactly 3 selected. Commit activity is `unverified` for all candidates (no commit graph read); release cadence is the proxy. Downstream docs `findings.md` and `report.md` do not exist yet.

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| **OpenCost** (SELECTED) | Cost allocation by cluster/node/namespace/pod plus cloud costs, Prometheus export | v1.121.3, 2026-09-16; pricing module v1.0.9, 2026-10-13 | unverified; 5,166 commits, 186 open issues, 194 open PRs | CNCF project, 1,568 contributors / 501 orgs (LFX) | Apache-2.0 | CNCF Incubating since 2024-10-25; LFX health 73 "Healthy"; 780 stars (-18% YoY) | dig deeper | Selected: the only candidate that does real cost allocation, vendor-neutral and CNCF-governed. | [README + tags](../../external-sources/k8s-cost-monitoring-opencost-readme.md), [CNCF page](../../external-sources/k8s-cost-monitoring-opencost-cncf.md) |
| **Robusta KRR** (SELECTED) | CLI that recommends CPU/memory requests and limits from Prometheus data | v1.31.3, 2026-11-04 | unverified; 749 commits, 101 open issues, 48 open PRs | Robusta (vendor-led) | MIT | stars unverified; releases v1.29.0 to v1.30.x had broken builds per v1.31.3 notes | dig deeper | Selected: agentless right-sizing on existing Prometheus, complements allocation tools. Caveat: UI and explainability are Robusta SaaS. | [README + release](../../external-sources/k8s-cost-monitoring-krr-readme.md) |
| **Goldilocks** (SELECTED) | Creates VPAs in recommendation mode per workload, shows a dashboard of request suggestions | v4.16.3, 2026-11-03 | unverified; 454 commits | Fairwinds (vendor-led) | Apache-2.0 | stars unverified | dig deeper | Selected: lightweight in-cluster right-sizing view built on the standard VPA. Caveat: multi-cluster and history need commercial Fairwinds Insights. | [README + tags](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md) |
| **Kubecost (helm chart)** | Commercial product that spawned OpenCost; free tier via the chart | v3.3.1, 2026-10-14 | unverified; 3,846 commits, latest 2026-11-04 | Kubecost (vendor) | Chart repo shows Apache-2.0; product image/free-tier terms unverified | 674 stars, 433 forks | watch | Not selected: overlaps OpenCost, and the free tier is a vendor product whose OSI status is unverified. | [repo + tags](../../external-sources/k8s-cost-monitoring-kubecost-chart.md) |
| **Kepler** | CNCF Sandbox power meter: per-workload energy use | v0.13.0, 2026-11-06 | unverified; 895 commits, latest 2026-11-06 | sustainable-computing-io community | Apache-2.0 | CNCF Sandbox; 1.6k stars, 288 forks | skip | Measures energy, not money; out of scope for cost allocation (revisit if carbon matters). | [repo + tags](../../external-sources/k8s-cost-monitoring-kepler-repo.md) |

Mark any cell you could not verify as `unverified`.

## Selected (exactly 3)

1. **OpenCost**: vendor-neutral CNCF Incubating cost allocation ([source](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)).
2. **Robusta KRR**: agentless, Prometheus-based right-sizing to cut waste, MIT ([source](../../external-sources/k8s-cost-monitoring-krr-readme.md)).
3. **Goldilocks**: VPA-based request recommendations with a dashboard, Apache-2.0 ([source](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).

Not screened (unverified, no sources fetched): other OSS options such as kube-resource-report or kubectl-cost.

## Preserved sources

- [OpenCost README + tags](../../external-sources/k8s-cost-monitoring-opencost-readme.md)
- [OpenCost on CNCF](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)
- [Robusta KRR README + release](../../external-sources/k8s-cost-monitoring-krr-readme.md)
- [Goldilocks README + tags](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)
- [Kepler repo + tags](../../external-sources/k8s-cost-monitoring-kepler-repo.md)
- [Kubecost chart repo + tags](../../external-sources/k8s-cost-monitoring-kubecost-chart.md)
