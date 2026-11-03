#!/usr/bin/env bash
# footprint.sh <tool: argocd|flux> <ns> — idle >=15 min, sample, force resync of all apps, sample again.
set -euo pipefail
tool=$1 ns=$2; cd "$(dirname "$0")"
ctx=$(kubectl config current-context); [[ $ctx == kind-* ]] || { echo "refusing: $ctx"; exit 1; }
echo "idle wait start $(date -u +%T)"; sleep "${IDLE:-900}"
./sample.sh "$tool idle (>=15m after Synced)" "$ns" 6 20 "raw-$tool-idle.txt"
echo "force resync $(date -u +%T)"
if [[ $tool == argocd ]]; then
  kubectl -n argocd annotate applications.argoproj.io --all argocd.argoproj.io/refresh=hard --overwrite >/dev/null
else
  for k in $(kubectl -n flux-system get kustomizations.kustomize.toolkit.fluxcd.io -o name); do
    ./bin/flux-2.10.0 reconcile ks "${k#*/}" --with-source >/dev/null 2>&1 & done
fi
sleep 5; ./sample.sh "$tool forced resync (all 20)" "$ns" 6 10 "raw-$tool-resync.txt"
wait || true
