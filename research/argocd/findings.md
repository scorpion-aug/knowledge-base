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
- OPINION: Because edits and deletions fan out, an ApplicationSet has a wide blast radius. A bad template or a Git generator that matches the wrong directories can change or remove many Applications at once. Treat ApplicationSet manifests as privileged config and review them accordingly.

### Flux

- FACT: Flux v2 is built from the GitOps Toolkit, "a set of composable APIs and specialized tools". The CRDs are grouped by controller: source (GitRepository, OCIRepository, HelmRepository, HelmChart, Bucket, ExternalArtifact, ArtifactGenerator), kustomize (Kustomization), helm (HelmRelease), notification (Provider, Alert, Receiver) and image automation (ImageRepository, ImagePolicy, ImageUpdateAutomation) ([Flux README](../../external-sources/argocd-flux2-readme.md)).
- FACT: Flux v2 supports multi-tenancy and "syncing an arbitrary number of Git repositories" ([Flux README](../../external-sources/argocd-flux2-readme.md)).

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
