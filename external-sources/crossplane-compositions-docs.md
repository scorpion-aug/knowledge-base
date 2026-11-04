---
date_fetched: 2026-11-04
preservation: text-extracted
media_type: text/html
author: Crossplane project (CNCF), docs CC-BY-4.0
description: "Composition concept page: pipeline mode, function installation/verification, multi-function pipelines, compositeTypeRef matching, RBAC for composed resources, capabilities, response cache."
title: Compositions (Crossplane docs v2.4)
type: source
source_url: https://docs.crossplane.io/latest/composition/compositions/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
---
# Compositions · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle (RBAC ClusterRole YAML for granting access to composed resources, function-writing guide). The head (what compositions are, function installation, pipeline mode, function pipelines, compositeTypeRef, grant-access intro) and tail (capabilities table, function pipeline context, response cache) are captured verbatim. Nav boilerplate trimmed.

Compositions are a template for creating multiple Kubernetes resources as a single composite resource.

A Composition composes individual resources together into a larger, reusable, solution.

An example Composition may combine a virtual machine, storage resources and networking policies. A Composition template links all these individual resources together.

Here's an example Composition. When you create an `AcmeBucket` composite resource (XR) that uses this Composition, Crossplane uses the template to create the Amazon S3 `Bucket` managed resource.

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: example
spec:
  compositeTypeRef:
    apiVersion: custom-api.example.org/v1alpha1
    kind: AcmeBucket
  mode: Pipeline
  pipeline:
  - step: patch-and-transform
    functionRef:
      name: function-patch-and-transform
    input:
      apiVersion: pt.fn.crossplane.io/v1beta1
      kind: Resources
      resources:
      - name: storage-bucket
        base:
          apiVersion: s3.aws.m.upbound.io/v1beta1
          kind: Bucket
          spec:
            forProvider:
              region: "us-east-2"
```

## What are XRs, XRDs and Compositions?

A composite resource or XR is a custom API.

You use two Crossplane types to create a new custom API:

- A Composite Resource Definition (XRD) - Defines the XR's schema.
- A Composition - Configures how the XR creates other resources.

## Create a composition

Creating a Composition consists of:

- Using composition functions to define the resources to create.
- Enabling composite resources to use the Composition template.

A Composition is a pipeline of composition functions.

Composition functions (or just functions, for short) are Crossplane extensions that template Crossplane resources. Crossplane calls the composition functions to determine what resources it should create when you create a composite resource (XR).

Tip: Crossplane has functions that let you template composed resources using YAML patch and transforms, Helm-like YAML templates, CUE, KCL, or Python. You can also write your own function using Go or Python.

### Install a composition function

Installing a Function creates a function pod. Crossplane sends requests to this pod to ask it what resources to create when you create a composite resource.

Install a Function with a Crossplane `Function` object setting the `spec.package` value to the location of the function package.

For example, to install Function Patch and Transform:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.8.2
```

Tip: Functions are Crossplane Packages. By default, the Function pod installs in the same namespace as Crossplane (`crossplane-system`).

### Verify a composition function

View the status of a Function with `kubectl get functions`. During the install a Function reports `INSTALLED` as `True` and `HEALTHY` as `Unknown`. After the Function install completes and it's ready for use the `HEALTHY` status reports `True`.

### Use a function in a composition

Crossplane calls a Function to determine what resources it should create when you create a composite resource. The Function also tells Crossplane what to do with these resources when you update a composite resource.

Note: Composition functions don't run when you delete a composite resource. Crossplane handles deletion of composed resources automatically.

When Crossplane calls a Function it sends it the current state of the composite resource. It also sends it the current state of any resources the composite resource owns.

Crossplane knows what Function to call when a composite resource changes by looking at the Composition the composite resource uses.

To use composition functions set the Composition `mode` to `Pipeline`. Define a `pipeline` of `steps`. Each `step` calls a Function. Each `step` uses a `functionRef` to reference the `name` of the Function to call. Some Functions also allow you to specify an `input`. The function defines the `kind` of input.

### Use a pipeline of functions in a composition

