---
title: Argo CD — report
description: Argo CD vs Flux as GitOps core, Kargo for promotion and image-update options, with Argo CD v3.5.6 and Flux 2.10 PoC results on kind.
type: research-note
status: draft
date: 2026-11-03
author: res-writer
cluster: argocd
tags:
  - research
  - provisional
  - research-team
  - report
  - argocd
  - gitops
  - flux
  - kargo
  - kubernetes
sources:
  - resource: ../../external-sources/argocd-argo-cd-readme.md
  - resource: ../../external-sources/argocd-architecture-docs.md
  - resource: ../../external-sources/argocd-applicationset-docs.md
  - resource: ../../external-sources/argocd-v3-6-rc-blog.md
  - resource: ../../external-sources/argocd-release-cadence-docs.md
  - resource: ../../external-sources/argocd-image-updater-readme.md
  - resource: ../../external-sources/argocd-flux2-readme.md
  - resource: ../../external-sources/argocd-flux-v2-10-release-notes.md
  - resource: ../../external-sources/argocd-flux-image-update-guide.md
  - resource: ../../external-sources/argocd-kargo-readme.md
  - resource: ../../external-sources/argocd-kargo-core-concepts.md
---
> **Draft.** Built from [findings](./findings.md) (res-researcher), [PoC README](./poc/README.md) (res-lab) and [sources](./sources.md) (res-scout), all dated 2026-11-03. Nothing new was researched for this report. The Flux half of the footprint comparison has not run yet, so the recommendation is tentative. See [Gaps](#gaps).

How-to guide for the steps that were actually run: [Bootstrap Argo CD on kind](./guide-bootstrap-argocd.md).

## Problem

We need one tool that keeps Kubernetes clusters in line with what is declared in Git, plus a way to move new versions from one environment to the next. The decision has three parts ([findings](./findings.md#question)):

1. **GitOps core:** Argo CD or Flux v2?
2. **Promotion layer:** do we add Kargo on top for test → prod promotion?
3. **Image updates:** Argo CD Image Updater, Flux image automation, or Kargo?

Readers are platform engineers choosing a default for new clusters.

## Concepts

- **GitOps:** the desired state of a cluster lives in a Git repo (or an OCI artifact), and a controller in the cluster makes the live state match it. Argo CD calls itself "a declarative GitOps continuous delivery tool for Kubernetes" ([Argo CD README](../../external-sources/argocd-argo-cd-readme.md)). Flux describes itself as a tool for "keeping Kubernetes clusters in sync with sources of configuration" ([Flux README](../../external-sources/argocd-flux2-readme.md)).
- **Reconciler:** the controller that compares live state with desired state and fixes differences. Argo CD's application controller detects `OutOfSync` and "optionally takes corrective action" ([Argo CD architecture](../../external-sources/argocd-architecture-docs.md)).
- **Drift / self-heal / prune:** *drift* is any manual change to the live cluster that Git doesn't have. *Self-heal* means the reconciler reverts it automatically. *Prune* means it deletes live objects that were removed from Git. In the PoC both were switched on with `syncPolicy.automated: {prune: true, selfHeal: true}` ([poc/guestbook-app.yaml](./poc/README.md#files)).
- **CRD (Custom Resource Definition):** a Kubernetes API extension. Both tools are configured through their own CRDs.
- **Argo CD `Application`:** one source (repo URL + revision + path) mapped to one destination (cluster + namespace) ([Argo CD architecture](../../external-sources/argocd-architecture-docs.md)).
- **`ApplicationSet`:** a controller + CRD bundled with Argo CD since v2.3. *Generators* (List, Cluster, Git, Matrix, …) produce parameters that fill a `template:`, and each result becomes an `Application`. Edits and deletions propagate to every generated Application ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)).
- **Flux `Kustomization` / `HelmRelease`:** Flux's deployment units. They point at a source CRD such as `GitRepository` or `OCIRepository` ([Flux README](../../external-sources/argocd-flux2-readme.md)).
- **Kargo Stage / Freight / Warehouse:** a *Stage* is a promotion target (for example an environment). *Freight* is a "meta-artifact" that pins specific image, chart and Git revisions so they move together. A *Warehouse* watches repos and produces new Freight. Kargo changes each stage's desired state and leaves deployment "to a GitOps agent like Argo CD" ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)).

## Options

### GitOps core

| | Argo CD | Flux v2 |
|---|---|---|
| Shape | API server + repo server + application controller; Web UI, CLI, SSO and RBAC built in ([architecture](../../external-sources/argocd-architecture-docs.md)) | Separate controllers per concern (source, kustomize, helm, notification, image automation), configured only through CRDs ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| UI | First-class Web UI; 3.6 adds a Resources Explorer and virtual scrolling ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) | No UI listed among the toolkit components ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Fan-out | `ApplicationSet` generators across clusters and monorepos ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)) | Multi-tenancy and "an arbitrary number of Git repositories" ([Flux README](../../external-sources/argocd-flux2-readme.md)) |
| Release cadence | Quarterly minors with a 7-week RC freeze; v4.0 GA planned 2027-11-02 ([release cadence](../../external-sources/argocd-release-cadence-docs.md)) | v2.10.0 on 2026-10-26; supports only the latest 3 Kubernetes minors (1.35–1.37) ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) |
| Governance | CNCF Graduated, Apache-2.0 ([Argo CD README](../../external-sources/argocd-argo-cd-readme.md)) | CNCF Graduated, Apache-2.0 ([Flux README](../../external-sources/argocd-flux2-readme.md)) |

