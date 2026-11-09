---
author: Kubecost
date_fetched: 2026-11-09
description: kubectl-cost, a kubectl plugin that queries Kubecost (or OpenCost) cost APIs; README, releases and repo API facts.
media_type: text/markdown
preservation: text-extracted
source_url: https://github.com/kubecost/kubectl-cost
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - k8s-cost-monitoring
title: kubectl-cost (README, releases, repo API)
type: source
---
> Facts from the kubectl-cost README (https://raw.githubusercontent.com/kubecost/kubectl-cost/main/README.md), the releases page (https://github.com/kubecost/kubectl-cost/releases) and the GitHub repo API (https://api.github.com/repos/kubecost/kubectl-cost), all read 2026-11-09.

README excerpt: "`kubectl-cost` is a kubectl plugin that provides easy CLI access to Kubernetes cost information, like historical cost and predicted future cost, via Kubecost's APIs. It allows developers, devops, and others to quickly determine the cost & efficiency of any Kubernetes workload."

README note: "If you use OpenCost, most of `kubectl cost` works! See the OpenCost documentation for examples."

README install section: "This software requires that you have a running deployment of Kubecost in your cluster." `kubectl cost predict -f <file>` estimates the cost of undeployed changes starting with Kubecost v1.100.

Repo API: license Apache-2.0, archived false, 1,047 stars, 70 forks, 29 open issues, last push 2026-11-04, latest commit 2026-09-28.

Releases: latest v0.6.6 published 2024-09-26; v0.6.5 published 2024-09-25. v0.6.2 "Patch CVEs". v0.5.0 moved `predict` to Kubecost's `/prediction/speccost` API (Kubecost v1.101).