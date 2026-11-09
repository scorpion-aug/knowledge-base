---
title: OpenCost (README and tags)
description: OpenCost README (Apache-2.0, Kubernetes and cloud cost monitoring) plus latest tags from the GitHub tags page.
type: source
source_url: https://raw.githubusercontent.com/opencost/opencost/develop/README.md
media_type: text/markdown
date_fetched: 2026-11-09
author: OpenCost maintainers
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - k8s-cost-monitoring
---
> Excerpt of the develop-branch README (middle omitted by fetcher) plus tag facts from https://github.com/opencost/opencost/tags and repo page (License: Apache-2.0, 5,166 commits, default branch develop, created 2019-03-27).

OpenCost gives teams visibility into current and historical Kubernetes and cloud spend and resource allocation. Originally developed and open sourced by Kubecost; a specification plus a Golang implementation. UI lives in opencost/opencost-ui.

Features listed: real-time cost allocation by cluster, node, namespace, controller, service or pod; multi-cloud cost monitoring (AWS, Azure, GCP); on-prem custom CSV pricing; CPU/GPU/memory/PV allocation; Prometheus /metrics export; carbon costs; MCP server (opt-in); AI inference cost tracking for vLLM-based deployments; external costs via OpenCost Plugins; Apache-2.0.

Install: Helm chart only (`helm repo add opencost https://opencost.github.io/opencost-helm-chart`; `helm install opencost opencost/opencost`), Kubernetes 1.20+. Standalone manifests were removed. Needs Prometheus; sharded Prometheus needs a global query endpoint.

Community: CNCF Slack #opencost; biweekly working group meeting. OpenSSF Best Practices badge present.

Tags (GitHub tags page, fetched 2026-11-09):

- v1.121.3: Sep 16, 2026 (latest core release tag)
- modules/pricing/public/v1.0.9: Oct 13, 2026 (pricing module; adds GBP/EUR/JPY)
- modules/pricing/public/v1.0.6 and v1.0.5: Oct 2, 2026
- Issues 186 open, pull requests 194 open (tab counts on tags page)
