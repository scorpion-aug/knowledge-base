---
type: research-note
status: draft
title: Crossplane — candidate sources
description: "Screened candidates for how to use Crossplane v2: core, docs, providers, functions, alternatives."
date: 2026-11-04
cluster: crossplane
tags:
  - crossplane
  - research
  - sources
  - kubernetes
sources:
  - resource: ../../external-sources/crossplane-core-readme.md
  - resource: ../../external-sources/crossplane-v2-whats-new-docs.md
  - resource: ../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md
  - resource: ../../external-sources/crossplane-provider-kubernetes-readme.md
  - resource: ../../external-sources/crossplane-upjet-readme.md
---

## Scope

Topic: how to use Crossplane (github.com/crossplane/crossplane). Screened the core project, official docs, and the package ecosystem needed to run Crossplane v2 (providers, composition functions, codegen). Decision: what res-researcher digs into for findings.md and the usage guide. Search date: 2026-11-04; health data fetched same day unless marked unverified. Crossplane is CNCF Graduated since 2025-10-28 ([CNCF page](https://www.cncf.io/projects/crossplane/), TODO: needs ingest). v2 usage differs sharply from v1-era tutorials: claims removed, native patch-and-transform removed, namespaced XRs/MRs, fully-qualified package images required.

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| [crossplane/crossplane](https://github.com/crossplane/crossplane) | Core control-plane framework: XRs, compositions, function runtime, Operations, package manager, CLI | v2.4.3 (2026-10-22); v2.5 due Nov 2026 (README EOL table) | main merge 2026-11-02; 9,265 commits; 4 active release lines (v1.20/v2.2/v2.3/v2.4) | CNCF project; visible leads lsviben, jbw976, adamwg | Apache-2.0 | 12.2k stars, 1.3k forks; CNCF Graduated 2025-10-28 | dig deeper | Healthy; v1.20 EOL Nov 2026 makes v2-only guidance the right target | [README](../../external-sources/crossplane-core-readme.md), [v2 what's-new](../../external-sources/crossplane-v2-whats-new-docs.md) |
| [Official docs v2.4](https://docs.crossplane.io/latest/) | Canonical usage path: Install, Control Plane Projects, Composition, Managed Resources, Operations quickstarts + guides | n/a (v2.4 latest; v2.3/2.2/1.20 kept) | n/a | Crossplane project | CC-BY-4.0 | only official doc set | dig deeper | Get Started defines the current v2 workflow: xpkg.crossplane.io packages, functions instead of native P&T | [Get Started index](https://docs.crossplane.io/latest/get-started/) (TODO: ingest), [v2 what's-new](../../external-sources/crossplane-v2-whats-new-docs.md) |
| [Composition Functions](https://docs.crossplane.io/latest/packages/functions/) | v2 compositions are function pipelines; docs pin function-go-templating v0.9.2 and function-kro v0.3.0; patch-and-transform survives as a bundled function | versions pinned in v2.4 docs (2026-11-04) | unverified | crossplane-contrib plus SIG functions | Apache-2.0 (unverified) | required by core in v2: native pipeline removed | dig deeper | Biggest v1-to-v2 usage change; any guide must teach function composition | [v2 what's-new](../../external-sources/crossplane-v2-whats-new-docs.md) |
| [provider-upjet-aws](https://github.com/crossplane-contrib/provider-upjet-aws) | Official-style AWS provider (Upjet-generated managed resources); family sub-packages e.g. ec2 | v2.9.0 (2026-10-08) | 3,510 commits; Terraform AWS pinned 6.65.0 | crossplane-contrib (release by jonasz-lasut) | Apache-2.0 | most used cloud provider in ecosystem (unverified) | dig deeper | Needed for any real cloud example; v2.9.0 has one breaking CloudFront external-name fix | [v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md) |
| [provider-kubernetes](https://github.com/crossplane-contrib/provider-kubernetes) | Provider that manages arbitrary Kubernetes objects via an Object MR; good for no-cloud local demos | unverified (README read 2026-11-04) | unverified | crossplane-contrib | unverified | unverified | dig deeper | Lets a kind-only PoC run without cloud credentials; known write-only-field limits | [README](../../external-sources/crossplane-provider-kubernetes-readme.md) |
| [crossplane/upjet](https://github.com/crossplane/upjet) | Codegen framework turning Terraform providers into Crossplane providers | unverified | unverified | Crossplane authors | unverified | powers AWS/Azure/GCP providers and 50+ community providers (per README) | watch | Only relevant if building custom providers, not for basic usage | [README](../../external-sources/crossplane-upjet-readme.md) |
| [function-patch-and-transform](https://github.com/crossplane-contrib/function-patch-and-transform) | Composition function that carries the v1 native patch-and-transform model | tag v0.11.0 referenced in examples (2026-09-25); 30 tags | last main commit 2026-10-23; 439 commits | crossplane-contrib (ulucinar merged; jbw976 among contributors) | Apache-2.0 (unverified) | default migration path for v1 compositions (unverified) | dig deeper | Simplest function for first compositions and v1 migration | [repo page](https://github.com/crossplane-contrib/function-patch-and-transform) (TODO: ingest) |
| [kubernetes-sigs/kro](https://github.com/kubernetes-sigs/kro) | Alternative: ResourceGraphDefinition for composing K8s resources, vendor-neutral, no provider layer | unverified | 1,400 commits, created 2024-09-12 | Kubernetes SIG Cloud Provider subproject | Apache-2.0 | unverified | watch | Overlaps composition only; Crossplane docs pin function-kro, so they interoperate | [repo page](https://github.com/kubernetes-sigs/kro) (TODO: ingest) |
| [GoogleCloudPlatform/k8s-config-connector](https://github.com/GoogleCloudPlatform/k8s-config-connector) | GCP-only K8s add-on for managing GCP resources | unverified | commit 2026-11-04; 20,692 commits | Google | Apache-2.0 | 1.1k stars | skip | Single-cloud alternative, not needed to learn Crossplane | [repo](https://github.com/GoogleCloudPlatform/k8s-config-connector) |
| [aws-controllers-k8s/community](https://github.com/aws-controllers-k8s/community) | AWS Controllers for Kubernetes (ACK): AWS-only service controllers | unverified | commit 2026-11-03; 1,316 commits | AWS | Apache-2.0 | 2.6k stars | skip | Single-cloud alternative, no composition layer | [repo](https://github.com/aws-controllers-k8s/community) |
| [hashicorp/terraform-k8s](https://github.com/hashicorp/terraform-k8s) | Terraform Cloud operator for K8s | n/a | 151 commits | HashiCorp | MPL-2.0 | deprecated | skip | README states deprecated; successor is HCP Terraform Operator | [repo](https://github.com/hashicorp/terraform-k8s) |

Cells marked unverified were not read from commit graphs, release pages or license files. Core latest tags from the [tags page](https://github.com/crossplane/crossplane/tags): v2.4.3 per the [release page](https://github.com/crossplane/crossplane/releases/tag/v2.4.3) (2026-10-22, immutable, security-patch release: Go 1.26.10 CA distrust, truncated package download fix) (TODO: needs ingest).

## Preserved sources

Captured for dig-deeper candidates (2026-11-04):

- [Crossplane core README](../../external-sources/crossplane-core-readme.md)
- [What's new in v2 (docs v2.4)](../../external-sources/crossplane-v2-whats-new-docs.md)
- [provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md)
- [provider-kubernetes README](../../external-sources/crossplane-provider-kubernetes-readme.md)
- [Upjet README](../../external-sources/crossplane-upjet-readme.md)

Still to ingest (TODO): Get Started with Composition guide, function-patch-and-transform README.

Related docs: [findings](./findings.md) (res-researcher), report.md (res-writer, pending).

