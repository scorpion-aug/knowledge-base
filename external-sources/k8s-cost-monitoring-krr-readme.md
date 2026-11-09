---
title: Robusta KRR (README and releases)
description: KRR README excerpt (MIT, Prometheus-based resource recommendations) with release v1.31.3 facts.
type: source
source_url: https://raw.githubusercontent.com/robusta-dev/krr/main/README.md
media_type: text/markdown
date_fetched: 2026-11-09
author: Robusta
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - k8s-cost-monitoring
---
> Excerpt (middle omitted by fetcher) plus facts from https://github.com/robusta-dev/krr (License: MIT, 749 commits, created 2023-02-17) and https://github.com/robusta-dev/krr/releases/tag/v1.31.3.

Robusta KRR (Kubernetes Resource Recommender) is a CLI tool that gathers pod usage data from Prometheus and recommends CPU and memory requests and limits. No in-cluster agent required; runs from a laptop or in-cluster. Optional auto-apply via KRR Enforcer. Works with Prometheus, Thanos, VictoriaMetrics, Mimir, Amazon/Azure/Google managed Prometheus, Coralogix, Grafana Cloud. Requires Prometheus 2.26+, kube-state-metrics and cAdvisor. Output formats: JSON, CSV, Markdown, Web UI. Some features (UI, explainability graphs, HolmesGPT agentic savings) are on the Robusta SaaS platform. The README cites a Sysdig study (69% unused CPU, 18% unused memory) and claims 69% average savings (vendor claim).

Latest release: v1.31.3, published 2026-11-04 by RoiGlinik; fixes release builds (retired macos-13 runner, crashing binaries since v1.30.0, Homebrew update chain). The notes say every release since v1.29.0 hung and the Homebrew formula was still on v1.28.0. Earlier tags: v1.31.2 (drops Pillow, CVE fixes), v1.28.0 (CVE patches), v1.27.0 (grouped jobs, Prometheus credential refresh). Issues 101 open, PRs 48 open.
