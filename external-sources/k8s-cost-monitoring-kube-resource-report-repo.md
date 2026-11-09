---
author: Henning Jacobs
date_fetched: 2026-11-09
description: "kube-resource-report (GPL-3.0): static HTML report of requests vs usage and slack cost; GitHub archived, moved to Codeberg."
media_type: text/markdown
preservation: text-extracted
source_url: https://codeberg.org/hjacobs/kube-resource-report
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - k8s-cost-monitoring
title: kube-resource-report (Codeberg and GitHub repo facts)
type: source
---
> Facts from the GitHub repo API (https://api.github.com/repos/hjacobs/kube-resource-report), the GitHub README stub, the Codeberg repo page and API (https://codeberg.org/hjacobs/kube-resource-report, https://codeberg.org/api/v1/repos/hjacobs/kube-resource-report) and the Codeberg LICENSE file, all read 2026-11-09.

GitHub README stub: "Moved to https://codeberg.org/hjacobs/kube-resource-report". GitHub repo API: archived true, license GPL-3.0, 712 stars, 99 forks, last push 2020-10-02, last release 20.7.3 on 2020-07-02.

Codeberg: description "Report Kubernetes cluster and pod resource requests vs usage and generate static HTML". LICENSE file: GNU General Public License version 3. Latest tag 22.11.0 on 2022-11-30 (previous 22.10.1 on 2022-10-25, 22.10.0 on 2022-10-11). Latest commit 2023-02-09. 22 stars, 27 forks, 21 open issues; repo metadata last updated 2024-12-03.

README excerpt (Codeberg): "IMPORTANT SECURITY NOTICE: Kubernetes Resource Report does not provide any access control to the generated HTML report." "This version only supports node costs for AWS EC2 (all regions, On Demand, Linux) and GKE/GCP machine types (all regions, On Demand, without sustained discount)." It collects requests vs usage via the Metrics API, groups resource usage and slack costs per cluster, team and application, and reads VerticalPodAutoscalers.