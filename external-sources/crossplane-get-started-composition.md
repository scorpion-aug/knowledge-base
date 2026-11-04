---
title: Get Started With Composition (Crossplane docs v2.4)
description: "Hands-on guide: define an App XRD, install composition functions (go-templating, patch-and-transform, kro, python, kcl), configure a composition, create an App XR."
type: source
source_url: https://docs.crossplane.io/latest/get-started/get-started-with-composition/
media_type: text/html
author: Crossplane project (CNCF), docs CC-BY-4.0
date_fetched: 2026-11-04
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
---
# Get Started With Composition · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle of the page (language-variant composition YAML examples for YAML+CEL, Python and KCL). The head (XR/XRD definition, function installation for all five functions) and tail (use-the-custom-resource, next steps) are captured verbatim; the omitted middle is the per-language composition bodies, which follow the same pattern as the captured templated-YAML/Python examples. Nav menus and cookie boilerplate trimmed.

This guide shows how to create a new kind of custom resource named `App`. When a user calls the custom resource API to create an `App`, Crossplane creates a `Deployment` and a `Service`.

Crossplane calls this composition. The `App` is composed of the `Deployment` and the `Service`.

Tip: The guide shows how to configure composition using YAML, YAML+CEL, templated YAML, Python, and KCL. You can pick your preferred language.

An `App` custom resource looks like this:

```yaml
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  namespace: default
  name: my-app
spec:
  image: nginx
status:
  replicas: 2  # Copied from the Deployment's status
  address: 10.0.0.1  # Copied from the Service's status
```

The `App` is the custom API Crossplane users use to configure an app.

When users create an `App` Crossplane creates this `Deployment` and `Service`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: my-app-dhj3a
  labels:
    example.crossplane.io/app: my-app  # Copied from the App's name
spec:
  replicas: 2
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
        image: nginx  # Copied from the App's spec
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  name: my-app-03mda
  labels:
    example.crossplane.io/app: my-app
spec:
  selector:
    example.crossplane.io/app: my-app
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
```

Crossplane builds on Kubernetes, so users can use `kubectl` or any other tool from the Kubernetes ecosystem to work with apps.

## Prerequisites

This guide requires:

- A Kubernetes cluster with at least 2 GB of RAM
- Crossplane v2 installed on the Kubernetes cluster

## Create the custom resource

Follow these steps to create a new kind of custom resource using Crossplane:

1. Define the schema of the `App` custom resource
2. Install the function you want to use to configure how Crossplane composes apps
3. Configure how Crossplane composes apps

### Define the schema

Crossplane calls a custom resource that's powered by composition a composite resource, or XR.

Create this composite resource definition (XRD) to define the schema of the new `App` composite resource (XR).

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
  - name: v1
    served: true
    referenceable: true
    schema:
     openAPIV3Schema:
       type: object
       properties:
        spec:
          type: object
          properties:
            image:
              description: The app's OCI container image.
              type: string
          required:
          - image
        status:
          type: object
          properties:
            replicas:
              description: The number of available app replicas.
              type: integer
            address:
              description: The app's IP address.
              type: string
```

```shell
kubectl apply -f https://docs.crossplane.io/latest/manifests/get-started/composition/xrd.yaml
```

Check that Crossplane has established the XRD:

```shell
kubectl get -f https://docs.crossplane.io/latest/manifests/get-started/composition/xrd.yaml
NAME                         ESTABLISHED   OFFERED   AGE
apps.example.crossplane.io   True                    21s
```

### Install the function

You can use different composition functions to configure what Crossplane does when someone creates or updates a composite resource (XR). Composition functions are like configuration language plugins.

Pick what language to use to configure how Crossplane turns an `App` XR into a `Deployment` and a `Service`.

- Templated YAML
- YAML
- YAML+CEL
- Python
- KCL
- Pythonic

Templated YAML is a good choice if you're used to writing Helm charts.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-go-templating
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.9.2
```

YAML is a good choice for small, static compositions. It doesn't support loops or conditionals.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-patch-and-transform
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.8.2
```

YAML+CEL is a good choice for defining resources in plain YAML and wiring them together with CEL expressions. The function resolves dependencies between resources automatically.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-kro
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-kro:v0.3.0
```

Python is a good choice for compositions with dynamic logic. You can use the full Python standard library.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-python
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-python:v0.1.0
```

KCL is a good choice for compositions with dynamic logic. It's fast and sandboxed.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-kcl
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-kcl:v0.11.2
```

[... middle omitted — per-language composition bodies for YAML+CEL, Python and KCL; structure matches the captured templated-YAML example ...]

A composition can include multiple functions. Functions can change the results of earlier functions in the pipeline. Crossplane uses the result returned by the last function.

Tip: If you edit this composition to include a different kind of resource you might need to grant Crossplane access to compose it. Read the composition documentation to learn how to grant Crossplane access.

## Use the custom resource

Crossplane now understands `App` custom resources.

Create an `App`:

```yaml
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  namespace: default
  name: my-app
spec:
  image: nginx
```

Check that the `App` is ready:

```shell
kubectl get -f https://docs.crossplane.io/latest/manifests/get-started/composition/app.yaml
NAME     SYNCED   READY   COMPOSITION   AGE
my-app   True     True    app-yaml      56s
```

Note: The `COMPOSITION` column shows what composition the `App` is using. You can create multiple compositions for each kind of XR.

Check that Crossplane created a `Deployment` and a `Service`:

```shell
kubectl get deploy,service -l example.crossplane.io/app=my-app
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-app-2r2rk   2/2     2            2           11m

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/my-app-xfkzg   ClusterIP   10.96.148.56   <none>        8080/TCP   11m
```

Tip: Edit the `App`'s image; Crossplane updates the `Deployment`'s image to match. Delete the `App`; Crossplane deletes the `Deployment` and `Service`.

## Next steps

Managed resources (MRs) are ready-made Kubernetes custom resources. Crossplane has an extensive library of managed resources you can use to manage almost any cloud provider, or cloud native software. Get started with managed resources to learn more about them. You can use MRs with composition.
