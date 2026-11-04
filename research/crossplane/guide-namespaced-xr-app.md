---
author: res-writer
cluster: crossplane
date: 2026-11-04
description: "How-to, from the kind PoC only: install Crossplane 2.4.3, provider-kubernetes and fn-p&t, then compose a Deployment+Service from one namespaced App XR."
sources:
  - resource: ../../external-sources/crossplane-v2-whats-new-docs.md
  - resource: ../../external-sources/crossplane-providers-docs.md
  - resource: ../../external-sources/crossplane-compositions-docs.md
  - resource: ../../external-sources/crossplane-function-patch-and-transform-readme.md
  - resource: ../../external-sources/crossplane-composite-resources-docs.md
status: draft
tags:
  - research
  - provisional
  - research-team
  - guide
  - crossplane
  - kubernetes
  - kind
  - composition
title: "Crossplane — guide: compose an app with a namespaced XR"
type: research-note
---
> **Scope.** This guide covers only what the [crossplane PoC](./poc/README.md) actually ran: a kind-only cluster, Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2, composing a Deployment and a Service from one namespaced `App` object. It does **not** cover cloud providers, direct composition without provider-kubernetes `Object`s, Argo CD, Operations, or a v1→v2 upgrade; none of those were run. Background and trade-offs are in the [Crossplane report](./report.md).

## What you get

