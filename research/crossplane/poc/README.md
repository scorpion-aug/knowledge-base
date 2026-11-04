---
title: Crossplane — PoC
description: "Crossplane v2.4.3 + provider-kubernetes on kind: namespaced App XR composing Deployment+Service via fn-p&t; create/update/delete PASS, drift revert PARTIAL (SSA list-field gap)."
type: research-note
status: draft
date: 2026-11-04
author: res-lab
cluster: crossplane
tags:
  - research
  - provisional
  - research-team
  - poc
  - crossplane
  - kubernetes
  - kind
  - provider-kubernetes
  - composition
  - control-plane
sources:
  - resource: ../../../external-sources/crossplane-provider-kubernetes-readme.md
  - resource: ../../../external-sources/crossplane-compositions-docs.md
  - resource: ../../../external-sources/crossplane-composite-resources-docs.md
  - resource: ../../../external-sources/crossplane-function-patch-and-transform-readme.md
  - resource: ../../../external-sources/crossplane-v2-whats-new-docs.md
---
Runs on one throwaway kind cluster. Requested in [Findings](../findings.md) and on the kanban card (default PoC). Candidate tools are in [Sources](../sources.md).

## Question

Can a kind-only cluster run Crossplane v2.4.3 + provider-kubernetes +
function-patch-and-transform to create a **namespaced XR** (kind `App`) that
composes a Deployment and a Service via a function pipeline, with no cloud
credentials?

## Success criterion

Written in scratch `PLAN.md` before running. **PASS iff ALL of:**

1. `kubectl get apps.example.crossplane.io -n demo` shows `SYNCED=True` and `READY=True`.
2. `kubectl get deploy,service -n demo -l example.crossplane.io/app=my-app` returns exactly one Deployment and one Service.
3. Drift reconcile: mutating the composed Service (e.g. change port) is reverted by Crossplane within ~60s.
4. Delete of the XR removes the composed Deployment + Service (garbage collection).
5. No cloud credentials anywhere (kind + in-cluster provider-kubernetes only).

## Result

