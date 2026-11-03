---
title: "Argo CD — PoC"
description: "Argo CD v3.5.6 on kind: App + ApplicationSet auto-sync/self-heal PASS; Flux 2.10 RBAC break reproduced; footprint PARTIAL (Argo CD only)."
type: research-note
status: draft
date: 2026-11-03
author: res-lab
cluster: argocd
tags: [ research, provisional, research-team, poc, argocd, gitops, flux, kubernetes, kind ]
sources:
  - resource: ../../../external-sources/argocd-applicationset-docs.md
  - resource: ../../../external-sources/argocd-flux-v2-10-release-notes.md
---

Runs on one throwaway kind cluster. Requested in [Findings](../findings.md) (PoC requests section) and on the kanban card. Candidate tools are in [Sources](../sources.md).

## Question

- **PoC-0 (card default):** Does a pinned Argo CD automatically sync one Application from a public repo and one ApplicationSet (git directory generator), then revert manual drift?
- **PoC-4:** Does upgrading Flux 2.9.6 to 2.10.0 with the default RBAC break object-level workload identity until the extra ClusterRole binding is added ([Flux v2.10.0 notes](../../../external-sources/argocd-flux-v2-10-release-notes.md))?
- **PoC-1:** Argo CD vs Flux controller footprint for the same 20 apps. In progress, see [PoC-1 status](#poc-1-footprint-status).

## Success criterion

Written in scratch `PLAN.md` before running.

- **PoC-0:** the guestbook Application (argocd-example-apps at a pinned commit) reaches Synced/Healthy without a manual sync. The ApplicationSet generates 20 apps from in-cluster Git, all Synced/Healthy. Self-heal reverts a `kubectl scale` drift, a deleted managed object and an edited ConfigMap.
- **PoC-4:** either reproduce the failure on an object that uses object identity (exact error captured) and show the fix resolves it, or show that no failure occurs.

## Result

- **PoC-0: PASS.** 21/21 apps Synced/Healthy with no manual sync. All three drifts were reverted within about 1 s. One caveat: the upstream guestbook image is amd64-only, so on this arm64 host it needed an image override (see [Failures and workarounds](#failures-and-workarounds)).
- **PoC-4: PASS (failure reproduced).** After the in-place upgrade, source-controller loses `serviceaccounts/token create`, and the object-identity `OCIRepository` fails with `forbidden`. Applying the extra ClusterRole/Binding restores token minting.
- **PoC-1: PARTIAL.** Argo CD v3.5.6 with 20 apps used about 486 Mi working set at idle and about 590 Mi after a forced resync (total across 7 pods). The Flux run did not execute; it is waiting on owner approval to recreate the cluster.

## Environment and pinned versions

| Component | Version |
|---|---|
| Host | Linux arm64 (aarch64), 8 vCPU |
| kind | v0.33.0 |
| Node image | `kindest/node:v1.35.8@sha256:07b2536e30b803ed61d1677a79df6115f798ce64c80f9e22f6ed45afd09323c0` |
| Argo CD | v3.5.6 (`manifests/install.yaml` at tag; CLI `v3.5.6+c2b1e30`) |
| Flux CLI/controllers | v2.9.6 then v2.10.0 |
| metrics-server | v0.9.1 (`--kubelet-insecure-tls`) |
| Git server | `gitea/gitea:1.24.6-rootless` (in-cluster, throwaway) |
| Local registry | `registry:3.1.0` |
| Guestbook source | `argoproj/argocd-example-apps` @ `8088f4c0d970abb09e250248cc97e35623447cb5` |
| Guestbook image override | `nginx:1.29.3-alpine` (multi-arch) |

Cluster: kind (`kubectl config current-context` = `kind-argocd`). Upstream check on 2026-11-03: Argo CD v3.5.7 shipped 2026-11-02, after the plan was pinned, so the PoC stays on v3.5.6. v3.6.0 is still `-rc4` (prerelease). Flux v2.10.0 is the latest release.

## Prerequisites

- Docker, plus a kubeconfig file used only for kind, exported as `KUBECONFIG`.
- If kind's `kubeadm init` fails with `client rate limiter`, raise the inotify limits first: `sudo sysctl fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=524288`.
- Binaries pinned by tag (kind, argocd, flux 2.9.6 and 2.10.0, crane).
- Approval for the cluster-wide installs: Argo CD install manifest, metrics-server, Flux.

## Run steps

```bash
# 0. infra: kind cluster "argocd" + local registry + metrics-server
./up.sh
kubectl config current-context            # must print kind-argocd

# throwaway git: gitea + admin user + public repo lab/gitops
# (password in a umask-077 scratch file, never in the KB)
kubectl apply -f gitea.yaml
# 20 synthetic apps: Namespace + pause Deployment + Service + 50 x 8 KiB ConfigMaps each (~8 MB)
OUT=./repo N=20 CMS=50 KB=8 ./gen-apps.sh   # then git commit + push to http://127.0.0.1:30300/lab/gitops.git

# 1. Argo CD v3.5.6 (server-side apply: CRDs exceed the client-side annotation limit)
kubectl create ns argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.6/manifests/install.yaml
kubectl -n argocd rollout status deploy --timeout=300s
kubectl -n argocd rollout status sts/argocd-application-controller --timeout=300s

# 2. PoC-0: one Application + one ApplicationSet, automated prune + selfHeal
kubectl apply -f guestbook-app.yaml -f appset.yaml
kubectl -n argocd get applications.argoproj.io      # poll until 21 Synced/Healthy

# 3. drift tests (each polled every 1 s)
kubectl -n guestbook scale deploy/kustomize-guestbook-ui --replicas=3
kubectl -n app-07 delete svc web
kubectl -n app-03 patch cm cfg-01 --type=merge -p '{"data":{"blob":"drift"}}'

# 4. Git-driven change (no webhook): app-05 replicas 1 -> 2, push, wait; then git revert + push

# PoC-4 (earlier run on the same kind/node versions):
#   Flux 2.9.6 with --feature-gates=ObjectLevelWorkloadIdentity=true; kubectl apply -f wi-test.yaml
#   in-place install of Flux 2.10.0 (default RBAC); then kubectl apply -f rbac-fix.yaml
```

For PoC-4, the exact `flux install` flags were not saved in the scratch log. Only the outcomes below were recorded.

## Output (trimmed)

PoC-0:

```text
Argo CD install: 7 pods Ready (quay.io/argoproj/argocd:v3.5.6, dex v2.45.1, redis 8.2.3-alpine) in 53s
ApplicationSet "synthetic": 20 apps generated; t+94s  20 Synced/Healthy  (no manual sync)
guestbook (path guestbook, upstream image): Synced/Progressing, pod Error/CrashLoop -> see failures
guestbook (kustomize-guestbook + image override): old guestbook-ui pruned, Synced/Healthy at t+11s
  -> 21 Synced/Healthy
D1 scale guestbook 1->3        reverted replicas=1  t+1s
D2 delete svc app-07/web       recreated            t+1s
D3 patch cm app-03/cfg-01      reverted             t+1s
controller log: "Initiated automated sync to '1a147ce…'" (app-07, app-03)
Git push app-05 replicas 1->2 at 15:46:27 -> applied after 189s (no webhook, default polling)
```

PoC-4:

```text
2.9.6 + --feature-gates=ObjectLevelWorkloadIdentity=true:
  crd-controller-flux-system has serviceaccounts/token create; can-i = yes
  OCIRepository wi-test (provider: aws, serviceAccountName) -> "failed to create provider access token
  ... STS: AssumeRoleWithWebIdentity ... 400"  (token minted; STS rejects the fake role = expected)
flux 2.10.0 install (in-place upgrade, default RBAC):
  crd-controller-flux-system serviceaccounts/token count = 0; can-i = no
  Ready=False OCIArtifactPullFailed: failed to create kubernetes token for service account
  'default/wi-test': serviceaccounts "wi-test" is forbidden: User
  "system:serviceaccount:flux-system:source-controller" cannot create resource
  "serviceaccounts/token" in API group "" in the namespace "default"
kubectl apply -f rbac-fix.yaml -> can-i = yes; error back at the STS stage (token minted again)
```

## Failures and workarounds

- **Guestbook image is amd64-only.** `gcr.io/google-samples/gb-frontend:v5` is a single-arch `linux/amd64` image (checked with `crane config`). On this arm64 host the pod went into Error/CrashLoop with no logs, so the app stayed `Synced/Progressing`. Argo CD itself behaved correctly: Synced, health honestly reported as Progressing. Workaround: point the Application at `kustomize-guestbook` and set `spec.source.kustomize.images: [gcr.io/google-samples/gb-frontend=nginx:1.29.3-alpine]`. Switching paths also exercised prune: the old `guestbook-ui` Deployment and Service were removed.
- **Git change latency.** Without a webhook, a pushed commit took 189 s to apply. That fits a roughly 3-minute default repo poll, but the default value is not in a preserved source here (unverified). Self-heal of live drift does not wait for that poll; it fired within about 1 s.
- **PoC-4 startup warning.** The Flux 2.10 install rewrote the controller args and dropped the retired feature gate, so the startup warning described upstream (fluxcd/flux2#6139) did not appear. (TODO: needs source for #6139; it is not ingested yet.)
- **kind create failed once** at `kubeadm init` with `client rate limiter`. Fixed by raising the inotify limits (see Prerequisites) and recreating the cluster.
- `kubectl auth can-i create serviceaccounts/token` reports `no` even when the action is allowed. Use `kubectl auth can-i create serviceaccounts --subresource=token`.

## PoC-1 footprint status

**PARTIAL.** The Argo CD half is measured. The Flux half has not run: the command that recreates the cluster for it (`flux-phase.sh`, which runs `kind delete cluster` first) hit the approval gate, got no answer within 30 min, and did not execute. It needs owner approval to re-run.

Method: same 20 apps (~1,000 objects, ~8 MB of ConfigMaps). Idle = 15 min after all 20 apps were Synced/Healthy, then 6 samples × 20 s. Forced resync = `argocd.argoproj.io/refresh=hard` on all 20, then 6 samples × 10 s. Numbers are from `kubectl top` (metrics-server). That is container **working set, not RSS**. The guestbook app had been removed, so exactly 20 apps were measured.

| Argo CD v3.5.6 pod | idle CPU avg / max (m) | idle mem avg / max (Mi) | resync CPU avg / max (m) | resync mem avg / max (Mi) |
|---|---|---|---|---|
| application-controller | 32 / 99 | 322 / 328 | 254 / 492 | 398 / 477 |
| repo-server | 3 / 8 | 45 / 47 | 23 / 95 | 73 / 97 |
| applicationset-controller | 1 / 2 | 34 / 34 | 26 / 57 | 34 / 36 |
| server | 2 / 2 | 25 / 25 | 2 / 7 | 26 / 26 |
| dex-server | 1 / 2 | 28 / 28 | 1 / 1 | 28 / 28 |
| notifications-controller | 1 / 1 | 25 / 25 | 2 / 4 | 26 / 28 |
| redis | 6 / 7 | 6 / 7 | 6 / 7 | 6 / 7 |
| **Total of averages** | **46** | **486** | **315** | **590** |

Notes:

- A first run (idle window 16:06–16:23 UTC) gave close totals: 486 Mi idle, 541 Mi resync. Its max columns were wrong: `sample.sh` compared numbers as strings in awk. The fixed script (numeric coercion) was used for the table above. The bad run's idle CPU average for the app-controller (129 m) was also much higher than the second run's (32 m). It likely caught tail work from the earlier drift and Git tests, so treat single-run CPU averages as noisy (unverified).
- Single node, one run per state, 6 samples: an indication, not a benchmark.
- Still to do: the Flux v2.10.0 run on a fresh cluster with the same repo (`flux-phase.sh` + `flux-apps.sh`, then `footprint.sh flux flux-system`). PoC-2 (3.6.0-rc4 compression) and PoC-3 (image update end to end) were not run in this session.

## Cleanup

```bash
kubectl config current-context     # must be kind-argocd
kind delete cluster --name argocd --kubeconfig "$KUBECONFIG"
docker rm -f kind-registry
# scratch only: remove the local repo clone and the gitea password file
```

## Files

These files sit next to this README. No secrets: the gitea password never leaves scratch.

- `up.sh`, `kind.yaml`: cluster, local registry, metrics-server
- `gitea.yaml`: throwaway in-cluster Git server
- `gen-apps.sh`: synthetic 20-app workload generator
- `guestbook-app.yaml`, `appset.yaml`: PoC-0 manifests
- `wi-test.yaml`, `rbac-fix.yaml`: PoC-4 manifests (fake AWS role ARN, documentation account id)
- `footprint.sh`, `sample.sh`: PoC-1 measurement scripts (`sample.sh` with the numeric-max fix)
- `flux-phase.sh`, `flux-apps.sh`: Flux half of PoC-1 (not yet run; `flux-phase.sh` deletes and recreates the `argocd` kind cluster)

ApplicationSet git directory generator semantics: [ApplicationSet docs](../../../external-sources/argocd-applicationset-docs.md).

## Related

- [Findings](../findings.md)
- [Sources](../sources.md)
- Report (`report.md`, res-writer): not written yet
