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

- FACT: Argo CD describes itself as "a declarative GitOps continuous delivery tool for Kubernetes". Its stated rationale is that application definitions, configuration and environments should be declarative and version-controlled, and that deployment should be "automated, auditable, and easy to understand" ([Argo CD README](../../external-sources/argocd-argo-cd-readme.md), master, fetched 2026-11-03).
- FACT: Flux describes itself as "a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy" ([Flux README](../../external-sources/argocd-flux2-readme.md), main, fetched 2026-11-03).
- FACT: Kargo "builds upon GitOps principles to manage and automate the promotion of software artifacts through the many stages of their lifecycle" ([Kargo README](../../external-sources/argocd-kargo-readme.md), main, fetched 2026-11-03).
- OPINION: Argo CD and Flux solve the same problem: reconciling a cluster to what Git or OCI declares. Kargo solves a different, adjacent one: deciding which version each stage should declare, then moving it forward. Kargo complements a reconciler; it doesn't replace one.

## Core concepts

### Argo CD

- FACT: The unit is an `Application` (source repo URL + revision + path → destination cluster + namespace). The application controller compares live state against the target state in the repo, detects `OutOfSync` and "optionally takes corrective action". It also runs PreSync, Sync and PostSync hooks ([Argo CD architecture](../../external-sources/argocd-architecture-docs.md), stable docs, fetched 2026-11-03).

### ApplicationSet (part of Argo CD)

- FACT: ApplicationSet is a controller plus CRD, bundled with Argo CD since v2.3. A single manifest can target many clusters or deploy many apps from one or more repos. It improves monorepo support and lets tenants self-serve on multitenant clusters without a privileged admin enabling each destination ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md), stable, fetched 2026-11-03).
- FACT: *Generators* produce parameters that are substituted into a `template:`. Each rendered template becomes an Argo CD `Application` in the Argo CD namespace. Documented generators include List, Cluster (built from clusters registered in Argo CD), Git (files or directories) and Matrix (combines two generators), with more under the generators section ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)).
- FACT: Changes to an ApplicationSet, including deletions, propagate to every Application it generated ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)).
- FACT: The docs warn readers to "be aware of the security implications of ApplicationSets before using them" ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)). The security page itself was not ingested (TODO: needs source for the specific risks).
- FACT (3.6 RC, 2026-09-16): there is a new **OCI generator**. It discovers directories and parses files inside an OCI artifact using the same include/exclude semantics as the Git generators, "so the teams who have moved their manifests … into an OCI registry no longer have to keep a Git repository around purely to drive ApplicationSet generation" ([Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- FACT (3.6 RC): **Progressive Sync** improvements:
  - Owned Applications are refreshed before step decisions.
  - New `--refresh-grace-period-seconds` flag.
  - Four new Prometheus metrics labeled by namespace, AppSet and step.
  - New `ApplicationSetRolloutError` and `InvalidRolloutConfig` reasons. Before this, a rollout that never started was reported as completed.
  - Also new in 3.6: a `tpl` function in go-templates and workqueue rate-limiter flags. Previously retries were capped at about 16 minutes ([Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- OPINION: Progressive Sync gives Argo CD a basic ordered, multi-cluster rollout across generated Applications. It is not a promotion system: there's no artifact bundle and no per-stage verification gate in the sources read. The fact that 3.6 had to fix a case where a rollout that never began looked identical to a successful one suggests the feature was still maturing as of 3.5.
- OPINION: Because edits and deletions fan out, an ApplicationSet has a wide blast radius. A bad template or a Git generator that matches the wrong directories can change or remove many Applications at once. Treat ApplicationSet manifests as privileged config and review them accordingly.

### Argo CD 3.6 (RC) deltas relevant to the decision

- FACT: Two controller memory changes, both described in the RC blog post published 2026-09-16:
  - Label-based resource filtering (`resource.selectors` in `argocd-cm`) applies label selectors server-side, so non-matching objects never enter the cluster cache.
  - Optional serialization and compression of cached manifests. In the blog's benchmark, controller memory went from 3.27 GB to under 1 GB, about 70% less, for about 2.5% more CPU. A second large instance saw about 30% savings ([Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- FACT: 3.6 also adds:
  - A global Resources Explorer view that respects RBAC.
  - Virtual scrolling in the UI for installs with many apps.
  - A "rollback" RBAC action, disabled by default.
  - A `hydrator_status` label on `argocd_app_info` for the Source Hydrator.
  - A fix so server-side diff respects impersonation. Before the fix, the diff dry-run used the controller's own credentials ([Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- OPINION: The memory numbers come from the project's own benchmarks in an RC post, not from independent tests. Treat them as an upper bound until reproduced (see Requests for res-lab).

### Flux

- FACT: Flux v2 is built from the GitOps Toolkit, "a set of composable APIs and specialized tools". The CRDs are grouped by controller: source (GitRepository, OCIRepository, HelmRepository, HelmChart, Bucket, ExternalArtifact, ArtifactGenerator), kustomize (Kustomization), helm (HelmRelease), notification (Provider, Alert, Receiver) and image automation (ImageRepository, ImagePolicy, ImageUpdateAutomation) ([Flux README](../../external-sources/argocd-flux2-readme.md)).
- FACT: Flux v2 supports multi-tenancy and "syncing an arbitrary number of Git repositories" ([Flux README](../../external-sources/argocd-flux2-readme.md)).
- FACT (v2.10.0, 2026-10-26):
  - Object identity is GA.
  - Inter-controller traffic uses SPIFFE mTLS.
  - The notification APIs are promoted to `v1`.
  - `HelmRelease` can take `OCIRepository` as a chart source.
  - `ArtifactGenerator` gains cross-namespace artifacts and tenant namespace provisioning ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).
- FACT: v2.10.0 has these breaking changes ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)):
  - The default RBAC no longer grants `create` on `serviceaccounts/token`. You must bind a ClusterRole before upgrading if you rely on the defaults.
  - Converting notification `v1beta3` to `v1` drops several deprecated fields.
  - The ImageRepository tag database switches to Flux artifact storage. This wipes the local tag DB and forces a full rescan. The old behaviour is kept with `--feature-gates=FluxStorage=false`.
  - Remote-cluster auth renames the `audiences` key.

### Kargo

- FACT: Kargo calls itself "an unopinionated continuous promotion platform". It defines promotion as propagating changes to the *desired state* of each stage and leaves deployment "to a GitOps agent like Argo CD" ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md), docs.kargo.io, fetched 2026-11-03).
- FACT: Kargo's terms, all from [Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md):
  - **Stage**: a promotion target. It can be an environment, a set of microservices, or a whole cluster. Stages link together into a pipeline.
  - **Freight**: a "meta-artifact" that references specific revisions of images, Helm charts and Git commits, so they move through the pipeline together.
  - **Warehouse**: watches repositories and packages the latest revision of each artifact into new Freight.
  - **Project**: the unit of tenancy, mapped to a Kubernetes namespace and governed by standard RBAC.
