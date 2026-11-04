---
title: "provider-kubernetes README (crossplane-contrib, main)"
description: "Crossplane provider for managing arbitrary Kubernetes objects; Object resource type, target-cluster client cache, known write-only-field limitations."
type: source
source_url: "https://raw.githubusercontent.com/crossplane-contrib/provider-kubernetes/main/README.md"
media_type: "text/markdown"
author: "crossplane-contrib"
date_fetched: "2026-11-04"
preservation: "text-extracted"
tags: [source, immutable, layer-ingest, text, crossplane]
---

# provider-kubernetes README (main, fetched 2026-11-04)

provider-kubernetes is a Crossplane Provider that enables deployment and management of arbitrary Kubernetes objects on clusters typically provisioned by Crossplane:

- A Provider resource type that only points to a credentials Secret.
- An Object resource type that manages Kubernetes Objects.
- A managed resource controller that reconciles Object typed resources.

## Install

```
crossplane xpkg install provider xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0
```

or by creating a Provider package resource with `spec.package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0`.

## Target cluster clients

The provider builds one client per distinct ProviderConfig credential set (kubeconfig plus identity) and keeps it in an LRU cache; at startup it sizes the cache from the cluster's ProviderConfigs (+10% or 4 entries headroom, min 8) and reports provider_kubernetes_client_cache_size, ..._entries, ..._events_total with hit/miss/evict labels. A sustained eviction rate means the credential sets in use no longer fit the bound. Client-side rate limiting disabled for cached clients; load bounded by --max-reconcile-rate and API Priority/Fairness. Watches (spec.watch: true) follow the credential set on rotation.

## Known limitations

Write-only fields cannot be reconciled (e.g. Secret.stringData): with server-side apply (default since v1.2.0) drift detection never sees them, and manifests whose owned fields are all absent from observed state fail with ExtractInto ... expected map, got nil and stick at Synced False. Prefer round-trippable fields: for Secrets set base64 data, not stringData. (Issue analysis: provider-kubernetes #420.)

## Developing locally

make && make local-dev starts a Kind cluster with Crossplane installed; make run (outside cluster, needs kubectl proxy) or make local-deploy (in-cluster). Requires a clusterrolebinding for the provider service account and a ProviderConfig (examples/namespaced/provider/...), then create Object resources (examples/namespaced/object/object.yaml).
