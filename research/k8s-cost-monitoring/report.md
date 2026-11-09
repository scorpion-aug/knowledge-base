---
title: Kubernetes cost monitoring — report
description: Screen-level comparison of OpenCost, Robusta KRR and Goldilocks with a tentative recommendation.
type: research-note
status: draft
date: 2026-11-09
author: res-writer
cluster: k8s-cost-monitoring
tags:
  - research
  - provisional
  - research-team
  - report
  - k8s-cost-monitoring
sources:
  - resource: ../../external-sources/k8s-cost-monitoring-opencost-readme.md
  - resource: ../../external-sources/k8s-cost-monitoring-opencost-cncf.md
  - resource: ../../external-sources/k8s-cost-monitoring-krr-readme.md
  - resource: ../../external-sources/k8s-cost-monitoring-goldilocks-readme.md
---
> **Draft, screen level only.** Built from [sources.md](./sources.md) and the preserved sources it cites. This topic has no findings.md and no PoC (the owner said a PoC is not needed), so nothing here was installed or measured. Every fact below comes from a project README, tag page or the CNCF page, all fetched 2026-11-09. Open items are under [Gaps](#gaps).

## Problem

We want open-source tooling that answers two questions about our Kubernetes clusters: *what does each team or workload cost?* and *where are we paying for capacity we don't use?* The screen in [sources.md](./sources.md) shortlisted exactly three OSI-licensed tools: OpenCost, Robusta KRR and Goldilocks. This report compares them and recommends how to combine them.

**The most important point:** these three tools don't do the same job.

- **Only OpenCost tracks and allocates costs.** It reports current and historical Kubernetes and cloud spend and splits it by cluster, node, namespace, controller, service or pod ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
- **KRR and Goldilocks don't track costs.** They recommend CPU and memory settings for workloads. KRR recommends requests and limits from Prometheus usage data ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)). Goldilocks shows request recommendations from VPAs it creates ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)). Neither preserved source says the tool reports spend in money. Right-sizing can lower the bill, but only OpenCost shows the bill.

So this is less a "pick one" choice than "cost visibility (OpenCost) plus, optionally, one right-sizing tool (KRR or Goldilocks)".

## Concepts

The definitions below are standard Kubernetes background; the preserved sources use these terms but do not define them (TODO: needs source, e.g. ingest the Kubernetes docs pages on resource management and VPA).

- **Requests and limits:** per-container CPU/memory settings. A *request* is what the scheduler reserves for the container on a node; a *limit* is the most it may use. Requests set far above real usage reserve node capacity that sits idle, and you still pay for those nodes.
- **Right-sizing:** changing requests/limits to match observed usage. KRR and Goldilocks produce right-sizing recommendations.
- **Cost allocation:** splitting the cluster and cloud bill across Kubernetes objects (namespace, pod, controller and so on) so you can charge teams back or show them their costs. This is what OpenCost does ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
- **Prometheus:** the metrics system that OpenCost needs and exports to ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)), and that KRR reads usage history from ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)). **kube-state-metrics** and **cAdvisor** are the exporters that publish object state and container usage into it. KRR requires both ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)).
- **VPA (Vertical Pod Autoscaler):** a Kubernetes add-on that computes request recommendations for a workload. In *recommendation mode* it only suggests values and does not apply them. Goldilocks creates one such VPA for each workload in a namespace ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).
- **CNCF Incubating:** the middle maturity level of the Cloud Native Computing Foundation, between Sandbox and Graduated. OpenCost is at this level ([CNCF page](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)).

## Options

### OpenCost: cost allocation (tracks costs)

- Visibility into current and historical Kubernetes and cloud spend and resource allocation. It's a specification plus a Go implementation, originally developed and open-sourced by Kubecost. The UI is a separate repo, opencost/opencost-ui ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
- Features listed: real-time allocation by cluster, node, namespace, controller, service or pod; multi-cloud cost monitoring for AWS, Azure and GCP; custom CSV pricing for on-prem; CPU/GPU/memory/PV allocation; Prometheus `/metrics` export; carbon costs; an opt-in MCP server; AI inference cost tracking for vLLM deployments; external costs via OpenCost Plugins ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
- Deployment: Helm chart only (standalone manifests were removed), Kubernetes 1.20+, requires Prometheus. A sharded Prometheus needs a global query endpoint ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
- Governance: CNCF project since 2022-06-17, Incubating since 2024-10-25 ([CNCF page](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)).