### Promotion layer

- **Native Argo CD:** ApplicationSet Progressive Sync rolls a change across generated Applications in steps. 3.6 fixes a case where a rollout that never started was reported as completed ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- **Kargo on Argo CD:** Freight bundles several artifacts and moves them stage by stage ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)). It is Akuity-led and has a paid enterprise edition ([Kargo README](../../external-sources/argocd-kargo-readme.md)).
- Whether Kargo can drive Flux as its agent is not covered by any preserved source (see [Gaps](#gaps)).

### Image updates

| | Argo CD Image Updater | Flux image automation | Kargo |
|---|---|---|---|
| Maturity | argoproj-labs; "we would not recommend it yet for *critical* production workloads" ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | Part of Flux, opt-in via `--components-extra=image-reflector-controller,image-automation-controller` ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Core feature: Warehouse → Freight ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) |
| Write path | Argo CD API override **or** Git commit ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | Rewrites tags at policy markers in YAML, commits and pushes ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Changes stage desired state; exact mechanism not in a preserved source |
| Manifest types | Kustomize, Helm and CMP; no plain YAML ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) | YAML and HelmRelease values ([Flux image guide](../../external-sources/argocd-flux-image-update-guide.md)) | Images, charts and Git commits as Freight ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) |

None of the three image-update paths was run end to end (PoC-3 not run).

## Trade-offs

**Measured in the PoC (Argo CD v3.5.6, kind, one arm64 node):**

