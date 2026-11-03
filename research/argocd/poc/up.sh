#!/usr/bin/env bash
# Creates kind cluster "argocd" + local registry "kind-registry" (host 127.0.0.1:5001, in-cluster kind-registry:5000)
set -euo pipefail
NODE_IMAGE="kindest/node:v1.35.8@sha256:07b2536e30b803ed61d1677a79df6115f798ce64c80f9e22f6ed45afd09323c0"
: "${KUBECONFIG:?export KUBECONFIG to a kind-only kubeconfig}"
docker inspect kind-registry >/dev/null 2>&1 || docker run -d --restart=always --name kind-registry -p 127.0.0.1:5001:5000 registry:3.1.0
kind create cluster --name argocd --image "$NODE_IMAGE" --config "$(dirname "$0")/kind.yaml" --kubeconfig "$KUBECONFIG" --wait 120s
docker network connect kind kind-registry 2>/dev/null || true
for n in $(kind get nodes --name argocd); do
  docker exec "$n" mkdir -p /etc/containerd/certs.d/kind-registry:5000
  printf '[host."http://kind-registry:5000"]\n' | docker exec -i "$n" tee /etc/containerd/certs.d/kind-registry:5000/hosts.toml >/dev/null
done
ctx=$(kubectl config current-context); [[ $ctx == kind-* ]] || { echo "refusing: context $ctx"; exit 1; }
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.1/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s
