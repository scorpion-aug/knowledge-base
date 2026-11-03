---
title: "Argo CD — findings"
description: "Argo CD vs Flux as GitOps core, Kargo for promotion, ApplicationSet, and three image-update options compared."
type: research-note
status: draft
date: 2026-11-03
author: res-researcher
cluster: argocd
tags: [ research, provisional, research-team, findings, argocd, gitops, flux, kargo, kubernetes ]
sources: [ { resource: ../../external-sources/argocd-argo-cd-readme.md }, { resource: ../../external-sources/argocd-architecture-docs.md }, { resource: ../../external-sources/argocd-applicationset-docs.md }, { resource: ../../external-sources/argocd-v3-6-rc-blog.md }, { resource: ../../external-sources/argocd-release-cadence-docs.md }, { resource: ../../external-sources/argocd-image-updater-readme.md }, { resource: ../../external-sources/argocd-flux2-readme.md }, { resource: ../../external-sources/argocd-flux-v2-10-release-notes.md }, { resource: ../../external-sources/argocd-flux-image-update-guide.md }, { resource: ../../external-sources/argocd-kargo-readme.md }, { resource: ../../external-sources/argocd-kargo-core-concepts.md } ]
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

### GitOps core: Argo CD vs Flux

| Dimension | Argo CD | Flux v2 |
|---|---|---|
| Shape | API server + repo server + app controller, with Web UI, CLI, SSO and RBAC built in ([architecture](../../external-sources/argocd-architecture-docs.md)) | Separate controllers per concern, configured purely through CRDs ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Unit of deployment | `Application`; fan-out with `ApplicationSet` ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)) | `Kustomization` / `HelmRelease` pointing at a source CRD ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Sources | Git, Helm, OCI. OCI now also drives ApplicationSet generation in 3.6 ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) | Git, OCI, Helm repos, S3 buckets; generated artifacts via ArtifactGenerator ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| UI | First-class Web UI. 3.6 adds Resources Explorer and virtual scrolling ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) | No UI listed among the toolkit components ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Release cadence | Quarterly minors, 7-week RC freeze, v4.0 planned for GA 2027-11-02 ([release cadence](../../external-sources/argocd-release-cadence-docs.md)) | v2.10.0 on 2026-10-26; supports only the latest 3 Kubernetes minors ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) |
| Governance | CNCF Graduated; CNCF Code of Conduct ([Argo CD README](../../external-sources/argocd-argo-cd-readme.md)). Graduation date per scout, not ingested | CNCF Graduated ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Commercial support | Akuity, Red Hat and Intuit contributors are visible in 3.6 credits ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)). Vendor offerings were not researched | ControlPlane enterprise support, including older Kubernetes versions ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) |

### Promotion layer: Kargo vs native features

- FACT: Kargo positions itself on top of a GitOps agent and names Argo CD as the example agent ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)).
- FACT: Native Argo CD has ApplicationSet Progressive Sync (RollingSync steps across generated Applications) ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- Not covered by any source read: whether Kargo supports Flux as the downstream agent (TODO: needs source); Flux's own promotion model (TODO: needs source).
- OPINION: Progressive Sync answers "roll this one change to these Applications in order". Kargo answers "which bundle of image + chart + config is cleared for staging, and was it verified in test?" The Freight bundle is what native features lack.

### Image-update options compared

| | Argo CD Image Updater | Flux image automation | Kargo |
|---|---|---|---|
| Status | argoproj-labs. "We would not recommend it yet for *critical* production workloads" ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | Part of Flux core, but not installed by default; enable with `--components-extra=image-reflector-controller,image-automation-controller` ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Core feature: a Warehouse watches repos and produces Freight ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) |
| Config | `ImageUpdater` CR ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | `ImageRepository` (scan), `ImagePolicy` (semver, calver, regex or alphabetical selection), `ImageUpdateAutomation` (commit and push) ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md); [Flux README](../../external-sources/argocd-flux2-readme.md)) | `Warehouse` + `Stage` + `Promotion` ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)); promotion step details not ingested |
| Write path | Argo CD API parameter overrides **or** Git commit ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | Replaces tags in YAML manifests via policy markers, then commits and pushes to Git ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Changes each stage's desired state. The mechanism (Git commit steps) is TODO: needs source |
| Manifest types | Kustomize, Helm and CMP only; plain YAML "not supported yet (and maybe never will)" ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | YAML manifests and HelmRelease values via markers ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Images, Helm charts and Git commits as Freight ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) |
| Multi-artifact coupling | Per-image (OPINION, inferred from the README) | Per-policy (OPINION) | Freight keeps multiple artifacts together through the pipeline ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) |
| Digest pinning | Not in the README | `digestReflectionPolicy: Always` / `IfNotPresent` ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | TODO: needs source |
| Recent changes | Its write-back pattern was broken by an ApplicationSet regression that was fixed in 3.6 ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) | v2.10: batching (`.spec.policyChangeDelay`), retry on rejected pushes, `.Changed.Summary`. The tag DB moves to Flux artifact storage and is wiped on upgrade ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) | Not researched |