### Robusta KRR: right-sizing CLI (recommends settings, no cost tracking)

- CLI that reads pod usage from Prometheus and recommends CPU and memory requests and limits. No in-cluster agent is needed: it runs from a laptop or in the cluster. Optional auto-apply through KRR Enforcer ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)).
- Metrics backends: Prometheus, Thanos, VictoriaMetrics, Mimir, Amazon/Azure/Google managed Prometheus, Coralogix, Grafana Cloud. Requires Prometheus 2.26+, kube-state-metrics and cAdvisor ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)).
- Output: JSON, CSV, Markdown, Web UI. The UI, explainability graphs and HolmesGPT "agentic savings" are on the Robusta SaaS platform, not in the OSS CLI ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)).

### Goldilocks: VPA-based recommendation dashboard (recommends settings, no cost tracking)

- Helps find a starting point for requests and limits. It creates a VPA in recommendation mode for each workload in a namespace and shows the results in a dashboard ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).
- Images moved from quay.io to `us-docker.pkg.dev/fairwinds-ops/oss/goldilocks` from v4.15.0. Images are signed and tags are immutable ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).
- Multi-cluster views, history and integrations are in the commercial Fairwinds Insights product, not in Goldilocks ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).

### Not covered

Kubecost (marked "watch" because the license of its free-tier product is unverified) and Kepler ("skip": it measures energy, not money) were screened out. The reasons are in [sources.md](./sources.md).

## Trade-offs

Nothing was measured in a PoC. Everything below comes from the sources and was not tested.

### Comparison table

| | OpenCost | Robusta KRR | Goldilocks |
|---|---|---|---|
| **What it does** | Cost allocation and spend tracking | CPU/memory request and limit recommendations | Request recommendations via VPA, plus a dashboard |
| **Tracks costs in money?** | **Yes** | No | No |
| **License** | Apache-2.0 | MIT | Apache-2.0 |
| **Latest release (checked 2026-11-09)** | v1.121.3 (2026-09-16); pricing module v1.0.9 (2026-10-13) | v1.31.3 (2026-11-04) | v4.16.3 (2026-11-03) |
| **Maintainer / governance** | CNCF Incubating; 1,568 contributors, 501 orgs (LFX) | Robusta (vendor-led) | Fairwinds (vendor-led) |
| **Health signals** | LFX health score 73 "Healthy"; 780 stars (-18% YoY); 186 open issues, 194 open PRs; 5,166 commits | 749 commits; 101 open issues, 48 open PRs; release builds broken from v1.29.0 to v1.30.x, fixed in v1.31.3 | 454 commits; regular tags (v4.16.0 to v4.16.3, Aug to Nov 2026) |
| **Deployment model** | In-cluster, Helm chart only, Kubernetes 1.20+ | CLI, no agent; laptop or in-cluster | In-cluster; creates VPA objects per workload |
| **Data sources** | Prometheus, plus cloud pricing for AWS/Azure/GCP, custom CSV pricing for on-prem, plugins for external costs | Prometheus-compatible backend, kube-state-metrics, cAdvisor | VPA recommendations |
| **Paid upsell for** | none stated in the source | UI, explainability graphs, HolmesGPT (Robusta SaaS) | multi-cluster, history, integrations (Fairwinds Insights) |
| **Sources** | [README](../../external-sources/k8s-cost-monitoring-opencost-readme.md), [CNCF](../../external-sources/k8s-cost-monitoring-opencost-cncf.md) | [README](../../external-sources/k8s-cost-monitoring-krr-readme.md) | [README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md) |

Commit activity is `unverified` for all three: the screen counted commits but didn't read commit graphs ([sources.md](./sources.md)).

### Caveats per tool

- **OpenCost:** stars are down 18% year over year while forks are up 60% and contributors up 6% ([CNCF page](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)). The core release tag (2026-09-16) is older than the pricing-module tag (2026-10-13) ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)). Requires Prometheus, so it adds to that stack's load (load impact unverified).
- **KRR:** the v1.31.3 notes say every release since v1.29.0 hung, binaries crashed from v1.30.0, and the Homebrew formula was stuck on v1.28.0 ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)). Pin a version you have tested. The README's "69% average savings" is a vendor claim, and the Sysdig figures it cites (69% unused CPU, 18% unused memory) are second-hand ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md)).
- **Goldilocks:** it depends on VPA recommendations. Whether the VPA recommender must be installed separately isn't stated in the preserved excerpt (`unverified`). Recommendations are per namespace, and the OSS version has no multi-cluster view or history ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).

