---
author: res-writer
cluster: argocd
date: 2026-11-03
description: Install Argo CD v3.5.6 on kind and bootstrap one Application plus an ApplicationSet with auto-sync and self-heal, as run in the PoC.
sources:
  - resource: ../../external-sources/argocd-applicationset-docs.md
status: draft
tags:
  - research
  - provisional
  - research-team
  - guide
  - argocd
  - gitops
  - kubernetes
  - kind
title: "Argo CD — guide: bootstrap Argo CD on kind"
type: research-note
---
> **Draft how-to.** Every step below was run in the [PoC](./poc/README.md) on 2026-11-03 with Argo CD v3.5.6 on kind. Context and recommendation: [report](./report.md).

> **Scope note.** The card asked for "Bootstrap Argo CD with app-of-apps". The PoC did **not** run the app-of-apps pattern (one parent `Application` whose path contains other `Application` manifests), and no preserved source describes it. This guide covers what was run: one `Application` plus one `ApplicationSet` that fans out to 20 apps. App-of-apps is listed in the [report gaps](./report.md#gaps).

## What you get

- Argo CD v3.5.6 in the `argocd` namespace (7 pods).
- One `Application` pinned to a Git commit, with automated sync, prune and self-heal.
- One `ApplicationSet` that turns every `apps/*` directory in a Git repo into its own `Application` ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)).

**Terms:** *sync* = apply what Git declares. *Prune* = delete live objects that were removed from Git. *Self-heal* = revert manual changes made to the cluster. *Generator* = the part of an ApplicationSet that produces one parameter set per app.

## Prerequisites

As used in the PoC ([pinned versions](./poc/README.md#environment-and-pinned-versions)):

- Docker, kind v0.33.0, `kubectl`, and a kubeconfig used only for kind (`export KUBECONFIG=...`).
- Node image `kindest/node:v1.35.8`.
- A Git repo with one directory per app under `apps/`. The PoC used a throwaway in-cluster Gitea and 20 synthetic apps from `poc/gen-apps.sh`.
- If `kind create cluster` fails at `kubeadm init` with `client rate limiter`, raise the inotify limits first: `sudo sysctl fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=524288`.

## Steps

### 1. Create the cluster and check the context

```bash
./up.sh                                   # poc/up.sh: kind cluster "argocd" + local registry + metrics-server
kubectl config current-context            # must print kind-argocd
```

### 2. Install Argo CD with server-side apply

The Argo CD CRDs are too large for client-side apply's annotation limit, so use `--server-side`.

```bash
kubectl create ns argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.6/manifests/install.yaml
kubectl -n argocd rollout status deploy --timeout=300s
kubectl -n argocd rollout status sts/argocd-application-controller --timeout=300s
```

PoC result: 7 pods Ready in 53 s.

### 3. Add one Application pinned to a commit

Save as `guestbook-app.yaml` (same as `poc/guestbook-app.yaml`):

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

> **arm64 hosts:** the upstream image `gcr.io/google-samples/gb-frontend:v5` is amd64-only and crash-loops on arm64. The `kustomize.images` override swaps in multi-arch nginx. On amd64 you can remove that block ([failures and workarounds](./poc/README.md#failures-and-workarounds)).

### 4. Add one ApplicationSet for many apps

Save as `appset.yaml` (same as `poc/appset.yaml`). Replace both `repoURL` values with your repo.

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

`missingkey=error` makes a template with a missing parameter fail instead of rendering an empty string.

> **Blast radius:** changes to an ApplicationSet, including deleting it, propagate to every Application it generated. The docs also tell you to "be aware of the security implications of ApplicationSets before using them" ([ApplicationSet docs](../../external-sources/argocd-applicationset-docs.md)). Review ApplicationSet changes like privileged config.

### 5. Apply and wait

```bash
kubectl apply -f guestbook-app.yaml -f appset.yaml
kubectl -n argocd get applications.argoproj.io    # repeat until all are Synced/Healthy
```

PoC result: guestbook Synced/Healthy at t+11 s; all 20 generated apps Synced/Healthy at t+94 s; no manual sync.

### 6. Check self-heal

```bash
kubectl -n guestbook scale deploy/kustomize-guestbook-ui --replicas=3
kubectl -n app-07 delete svc web
kubectl -n app-03 patch cm cfg-01 --type=merge -p '{"data":{"blob":"drift"}}'
```

PoC result: each change was reverted within about 1 s.

### 7. Check a Git-driven change

Change something in Git (the PoC set `app-05` replicas 1 → 2), push, and watch. Without a webhook the PoC took **189 s** to apply. If you need faster apply, configure a Git webhook; that step was not tested here.

## Troubleshooting (seen in the PoC)

| Symptom | Cause | Fix |
|---|---|---|
| App stays `Synced/Progressing`, pod in Error/CrashLoop with no logs | Image doesn't exist for the node's CPU architecture | Override the image (step 3) or use an amd64 node |
| `kubectl apply` of `install.yaml` fails on CRD annotations | Client-side apply annotation limit | Use `--server-side --force-conflicts` (step 2) |
| `kind create cluster` fails with `client rate limiter` | inotify limits too low | Raise them (see Prerequisites) |
| Git change takes ~3 min to land | No webhook; Argo CD polls the repo. The default interval is not in a preserved source (unverified) | Add a webhook |

## Cleanup

```bash
kubectl config current-context     # must be kind-argocd
kind delete cluster --name argocd --kubeconfig "$KUBECONFIG"
docker rm -f kind-registry
```

## Related

- [Report](./report.md)
- [PoC](./poc/README.md)
- [Findings](./findings.md)
- [Sources](./sources.md)