Crossplane can ask more than one Function what to do when a composite resource changes. When a Composition has a pipeline of two or more steps, Crossplane calls them all. It calls them in the order they appear in the pipeline.

Crossplane passes each Function in the pipeline the result of the previous Function. This enables powerful combinations of Functions. In this example, Crossplane calls `function-cue` to create an S3 bucket. Crossplane then passes the bucket to `function-auto-ready`, which marks the composite resource as ready when the bucket becomes ready.

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
spec:
  mode: Pipeline
  pipeline:
  - step: cue-export-resources
    functionRef:
      name: function-cue
    input:
      apiVersion: cue.fn.crossplane.io/v1beta1
      kind: CUEInput
      name: storage-bucket
      export:
        target: Resources
        value: |
          apiVersion: "s3.aws.m.upbound.io/v1beta1"
          kind: "Bucket"
          spec: forProvider: region: "us-east-2"
  - step: automatically-detect-readiness
    functionRef:
      name: function-auto-ready
```

### Match composite resources

A Composition is only a template defining how to create composed resources. A Composition limits which kind of composite resource (XR) can use this template. A Composition's `compositeTypeRef` defines which Composite Resource type can use this Composition.

### Grant access to composed resources

Crossplane uses its service account to create the composed resources that a function pipeline returns. Crossplane's service account has access to create, update, and delete any resource installed by a provider, or defined by an XRD. This includes all MRs and XRs. It also has access to some types of Kubernetes resources that it needs to function - for example it can create deployments.

You must grant Crossplane access to compose any other kind of resource. You do this by creating an RBAC ClusterRole. The ClusterRole must aggregate to Crossplane's primary ClusterRole using ClusterRole aggregation.

[... middle omitted — ClusterRole YAML example and write-your-own-function guide ...]

## Function capabilities

Crossplane advertises which features it supports when calling a function. When a function uses a feature (for example, required schemas or conditions) with an older Crossplane that doesn't support it, Crossplane ignores the unknown fields. The function has no way to know whether Crossplane honored its request.

Capability advertisement fixes this problem. Crossplane sends the list of supported capabilities in every RunFunctionRequest. Functions should test for a capability before relying on the corresponding feature and fall back when it is absent.

| Capability | Meaning |
| --- | --- |
| `CAPABILITY_CAPABILITIES` | Crossplane advertises capabilities; if another capability is absent, Crossplane doesn't support it. |
| `CAPABILITY_REQUIRED_RESOURCES` | Crossplane supports `requirements.resources` and populates `required_resources`. |
| `CAPABILITY_CREDENTIALS` | Crossplane supports credentials from the Composition. |
| `CAPABILITY_CONDITIONS` | Crossplane supports status conditions in the function response. |
| `CAPABILITY_REQUIRED_SCHEMAS` | Crossplane supports `requirements.schemas` and populates `required_schemas`. |

Function SDKs provide helpers such as `has_capability` and `get_required_schema`.

### Function pipeline context

Sometimes two functions in a pipeline want to share information with each other that isn't desired state. Functions can use context for this. Any function can write to the pipeline context. Crossplane passes the context to all following functions. When Crossplane has called all functions it discards the pipeline context.

### Function response cache

Note: Function response caching is an alpha feature. Enable it by setting the `--enable-function-response-cache` feature flag.

Crossplane can cache function responses to improve performance by reducing repeated function calls. When enabled, Crossplane caches responses from composition functions that include a time to live (TTL) value.

The cache works by:

- Storing function responses on disk based on a hash of the request
- Only caching responses with a nonzero TTL
- Automatically removing expired cache entries
- Reusing cached responses for identical requests until they expire

This feature helps functions that:

- Perform expensive computations or external API calls
- Return stable results for the same inputs
- Include appropriate TTL values in their responses

#### Cache configuration

Control the cache behavior with these Crossplane pod arguments:

- `--xfn-cache-max-ttl` - Maximum cache duration (default: 24 hours)

The cache stores files in the `/cache/xfn/` directory in the Crossplane pod. For better performance, consider using an in-memory cache by mounting an emptyDir volume with `medium: Memory`.
