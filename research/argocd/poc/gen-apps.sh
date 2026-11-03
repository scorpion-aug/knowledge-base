#!/usr/bin/env bash
# Generate N apps under $OUT/apps/app-NN: namespace, pause Deployment, Service, CMS ConfigMaps of ~KB KiB each.
set -euo pipefail
OUT=${OUT:-./repo}; N=${N:-20}; CMS=${CMS:-50}; KB=${KB:-8}
pad=$(head -c $((KB*1024*3/4)) /dev/urandom | base64 -w0 | head -c $((KB*1024)))
for i in $(seq -w 1 "$N"); do
  d="$OUT/apps/app-$i"; ns="app-$i"; mkdir -p "$d"
  cat > "$d/workload.yaml" <<Y
apiVersion: v1
kind: Namespace
metadata: {name: $ns}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: web, namespace: $ns}
spec:
  replicas: 1
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      containers:
        - name: web
          image: registry.k8s.io/pause:3.10
          resources: {requests: {cpu: 1m, memory: 4Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: web, namespace: $ns}
spec: {selector: {app: web}, ports: [{port: 80}]}
Y
  : > "$d/configmaps.yaml"
  for c in $(seq -w 1 "$CMS"); do
    printf -- '---\napiVersion: v1\nkind: ConfigMap\nmetadata: {name: cfg-%s, namespace: %s}\ndata:\n  blob: "%s"\n' "$c" "$ns" "$pad" >> "$d/configmaps.yaml"
  done
done
echo "generated $N apps x $CMS configmaps x ${KB}KiB under $OUT/apps"
