#!/usr/bin/env bash
# flux-phase.sh: fresh kind cluster for the Flux footprint run, same 20-app repo as the Argo CD run.
# Expects: ./up.sh-equivalent infra (infra/), ./repo (git, 20 apps), .gitea-pass (umask 077), bin/flux-2.10.0
set -euo pipefail
cd "$(dirname "$0")"
: "${KUBECONFIG:?}"
kind delete cluster --name argocd --kubeconfig "$KUBECONFIG"
./infra/up.sh
ctx=$(kubectl config current-context); [[ $ctx == kind-* ]] || { echo "refusing: $ctx"; exit 1; }
kubectl apply -f infra/gitea.yaml
kubectl -n git rollout status deploy/gitea --timeout=300s
P=$(cat .gitea-pass)
kubectl -n git exec deploy/gitea -- gitea admin user create --username lab --password "$P" \
  --email lab@example.invalid --admin --must-change-password=false >/dev/null
for i in $(seq 30); do curl -sf http://127.0.0.1:30300/api/healthz >/dev/null && break; sleep 2; done
curl -sf -u "lab:$P" -H 'Content-Type: application/json' -X POST http://127.0.0.1:30300/api/v1/user/repos \
  -d '{"name":"gitops","default_branch":"main","private":false}' >/dev/null
git -C repo -c "credential.helper=!f(){ echo username=lab; echo password=$P; };f" \
  push -q http://127.0.0.1:30300/lab/gitops.git main
./bin/flux-2.10.0 install --version=v2.10.0
./flux-apps.sh | kubectl apply -f -
for i in $(seq 60); do
  r=$(kubectl -n flux-system get kustomizations.kustomize.toolkit.fluxcd.io -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c True || true)
  echo "t+$((i*10))s ready=$r/20"; [[ $r == 20 ]] && break; sleep 10; done