**PARTIAL.** Criteria 1, 2, 4, 5 pass cleanly; criterion 3 (drift revert within ~60s) does not, and the reason is worth recording (see [Drift reconcile details](#drift-reconcile-details)). The core default PoC — a namespaced v2 XR composing a Deployment + Service through a function pipeline with no cloud creds — works end to end, including create, update and delete.

## Environment and pinned versions

| Component | Version |
|---|---|
| Host | Linux arm64 (aarch64) |
| kind | v0.27.0 |
| Node image | `kindest/node:v1.32.2@sha256:f226345927d7e348497136874b6d207e0b32cc52154ad8323129352923a3142f` |
| Crossplane (helm) | crossplane-stable/crossplane 2.4.3 (app 2.4.3) |
| provider-kubernetes | v1.4.1 (`xpkg.crossplane.io/crossplane-contrib/provider-kubernetes`) |
| function-patch-and-transform | v0.11.2 (`xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform`) |
| helm | v3.22.1 |
| kubectl (client) | v1.37.1 |
| Node k8s | v1.32.2 |

Cluster: kind (`kubectl config current-context` = `kind-crossplane`).

Note: the `kubectl` client (v1.37.1, a host tool) is several minors ahead of the
v1.32.2 API server — a wider skew than usual. It did not affect any command in this
PoC, but a reproduction should pin a client matching the node minor.

Stale pins from `findings.md` corrected against upstream on 2026-11-04 (GitHub
releases API): provider-kubernetes 1.0.0 → **1.4.1**, function-patch-and-transform
0.8.2 → **0.11.2**, kind 0.20.0 (pin) → 0.33.0 (latest; the PoC actually ran on the already-installed 0.27.0 shown in the table), Argo CD 2.13 → 3.6.0,
function-go-templating 0.9.2 → 0.13.2, and `upbound/provider-aws` repo is now
301-redirected (PoC-4 pin unverifiable as-is).

## Prerequisites

- Docker, plus a kubeconfig file used only for kind, exported as `KUBECONFIG`.
- `helm` repo `crossplane-stable` (`https://charts.crossplane.io/stable`).
- Owner approval for the two cluster-wide package installs (helm release + provider/function packages).

## Run steps

```bash
kubectl config current-context          # must print kind-crossplane

# 1. core
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system --create-namespace --version 2.4.3 --wait --timeout 5m

# 2. packages + provider wiring
cd poc && kubectl apply -f 00-namespace.yaml -f 01-provider.yaml -f 03-function.yaml
# 02 applies only after the provider CRDs exist:
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=180s
kubectl wait --for=condition=Healthy function.pkg.crossplane.io/function-patch-and-transform --timeout=180s
kubectl apply -f 02-provider-config.yaml

# 3. XRD + Composition (Pipeline mode) + XR
kubectl apply -f 04-xrd.yaml -f 05-composition.yaml
kubectl apply -f 06-xr.yaml
kubectl wait --for=condition=Ready app/my-app -n demo --timeout=120s

# 4. verify
kubectl get apps.example.crossplane.io -n demo
kubectl get deploy,service -n demo -l example.crossplane.io/app=my-app

# 5. update path (port 80->8080, replicas 2->3) then delete
kubectl patch app my-app -n demo --type=merge -p '{"spec":{"port":8080,"replicas":3}}'
kubectl delete app my-app -n demo --wait=true
```

## Output (trimmed)

```text
# core
crossplane-system pods: crossplane 1/1 Running, crossplane-rbac-manager 1/1 Running
provider-kubernetes   INSTALLED=True HEALTHY=True  xpkg...provider-kubernetes:v1.4.1
function-patch-and-transform  INSTALLED=True HEALTHY=True  ...function-patch-and-transform:v0.11.2

# XR
NAME     SYNCED   READY   COMPOSITION                  COMPOSITIONREVISION          AGE
my-app   True     True    apps.example.crossplane.io   apps.example.crossplane.io-…  44s

# composed managed resources (one per app bundle member)
NAME                  KIND         PROVIDERCONFIG        SYNCED   READY
my-app-eafa7c4f05bf   Deployment   kubernetes-provider   True     True
my-app-f2568632d991   Service      kubernetes-provider   True     True

deployment.apps/my-app   2/2 ready   nginx:1.27-alpine
service/my-app           ClusterIP   80/TCP

# update: port 80->8080, replicas 2->3
replicas=3/3 svc-port=8080  (applied in ~10s)

# delete cascade
app "my-app" deleted -> no Object MRs, no Deployment, no Service remain
```

## Drift reconcile details

This is the one nuance. The provider-kubernetes default drift poll is **10 minutes**
(`--poll` default in `cmd/provider/main.go:95` at tag v1.4.1 — read from the cloned
source in scratch, not a preserved KB source), so with defaults a drift is not
reverted within 60s. The provider also ships a realtime option: `spec.watch: true`
on the Object MR (alpha, honored when the `watches` feature gate is on — it is on by
default and the provider logs `Beta feature enabled flag=EnableBetaWatches`). Three
drift cases were tested with `watch: true`:

| Drift | Result |
|---|---|
| Delete the composed Service | Recreated in ~20s (realtime watch fires). |
| Change a leaf field (Service selector label) | Reverted in ~2s. |
| Change a list field (`spec.ports[0].port` 80→9090 via `kubectl patch`) | **Not reverted.** Object MR goes `Synced=False (ReconcileError)` with `cannot apply object: Service "my-app" is invalid: spec.ports[0].name Required value, spec.ports[1].name Required value`. |

The port case is an SSA field-ownership artifact, not a controller outage: the
Service shows two field managers (`provider-kubernetes/my-app-…` with operation
`Apply` and `kubectl-patch` with operation `Update`), so the provider's server-side
apply merge on the `ports[]` list cannot reconcile the out-of-band `Update` edit
into a valid object. The desired manifest still says `port: 80`, the observation
still reports `9090`, and the apply loop errors instead of converging. Net: whole-
object and leaf-field drift reconcile quickly with `watch: true`; list-field drift
introduced by a non-apply edit does not (unverified whether a newer v1.4.x or the
non-alpha management-policy combination changes this).

Default drift handling (no `watch`) was also observed: a port edit stayed at the
edited value past 2 minutes, consistent with the 10-minute poll — do not read
"~60s revert" from this PoC without enabling `watch`.

## Failures and workarounds

- **ProviderConfig CRD not present at first apply.** `kubectl apply -f 02-provider-config.yaml`
  failed with `no matches for kind "ProviderConfig"` because the CRDs come from the
  provider package. Fix: install the provider, wait `Healthy`, then apply.
- **`kubectl get providers` did not list under a mixed alias.** Use the full resource
  `providers.pkg.crossplane.io` and `functions.pkg.crossplane.io`.
- **List-field (`ports[]`) drift does not self-heal under SSA** — documented in
  [Drift reconcile details](#drift-reconcile-details).

## Cleanup

```bash
kubectl config current-context     # must be kind-crossplane
kind delete cluster --name crossplane --kubeconfig "$KUBECONFIG"
```

## Files

All manifests next to this README are cleaned (comments only, no secrets; no cloud
credentials anywhere — the ProviderConfig uses `credentials.source: InjectedIdentity`).

- `00-namespace.yaml` — `demo` namespace
- `01-provider.yaml` — Provider + DeploymentRuntimeConfig + cluster-admin ClusterRoleBinding
- `02-provider-config.yaml` — namespaced `kubernetes.m.crossplane.io` ProviderConfig (InjectedIdentity)
- `03-function.yaml` — Function (function-patch-and-transform)
- `04-xrd.yaml` — v2 XRD `apps.example.crossplane.io`, scope Namespaced
- `05-composition.yaml` — Pipeline mode, fn-p&t `Resources` input emitting Deployment + Service Object MRs (with `watch: true`)
- `06-xr.yaml` — the `App` XR (replicas, image, port)

## Related

- [Findings](../findings.md)
- [Sources](../sources.md)
- Report (`report.md`, res-writer): not written yet
