---
title: "What's New in v2? (Crossplane docs v2.4)"
description: "Crossplane v2's four major changes: namespaced XRs, namespaced MRs, composition supports any Kubernetes resource, and Operations. Lists breaking changes vs v1."
type: source
source_url: "https://docs.crossplane.io/latest/whats-new/"
media_type: "text/html"
author: "Crossplane project (CNCF), docs CC-BY-4.0"
date_fetched: "2026-11-04"
preservation: "text-extracted"
tags: [source, immutable, layer-ingest, text, crossplane]
---

# What's New in v2? · Crossplane v2.4 docs (fetched 2026-11-04)

Crossplane v2 makes Crossplane more useful, more intuitive, and less opinionated.

Crossplane v2 makes four major changes:

- Composite resources are now namespaced
- Managed resources are now namespaced
- Composition supports any Kubernetes resource
- Operations enable operational workflows

Crossplane v2 is better suited to building control planes for applications, not just infrastructure. It removes the need for awkward abstractions like claims and provider-kubernetes Objects.

Tip: Most users can upgrade to Crossplane v2 without breaking changes.

## Namespaced composite resources

XRs are namespaced by default. A namespaced XR can compose any resource in its namespace. All of an XR's Crossplane machinery moves under `spec.crossplane` (compositionRef, compositionRevisionRef, resourceRefs). XRDs get a `scope` field; defaults to Namespaced in the v2 XRD API (`apiVersion: apiextensions.crossplane.io/v2`). Cluster-scoped XRs compose cluster-scoped or any-namespaced resources. With namespaced XRs there is no longer a need for claims - the new v2-style XRs do not support claims. v1-style XRD API scope defaults to LegacyCluster, which supports claims and is backward compatible.

## Namespaced managed resources

All MRs become namespaced, e.g. `apiVersion: s3.aws.m.upbound.io/v1beta1`, kind Bucket, with `metadata.namespace`. Namespaced MRs work with or without composition; namespaces enable fine-grained access control. Namespaced AWS MRs fully available in v2; maintainers actively updating Azure, GCP, Terraform, Helm, GitHub MRs for namespaced support. Cluster-scoped MRs are considered legacy and will be deprecated/removed later. v2 also introduces managed resource definitions (MRDs) for selective activation of provider resources, reducing cluster overhead.

## Compose any resource

An XR can compose any resource: a Crossplane MR (RDSInstance), a plain Kubernetes resource (Deployment, Service), or a third-party CR (CloudNativePG Cluster, Cluster API Cluster). You must grant Crossplane access to compose non-Crossplane resources (see Compositions docs, Grant access to composed resources).

## Operations enable operational workflows

New `ops.crossplane.io` API: operations run function pipelines to completion, like a Kubernetes Job - certificate monitoring, rolling upgrades, scheduled maintenance, reacting to changes. Three modes: Operation (run once), CronOperation (schedule, e.g. `schedule: "0 6 * * *"`, mode Pipeline with steps referencing `functionRef: crossplane-contrib-function-python`), WatchOperation (run when resources change). Operations can read existing resources and optionally change them. Note: Operations are an alpha feature in v2.

## Backward compatibility - breaking changes

v2 removes:
- native patch-and-transform composition (deprecated v1.17; replaced by composition functions - see also the bundled Function Patch and Transform guide)
- the ControllerConfig type (deprecated v1.11; replaced by DeploymentRuntimeConfig)
- support for external secret stores (alpha for over 2 years, unmaintained)
- composite resource connection details support (recreate via composing your own connection Secret - connection-details composition guide; MR connection details unaffected)
- the default package registry (--registry flag dropped): packages must use fully qualified registry URLs in `spec.package`

Tooling: `crossplane beta upgrade check` with the v1.20 CLI scans a v1.x control plane for these features before upgrading. Existing Compositions need minor updates; follow the Upgrade to Crossplane v2 guide.