A platform team defines an `App` API once. An app team then writes about ten lines of YAML (`replicas`, `image`, `port`) in their namespace and gets a Deployment and a Service. Changing the `App` updates them, and deleting it removes them ([PoC — Result](./poc/README.md#result)).

Terms used below (defined in the [report's Concepts](./report.md#concepts)): **XR** = the `App` object users create; **XRD** = its schema; **Composition** = the pipeline that turns an XR into resources; **Object** = a provider-kubernetes managed resource that wraps one Kubernetes manifest.

## Prerequisites

From [PoC — Prerequisites](./poc/README.md#prerequisites) and [Environment](./poc/README.md#environment-and-pinned-versions):

- Docker and kind (PoC: kind v0.27.0, node image `kindest/node:v1.32.2`), Helm v3, kubectl.
- A kubeconfig used only for this kind cluster, exported as `KUBECONFIG`.
- Approval to install cluster-wide packages (the Crossplane Helm release plus a provider and a function).

Create the cluster and check you are pointed at it:

```bash
kind create cluster --name crossplane
kubectl config current-context          # must print kind-crossplane
```

(The PoC record shows the context check and the delete command, not the create command. The `kind create` line above is inferred from the cluster name `crossplane`; the exact flags and kubeconfig handling were not recorded.)

## 1. Install Crossplane core

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system --create-namespace --version 2.4.3 --wait --timeout 5m
```

Expected: `crossplane` and `crossplane-rbac-manager` pods `1/1 Running` in `crossplane-system` ([PoC — Output](./poc/README.md#output-trimmed)).

## 2. Namespace, provider and function

`00-namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
```

`01-provider.yaml` installs provider-kubernetes with its own ServiceAccount and lets it manage objects on this same cluster:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1
  runtimeConfigRef:
    apiVersion: pkg.crossplane.io/v1beta1
    kind: DeploymentRuntimeConfig
    name: provider-kubernetes
---
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: provider-kubernetes
spec:
  serviceAccountTemplate:
    metadata:
      name: provider-kubernetes
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-cluster-admin
subjects:
  - kind: ServiceAccount
    name: provider-kubernetes
    namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

> **Lab only.** The `cluster-admin` binding is a PoC shortcut. A least-privilege role was not tested; don't copy this to a shared cluster.

`03-function.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.11.2
```

Apply and wait. Package names must be fully qualified (`xpkg.crossplane.io/...`) because v2 dropped the default registry ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).

```bash
cd poc && kubectl apply -f 00-namespace.yaml -f 01-provider.yaml -f 03-function.yaml
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=180s
kubectl wait --for=condition=Healthy function.pkg.crossplane.io/function-patch-and-transform --timeout=180s
```

Use the full resource names (`providers.pkg.crossplane.io`, `functions.pkg.crossplane.io`) when you `kubectl get` these; the short alias was ambiguous in the PoC ([PoC — Failures](./poc/README.md#failures-and-workarounds)).

## 3. ProviderConfig (no credentials)

Apply this **only after** the provider is `Healthy`. The `ProviderConfig` kind comes from the provider package, so applying it earlier fails with `no matches for kind "ProviderConfig"` ([PoC — Failures](./poc/README.md#failures-and-workarounds)).

`02-provider-config.yaml`:

```yaml
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
  namespace: demo
spec:
  credentials:
    source: InjectedIdentity
```

`InjectedIdentity` means the provider talks to its own cluster's API server with its own ServiceAccount, so there is no kubeconfig Secret or cloud key. This ProviderConfig is namespaced, so it serves MRs in `demo` only ([Providers](../../external-sources/crossplane-providers-docs.md)).

```bash
kubectl apply -f 02-provider-config.yaml
```

## 4. Why two layers (XRD + Composition)

The XRD defines *what users may ask for*. The Composition defines *what Crossplane builds* for each request. In v2 the Composition is a pipeline of function steps ([Compositions](../../external-sources/crossplane-compositions-docs.md)); here there is one step, fn-p&t, which takes base resources and copies fields from the XR into them with `patches` ([fn-p&t README](../../external-sources/crossplane-function-patch-and-transform-readme.md)).

## 5. Define the API and the composition

`04-xrd.yaml`, a namespaced v2 XRD:

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: apps.example.crossplane.io
spec:
  scope: Namespaced
  group: example.crossplane.io
  names:
    kind: App
    plural: apps
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
                image:
                  type: string
                port:
                  type: integer
              required:
                - replicas
                - image
                - port
```

`05-composition.yaml`. Each base is an `Object` wrapping one manifest; `watch: true` turns on the provider's realtime watch on the composed object:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: apps.example.crossplane.io
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1alpha1
    kind: App
  mode: Pipeline
  pipeline:
    - step: app-bundle
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: deployment
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                watch: true
                providerConfigRef:
                  kind: ProviderConfig
                  name: kubernetes-provider
                forProvider:
                  manifest:
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: my-app
                      namespace: demo
                      labels:
                        example.crossplane.io/app: my-app
                    spec:
                      selector:
                        matchLabels:
                          example.crossplane.io/app: my-app
                      template:
                        metadata:
                          labels:
                            example.crossplane.io/app: my-app
                        spec:
                          containers:
                            - name: app
                              image: nginx:1.27-alpine
                              ports:
                                - containerPort: 80
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
              - type: FromCompositeFieldPath
                fromFieldPath: spec.image
                toFieldPath: spec.forProvider.manifest.spec.template.spec.containers[0].image
          - name: service
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                watch: true
                providerConfigRef:
                  kind: ProviderConfig
                  name: kubernetes-provider
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: Service
                    metadata:
                      name: my-app
                      namespace: demo
                      labels:
                        example.crossplane.io/app: my-app
                    spec:
                      selector:
                        example.crossplane.io/app: my-app
                      ports:
                        - port: 80
                          targetPort: 80
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.port
                toFieldPath: spec.forProvider.manifest.spec.ports[0].port
```

Note: the manifests hard-code `name: my-app` and `namespace: demo`, so this Composition serves exactly one `App` named `my-app`. That was enough for the PoC. Making names follow the XR needs extra patches that were not tested.

```bash
kubectl apply -f 04-xrd.yaml -f 05-composition.yaml
```

## 6. Create the App (what users write)

`06-xr.yaml`:

```yaml
apiVersion: example.crossplane.io/v1alpha1
kind: App
metadata:
  name: my-app
  namespace: demo
spec:
  crossplane:
    compositionRef:
      name: apps.example.crossplane.io
  replicas: 2
  image: nginx:1.27-alpine
  port: 80
```

```bash
kubectl apply -f 06-xr.yaml
kubectl wait --for=condition=Ready app/my-app -n demo --timeout=120s
kubectl get apps.example.crossplane.io -n demo
kubectl get deploy,service -n demo -l example.crossplane.io/app=my-app
```

What the PoC saw ([PoC — Output](./poc/README.md#output-trimmed)):

```text
NAME     SYNCED   READY   COMPOSITION                  COMPOSITIONREVISION          AGE
my-app   True     True    apps.example.crossplane.io   apps.example.crossplane.io-…  44s

NAME                  KIND         PROVIDERCONFIG        SYNCED   READY
my-app-eafa7c4f05bf   Deployment   kubernetes-provider   True     True
my-app-f2568632d991   Service      kubernetes-provider   True     True

deployment.apps/my-app   2/2 ready   nginx:1.27-alpine
service/my-app           ClusterIP   80/TCP
```

`SYNCED=True` means Crossplane could reconcile the XR; `READY=True` means all composed resources report ready ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).

## 7. Update and delete

Change the XR, not the Deployment or Service:

```bash
kubectl patch app my-app -n demo --type=merge -p '{"spec":{"port":8080,"replicas":3}}'
```

```text
replicas=3/3 svc-port=8080  (applied in ~10s)
```

Delete the XR to remove everything it composed:

```bash
kubectl delete app my-app -n demo --wait=true
```

```text
app "my-app" deleted -> no Object MRs, no Deployment, no Service remain
```

## 8. What to expect from drift

Drift = someone edits the Deployment or Service directly. From [PoC — Drift reconcile details](./poc/README.md#drift-reconcile-details):

| Edit made directly on the composed object | With `watch: true` (as above) |
|---|---|
| Delete the Service | Recreated in ~20s |
| Change a leaf field (Service selector label) | Reverted in ~2s |
| Change a list item (`spec.ports[0].port` via `kubectl patch`) | **Not reverted.** Object goes `Synced=False (ReconcileError)` |

Without `watch: true`, a port edit was still there after 2 minutes (res-lab reports a 10-minute provider poll default from source code; `unverified` in KB sources).

If you hit the list-field case, the symptom is the composed Object MR showing `Synced=False` with a `cannot apply object: ... spec.ports[0].name Required value` error (as in the PoC). The PoC did not test a recovery step. The safe rule is: don't hand-edit composed objects; change the `App` instead.

## 9. Clean up

```bash
kubectl config current-context     # must be kind-crossplane
kind delete cluster --name crossplane --kubeconfig "$KUBECONFIG"
```

## Not covered here

Listed in [report — Gaps](./report.md#gaps): direct composition of Deployment/Service without `Object`, least-privilege provider RBAC, per-XR resource names, recovery from the list-field drift error, cloud providers, Argo CD, Operations, and the v1→v2 upgrade.

## Related

- [Crossplane report](./report.md)
- [PoC](./poc/README.md)
- [Findings](./findings.md)
- [Sources](./sources.md)