- FACT: Akuity sells a hosted, managed and supported enterprise edition of Kargo ([Kargo README](../../external-sources/argocd-kargo-readme.md)). The README asks contributors to open an issue so they can engage the maintainers first.

## Architecture

### Argo CD

- FACT: Argo CD has three core components ([Argo CD architecture](../../external-sources/argocd-architecture-docs.md); partial page capture):
  - **API server** (gRPC/REST): serves the Web UI, CLI and CI. Handles app management, sync and rollback, repo and cluster credentials (stored as K8s Secrets), SSO delegation, RBAC, and Git webhooks.
  - **Repository server**: keeps a local cache of the Git repos and renders manifests from repo + revision + path + template settings (Helm values, parameters).
  - **Application controller**: diffs live state against desired state and syncs.
- FACT: The ApplicationSet controller runs alongside these and writes `Application` resources into the Argo CD namespace ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)).
- OPINION: This is a hub model. One Argo CD holds credentials for many destination clusters, and a central UI, RBAC and SSO layer sits in front. The architecture doc doesn't say this in those words; it's an inference from "cluster credential management" in the API server plus the multi-cluster destinations shown in the ApplicationSet docs.

### Flux

- FACT: Flux is a set of separate controllers, each owning its CRDs ([Flux README](../../external-sources/argocd-flux2-readme.md)). Since v2.10 they talk to each other over SPIFFE mTLS ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md), 2026-10-26).
- FACT: Flux v2.10 supports Kubernetes 1.35 to 1.37 only. The project supports the latest three minor versions, and vendors such as ControlPlane offer support for older ones ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).
- FACT: Flux Operator (OperatorHub) configures multi-tenancy lockdown, network policies, sharding and vertical scaling, and syncs from Git, OCI or S3-compatible storage ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).
- FACT: The Flux README lists no web UI component ([Flux README](../../external-sources/argocd-flux2-readme.md)). Whether third-party UIs are good enough is unverified.
- OPINION: Flux is closer to "agent per cluster". Each cluster runs its own controllers and pulls its own sources, with no central control plane. Whether there is an official hub-and-spoke mode was not verified (TODO: needs source).

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
