#!/usr/bin/env bash
# flux-apps.sh: one GitRepository + one Kustomization per apps/app-NN dir (same repo/revision as the Argo CD ApplicationSet).
set -euo pipefail
N=${N:-20}
cat <<Y
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata: {name: gitops, namespace: flux-system}
spec:
  interval: 3m
  url: http://gitea.git.svc.cluster.local:3000/lab/gitops.git
  ref: {branch: main}
Y
for i in $(seq -w 1 "$N"); do cat <<Y
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata: {name: app-$i, namespace: flux-system}
spec:
  interval: 10m
  path: ./apps/app-$i
  prune: true
  sourceRef: {kind: GitRepository, name: gitops}
Y
done