- OPINION: Image Updater's "Argo CD API override" mode puts the running version outside Git, which weakens GitOps auditability. Use the Git write-back mode if you adopt it at all.
- OPINION: The 3.6 bug note is the more important signal. The write-back pattern depends on ApplicationSet `ignoreApplicationDifferences` behaving correctly, and that coupling broke once.

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|
| Argo CD (+ ApplicationSet) | UI, SSO and RBAC built in; fan-out across clusters and monorepos from one manifest; predictable quarterly cadence ([architecture](../../external-sources/argocd-architecture-docs.md), [ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md), [cadence](../../external-sources/argocd-release-cadence-docs.md)) | Central hub holds credentials for many clusters (OPINION). ApplicationSet has security caveats ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)). Controller memory on large installs is significant: the 3.27 GB example is pre-optimization ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) | Medium-high: stateful-ish central service, UI and SSO to operate, quarterly upgrades. OPINION | Low-medium. Apache-2.0, CNCF. Manifests stay plain Kustomize/Helm; `Application`/`ApplicationSet` CRDs are Argo-specific. OPINION |
| Flux v2 | Composable controllers; any number of sources; image automation in core; mTLS and object identity in 2.10 ([Flux README](../../external-sources/argocd-flux2-readme.md), [v2.10 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) | No built-in UI; only the latest 3 Kubernetes minors supported (1.35+ for 2.10); 2.10 has RBAC and API breaking changes ([v2.10 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) | Lower per-cluster footprint is plausible but unverified (OPINION; PoC requested). Upgrade burden is tied to the Kubernetes version | Low-medium. Apache-2.0, CNCF. `Kustomization`/`HelmRelease` CRDs are Flux-specific. OPINION |
| Kargo (on Argo CD) | Explicit promotion model; Freight bundles multi-artifact versions; projects map to namespaces and K8s RBAC ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) | Extra control plane; single-vendor-led (Akuity) with an enterprise upsell ([Kargo README](../../external-sources/argocd-kargo-readme.md)); not CNCF per scout ([sources](./sources.md)) | Medium: another controller set and UI. OPINION | Medium. The promotion pipeline definitions are Kargo-specific; if the project stalls you have to re-implement promotion. OPINION |
| Argo CD Image Updater | Simplest add-on for Argo CD users | Not recommended for critical prod; no plain YAML ([README](../../external-sources/argocd-image-updater-readme.md)) | Low | Low; easy to remove. OPINION |

## Migration path

- OPINION: **Argo CD ↔ Flux.** Both reconcile plain Kustomize/Helm from Git, so the manifests carry over. What has to be rewritten is the wrapper layer: Application/ApplicationSet becomes Kustomization/HelmRelease plus a source CRD, and vice versa. Run both side by side per namespace or cluster, and make sure exactly one controller owns each resource at any time. No migration guide was ingested (TODO: needs source).
- OPINION: **Adding Kargo later** doesn't disturb the existing Argo CD Applications, because Kargo writes desired state and Argo CD still deploys ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md) supports the split, not the claim that it is non-disruptive). Start with one app and two stages.
- FACT: Upgrade notes to watch:
  - Argo CD 3.5 → 3.6 has a dedicated upgrading guide (not ingested) ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
  - Flux → 2.10 requires binding a ClusterRole for `serviceaccounts/token` if you use the default RBAC.
  - The Flux 2.10 upgrade wipes the ImageRepository tag database ([v2.10 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).

## Conflicting sources

- Argo CD 3.6 GA status: the cadence doc plans GA for **2026-11-03**, which is today ([release cadence](../../external-sources/argocd-release-cadence-docs.md)). The scout's screen recorded v3.6.0-rc4 on 2026-10-22 as the latest 3.6 build ([sources](./sources.md)). Whether 3.6.0 GA actually shipped is unverified; check the releases page before pinning.
- "CD 4.0": the scout's sources mention a "3.6 / CD 4.0 roadmap in flight" ([sources](./sources.md)). The cadence doc puts v4.0 RC1 on 2027-09-14 and GA on 2027-11-02 ([release cadence](../../external-sources/argocd-release-cadence-docs.md)), so 4.0 is a year out, not imminent.
- Image Updater version: the scout's table lists v1.3.2 (2026-10-26) with "v1.4.0 also listed" ([sources](./sources.md)). Which one is the latest stable is unresolved.
- The Flux image guide's prerequisites still say Kubernetes ≥ 1.16 ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)), while v2.10 requires ≥ 1.35 ([v2.10 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)). The guide is stale on this point; trust the release notes.

## Open questions

- What are the specific ApplicationSet security implications (for example, which generators or templated fields let tenants escalate)? The security page wasn't ingested.
- Does Kargo support Flux as the downstream GitOps agent, or only Argo CD?
- How does Kargo write promotions (Git commit steps, PRs, or the Argo CD API), and does it pin digests?
- What is Flux's recommended multi-cluster topology (agent per cluster vs a management cluster with remote kubeconfigs)? The `.spec.kubeConfig` mention in 2.10 suggests remote targets exist ([v2.10 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).
- Kargo governance: adopter list, contributor diversity outside Akuity, any CNCF plans. All unverified.
- CNCF graduation dates for Argo and Flux are cited by the scout but not ingested.

## Requests for res-lab

- Question: For the same 20 apps on one kind cluster, what is the steady-state resource footprint of Argo CD vs Flux? | Success criterion: a recorded table of controller-pod RSS memory and CPU after 15 min idle and after a forced resync of all 20 apps, collected for both tools with the same app set; numbers from `kubectl top` or metrics-server captured in poc/README.md. | Pinned versions: kind node `kindest/node` for K8s 1.35.x, Argo CD v3.5.6 (or v3.6.0 if GA is confirmed), Flux v2.10.0.
- Question: Does Argo CD 3.6 cached-manifest compression reduce application-controller memory on a non-trivial install? | Success criterion: controller RSS measured with compression off vs on (same apps, same cluster), showing a reduction of 20% or more with CPU increase of 10% or less; otherwise record the actual delta. | Pinned versions: Argo CD v3.6.0 (GA) or v3.6.0-rc4, K8s 1.35.x.
- Question: Image update end to end: does each option land a new tag in Git and roll out within 10 minutes? | Success criterion: for each of (a) Argo CD Image Updater in Git write-back mode, (b) Flux image automation and (c) Kargo Warehouse + 2 Stages (test → prod) on Argo CD, pushing image tag `x.y.(z+1)` results in a Git commit with the new tag and the pod running it. For Kargo, prod updates only after an explicit promotion. Record time-to-commit and time-to-running. | Pinned versions: Argo CD v3.5.6, Argo CD Image Updater v1.3.2, Flux v2.10.0, Kargo v1.12.5, K8s 1.35.x.
- Question: Does a Flux 2.9 → 2.10 upgrade with the default RBAC break object-identity features without the extra ClusterRole binding? | Success criterion: reproduce or rule out the failure described in the breaking-change note, and record the exact error and the fix. | Pinned versions: Flux v2.9.6 → v2.10.0, K8s 1.35.x.

## Tentative recommendation

OPINION (tentative, 2026-11-03):

- **GitOps core: Argo CD** for a platform team that needs a UI, SSO/RBAC and many-cluster fan-out (ApplicationSet).
- **Flux** is the better fit if you want a lean, CRD-only, per-cluster reconciler and already have observability elsewhere. Both are CNCF Graduated and Apache-2.0, so lock-in is mostly CRD-shaped and modest either way.
- **Promotion:** pilot **Kargo** on top of Argo CD only if you need multi-stage promotion with bundled artifacts. Otherwise ApplicationSet Progressive Sync covers ordered rollouts. Treat Kargo's single-vendor governance as a known risk.
- **Image updates:** Flux image automation is the most mature of the three per the sources. If you're on Argo CD, prefer Kargo Warehouses over Image Updater for production, given the Image Updater README's own warning.
- Re-evaluate after the res-lab footprint and image-update PoCs.

## Related

- [Sources](./sources.md): res-scout's candidate screen
- PoC (`poc/README.md`, res-lab) and report (`report.md`, res-writer) don't exist yet. Link them once they do.
- Preserved sources: [Argo CD README](../../external-sources/argocd-argo-cd-readme.md), [Argo CD architecture](../../external-sources/argocd-architecture-docs.md), [ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md), [Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md), [Argo CD release cadence](../../external-sources/argocd-release-cadence-docs.md), [Image Updater README](../../external-sources/argocd-image-updater-readme.md), [Flux README](../../external-sources/argocd-flux2-readme.md), [Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md), [Flux image update guide](../../external-sources/argocd-flux-image-update-guide.md), [Kargo README](../../external-sources/argocd-kargo-readme.md), [Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)
- Capture caveats: architecture, Flux image guide, 3.6 blog and release-cadence pages are **partial** captures (noted at the top of each). Claims here use only the captured text.