### KRR vs Goldilocks (opinion, based on the sources above)

- Pick **KRR** if you already run Prometheus with kube-state-metrics and cAdvisor and want reports you can run on demand or script (CSV/JSON) without installing anything in the cluster.
- Pick **Goldilocks** if you want a standing in-cluster dashboard that teams can browse per namespace and you are comfortable running VPA.

## How to use

The only install steps in the preserved sources are OpenCost's. They come from its README and were **not run** by this team ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)):

```bash
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm install opencost opencost/opencost
```

Prerequisites from the same README: Kubernetes 1.20+ and a reachable Prometheus (a global query endpoint if Prometheus is sharded).

Install steps for KRR and Goldilocks aren't in the preserved excerpts, so they're left out here rather than guessed (see [Gaps](#gaps)).

## Examples

No PoC exists for this topic, so there are no run examples. The commands under [How to use](#how-to-use) are quoted from the OpenCost README, not from a recorded run.

## Conclusion / Recommendation

**Tentative.** Screen-level only, nothing installed.

1. **Use OpenCost for cost monitoring.** It is the only one of the three that tracks and allocates costs ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)). It is Apache-2.0 and vendor-neutral under the CNCF at Incubating level ([CNCF page](../../external-sources/k8s-cost-monitoring-opencost-cncf.md)). It covers AWS/Azure/GCP pricing and on-prem CSV pricing ([OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)).
2. **Add one right-sizing tool if you want to cut waste, not just see it.** Default to **KRR**. It needs no agent and reuses the Prometheus that OpenCost already needs ([KRR README](../../external-sources/k8s-cost-monitoring-krr-readme.md), [OpenCost README](../../external-sources/k8s-cost-monitoring-opencost-readme.md)). Pin v1.31.3 or later because of the broken v1.29 to v1.30 builds. Choose **Goldilocks** instead if teams want a browsable in-cluster dashboard ([Goldilocks README](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md)).
3. Don't present KRR or Goldilocks as "cost monitoring". Their output is resource recommendations. The cost impact only shows up in OpenCost after the changes are applied.

What could change this: a PoC that shows OpenCost's Prometheus load is too high, or that its allocation doesn't match our cloud bill; or a KRR release that breaks again.

## Gaps

Owned by **res-researcher** (findings, not yet done for this topic):

- Install and prerequisites for KRR and Goldilocks (e.g. whether Goldilocks needs a separately installed VPA recommender). The preserved excerpts don't cover them.
- How accurate OpenCost's allocation is against the real cloud bill, how it handles idle and shared costs, and which pricing source it uses for each cloud.
- Whether OpenCost has a commercial upsell or feature split (none is stated in the preserved README).
- Preserved Kubernetes docs for the definitions in [Concepts](#concepts) (requests/limits, VPA).
- Commit activity for all three (currently `unverified`).

Owned by **res-lab** (only if the owner wants a PoC; the owner said none was needed):

- Install OpenCost on a test cluster and record Prometheus resource overhead.
- Run KRR v1.31.3 against the same Prometheus and record the output.

Owner decisions:

- Whether a PoC is wanted before this moves past draft.
- Version pins to adopt (proposed: OpenCost v1.121.3, KRR v1.31.3, Goldilocks v4.16.3).

## Sources and versions

All fetched 2026-11-09.

- [OpenCost README and tags](../../external-sources/k8s-cost-monitoring-opencost-readme.md): core v1.121.3, pricing module v1.0.9.
- [OpenCost on CNCF](../../external-sources/k8s-cost-monitoring-opencost-cncf.md): maturity and LFX Insights figures.
- [Robusta KRR README and releases](../../external-sources/k8s-cost-monitoring-krr-readme.md): v1.31.3.
- [Goldilocks README and tags](../../external-sources/k8s-cost-monitoring-goldilocks-readme.md): v4.16.3.

## Related

- [Sources (screen)](./sources.md)
- Findings: not written for this topic (screen only).
- PoC: none (the owner said a PoC is not needed).