- Auto-sync works without manual steps: 21/21 apps reached Synced/Healthy ([PoC result](./poc/README.md#result)).
- Self-heal is fast: a scale, a deleted Service and an edited ConfigMap were each reverted in about 1 s ([PoC output](./poc/README.md#output-trimmed)).
- Git-driven changes are slow without a webhook: a pushed commit took 189 s to apply. This fits a roughly 3-minute repo poll, but that default is not in a preserved source (unverified) ([failures and workarounds](./poc/README.md#failures-and-workarounds)).
- Footprint for 20 apps (~1,000 objects) across Argo CD's 7 pods: about **486 Mi / 46m CPU idle** and **590 Mi / 315m CPU** after a forced resync of all 20. The application controller is most of it (322 Mi idle). These are `kubectl top` working-set numbers from one run, so treat them as indicative ([PoC-1 status](./poc/README.md#poc-1-footprint-status)).
- **No Flux numbers yet.** The claim that Flux has a lower per-cluster footprint is still an untested opinion ([findings](./findings.md#trade-offs)).

**Flux upgrade risk (reproduced in the PoC):** upgrading 2.9.6 → 2.10.0 in place with the default RBAC removes `create` on `serviceaccounts/token`. Any object that uses object-level workload identity then fails with `forbidden`. This matches the breaking-change note in the [Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md). Binding the extra ClusterRole restored it ([PoC-4 output](./poc/README.md#output-trimmed)). The same release also wipes the ImageRepository tag database on upgrade ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)).

**From the sources (not tested here):**

| Option | Main upside | Main downside |
|---|---|---|
| Argo CD + ApplicationSet | UI, SSO and RBAC built in; one manifest fans out to many apps or clusters ([architecture](../../external-sources/argocd-architecture-docs.md), [ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)) | Central hub holds credentials for many clusters (OPINION from [findings](./findings.md#architecture)). ApplicationSet has documented security implications ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)). Large installs use a lot of controller memory: 3.27 GB in the project's own pre-3.6 benchmark ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) |
| Flux v2 | Lean CRD-only controllers; image automation built in; SPIFFE mTLS and object identity GA in 2.10 ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) | No built-in UI ([Flux README](../../external-sources/argocd-flux2-readme.md)); tight Kubernetes version window and breaking changes in 2.10 ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)) |
| Kargo | Explicit, multi-artifact promotion ([Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)) | Another control plane; single-vendor governance ([Kargo README](../../external-sources/argocd-kargo-readme.md)) |
| Image Updater | Smallest add-on for Argo CD | Its own README warns against critical prod use ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)) |

Lock-in is modest either way: both cores reconcile plain Kustomize/Helm, so mostly the wrapper CRDs (`Application` vs `Kustomization`) would need rewriting (OPINION, [findings](./findings.md#migration-path)).

## How to use

Step-by-step version: [Bootstrap Argo CD on kind](./guide-bootstrap-argocd.md). In short, as run in the PoC:

1. Install Argo CD from the pinned tag's `manifests/install.yaml` with **server-side apply**. The CRDs are too large for client-side apply's annotation limit ([run steps](./poc/README.md#run-steps)).
2. Wait for the deployments and the `argocd-application-controller` StatefulSet to roll out. In the PoC, 7 pods were Ready in 53 s.
3. Create an `Application` pinned to a commit (`targetRevision: <sha>`) with `automated: {prune: true, selfHeal: true}` and `CreateNamespace=true`.
4. For many similar apps, create one `ApplicationSet` with a Git directory generator (`apps/*`) and `goTemplate: true`.
5. Add a Git webhook if you need changes applied faster than the poll interval (not tested here).
6. **If you run Flux 2.10:** bind the `serviceaccounts/token` ClusterRole *before* upgrading if you use object identity ([Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)). Check it with `kubectl auth can-i create serviceaccounts --subresource=token`. The `serviceaccounts/token` form reports `no` even when the action is allowed ([failures and workarounds](./poc/README.md#failures-and-workarounds)).

## Examples

Only examples from [poc/](./poc/README.md) that were actually run, with versions. Environment: kind v0.33.0, `kindest/node:v1.35.8`, Argo CD v3.5.6, Flux v2.9.6 → v2.10.0, arm64 host ([pinned versions](./poc/README.md#environment-and-pinned-versions)).

### Single Application, pinned commit, auto-sync + self-heal

From `poc/guestbook-app.yaml`. The image override is there because the upstream guestbook image is amd64-only and crash-looped on the arm64 host. On amd64 you can drop the `kustomize.images` block ([failures and workarounds](./poc/README.md#failures-and-workarounds)).

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: 8088f4c0d970abb09e250248cc97e35623447cb5
    path: kustomize-guestbook
    kustomize:
      images:
        - gcr.io/google-samples/gb-frontend=nginx:1.29.3-alpine
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  syncPolicy:
    automated: {prune: true, selfHeal: true}
    syncOptions: [CreateNamespace=true]
```

Result: Synced/Healthy at t+11 s. Switching the path from `guestbook` to `kustomize-guestbook` also pruned the old `guestbook-ui` Deployment and Service.

### ApplicationSet, Git directory generator, 20 apps

From `poc/appset.yaml`. The repo URL points at the throwaway in-cluster Gitea used in the PoC.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: synthetic
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: http://gitea.git.svc.cluster.local:3000/lab/gitops.git
        revision: main
        directories:
          - path: apps/*
  template:
    metadata:
      name: '{{.path.basename}}'
    spec:
      project: default
      source:
        repoURL: http://gitea.git.svc.cluster.local:3000/lab/gitops.git
        targetRevision: main
        path: '{{.path.path}}'
      destination:
        server: https://kubernetes.default.svc
      syncPolicy:
        automated: {prune: true, selfHeal: true}
```

Result: 20 Applications generated, all Synced/Healthy at t+94 s with no manual sync.

### Drift tests

```bash
kubectl -n guestbook scale deploy/kustomize-guestbook-ui --replicas=3   # reverted to 1 at t+1s
kubectl -n app-07 delete svc web                                       # recreated at t+1s
kubectl -n app-03 patch cm cfg-01 --type=merge -p '{"data":{"blob":"drift"}}'   # reverted at t+1s
```

### Flux 2.10 RBAC fix (PoC-4)

From `poc/rbac-fix.yaml`. The manifest comes from upstream issue fluxcd/flux2#6139, which is referenced by the [Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md) but not preserved in the KB yet.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flux-object-level-workload-identity
rules:
  - apiGroups: [""]
    resources: ["serviceaccounts/token"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: flux-object-level-workload-identity
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flux-object-level-workload-identity
subjects:
  - kind: ServiceAccount
    name: source-controller
    namespace: flux-system
```

Error before the fix, after an in-place upgrade to 2.10.0 (trimmed):

```text
Ready=False OCIArtifactPullFailed: failed to create kubernetes token for service account
'default/wi-test': serviceaccounts "wi-test" is forbidden: User
"system:serviceaccount:flux-system:source-controller" cannot create resource
"serviceaccounts/token" in API group "" in the namespace "default"
```

After `kubectl apply -f rbac-fix.yaml`, token minting worked again. The test then failed at the AWS STS step, which was expected because the role ARN is fake ([PoC-4 output](./poc/README.md#output-trimmed)).

## Conclusion / Recommendation

**Tentative (2026-11-03), pending the Flux footprint run and PoC-2/PoC-3:**

- **GitOps core: Argo CD.** It did what the card asked on v3.5.6: hands-off sync for 21 apps, about 1 s self-heal, and one ApplicationSet driving 20 apps. It also has the UI, SSO/RBAC and fan-out a platform team needs ([findings](./findings.md#tentative-recommendation)). Budget roughly 0.5 GiB for a small install (PoC-1, indicative), and plan for much more on large installs ([3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)).
- **Add a Git webhook** if apply latency matters. Polling took 189 s in the PoC.
- **Flux** stays the better choice for a lean, CRD-only, per-cluster setup. If you run it, apply the `serviceaccounts/token` RBAC fix before any 2.10 upgrade. The PoC confirmed the break.
- **Promotion:** pilot Kargo on Argo CD only if you need multi-artifact, stage-by-stage promotion. Otherwise ApplicationSet Progressive Sync is enough for ordered rollouts (OPINION, [findings](./findings.md#promotion-layer-kargo-vs-native-features)).
- **Image updates:** on Argo CD, prefer Kargo Warehouses over Image Updater for production, given the Image Updater README's own warning ([Image Updater README](../../external-sources/argocd-image-updater-readme.md)). Not tested end to end.

The Argo-vs-Flux call may change once the Flux footprint is measured. The other parts of the recommendation don't depend on that run.

## Gaps

Open items (not yet handed off individually):

- **res-lab, PoC-1 Flux half:** not run. `flux-phase.sh` deletes and recreates the `argocd` kind cluster, so it needs owner approval first ([PoC-1 status](./poc/README.md#poc-1-footprint-status)).
- **res-lab, PoC-2:** Argo CD 3.6 cached-manifest compression (claimed ~70% controller memory saving in the project's own benchmark, [3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)) not run.
- **res-lab, PoC-3:** end-to-end image update (Image Updater vs Flux vs Kargo) not run.
- **res-lab, PoC-4:** the exact `flux install` flags were not saved.
- **res-researcher:** fluxcd/flux2#6139 (source of the RBAC fix manifest) not ingested; ApplicationSet security page not ingested; Argo CD default repo poll interval (needed to confirm the 189 s observation) not in a source; app-of-apps pattern not in any source; whether Kargo supports Flux; how Kargo writes promotions; Flux multi-cluster topology ([findings open questions](./findings.md#open-questions)).
- **Owner:** check whether Argo CD 3.6.0 GA shipped (planned for 2026-11-03, [release cadence](../../external-sources/argocd-release-cadence-docs.md)) and whether to pin v3.5.7, which shipped after the PoC was pinned ([pinned versions](./poc/README.md#environment-and-pinned-versions)).

## Sources and versions

| Item | Version / date |
|---|---|
| Argo CD (PoC) | v3.5.6; v3.5.7 shipped 2026-11-02; v3.6.0-rc4 latest 3.6 build per scout |
| Flux (PoC) | v2.9.6 → v2.10.0 (2026-10-26) |
| Kubernetes (PoC) | kind v0.33.0, `kindest/node:v1.35.8` |
| Kargo / Image Updater (sources only) | v1.12.5 / v1.3.2 per [sources](./sources.md) |

Preserved sources cited (all fetched 2026-11-03; architecture, Flux image guide, 3.6 blog and release cadence are partial captures):

- [Argo CD README](../../external-sources/argocd-argo-cd-readme.md)
- [Argo CD architecture](../../external-sources/argocd-architecture-docs.md)
- [ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)
- [Argo CD 3.6 RC blog](../../external-sources/argocd-v3-6-rc-blog.md)
- [Argo CD release cadence](../../external-sources/argocd-release-cadence-docs.md)
- [Argo CD Image Updater README](../../external-sources/argocd-image-updater-readme.md)
- [Flux README](../../external-sources/argocd-flux2-readme.md)
- [Flux v2.10.0 notes](../../external-sources/argocd-flux-v2-10-release-notes.md)
- [Flux image update guide](../../external-sources/argocd-flux-image-update-guide.md)
- [Kargo README](../../external-sources/argocd-kargo-readme.md)
- [Kargo core concepts](../../external-sources/argocd-kargo-core-concepts.md)

## Related

- [Sources](./sources.md)
- [Findings](./findings.md)
- [PoC](./poc/README.md)
- [Guide: Bootstrap Argo CD on kind](./guide-bootstrap-argocd.md)
