---
title: "Crossplane — findings"
description: "Concepts, architecture and trade-offs for using Crossplane v2 to build control planes: XRs, compositions, functions, providers, Operations, GitOps fit, alternatives and migration."
type: research-note
status: draft
date: 2026-11-04
author: res-researcher
cluster: crossplane
tags: [ research, provisional, research-team, findings, crossplane, kubernetes, gitops, control-plane ]
sources: [ { resource: ../../external-sources/crossplane-core-readme.md }, { resource: ../../external-sources/crossplane-v2-whats-new-docs.md }, { resource: ../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md }, { resource: ../../external-sources/crossplane-provider-kubernetes-readme.md }, { resource: ../../external-sources/crossplane-upjet-readme.md }, { resource: ../../external-sources/crossplane-get-started-composition.md }, { resource: ../../external-sources/crossplane-function-patch-and-transform-readme.md }, { resource: ../../external-sources/crossplane-compositions-docs.md }, { resource: ../../external-sources/crossplane-composite-resources-docs.md }, { resource: ../../external-sources/crossplane-managed-resources-docs.md }, { resource: ../../external-sources/crossplane-operations-docs.md }, { resource: ../../external-sources/crossplane-operation-docs.md }, { resource: ../../external-sources/crossplane-providers-docs.md }, { resource: ../../external-sources/crossplane-upgrade-v2-guide.md } ]
---

## Question

Should Crossplane v2 be the control-plane framework for managing infrastructure and applications on Kubernetes, and if so, what does the v2 usage model look like? Sub-questions: how do composition functions replace native patch-and-transform, how do providers and the package manager work, what do Operations add, and how does Crossplane fit with Argo CD?

**Rubric (headless, auto-confirmed 2026-11-04):**

1. Problem solved and core concepts (XR, XRD, Composition, function pipelines)
2. Architecture: v2 changes (namespaced XRs/MRs, compose any resource, Operations), providers, package manager
3. Managed resources: forProvider, cross-references, managementPolicies, Upjet
4. Operations: run-once function pipelines for operational tasks
5. GitOps fit with Argo CD: where Crossplane sits vs Argo CD
6. Multi-tenancy/RBAC: namespaced resources, ProviderConfig, RBAC aggregation
7. Scaling & provider memory: MRDs, function response cache, provider-kubernetes LRU
8. Alternatives: Terraform/OpenTofu, Pulumi K8s operator, ACK, KCC, kro
9. Trade-offs: operating cost, lock-in, migration path

**Success criteria:** every FACT cites a local `external-sources/` doc; OPINION lines are labeled; conflicts and unknowns are explicit; PoC requests have a success criterion and pinned versions.

## Context

res-scout screened 11 candidates in [sources](./sources.md). Core, docs v2.4, composition functions, provider-upjet-aws, provider-kubernetes and function-patch-and-transform got dig deeper; upjet and kro got watch; Google Config Connector, ACK and terraform-k8s got skip. This doc informs one decision: whether to adopt Crossplane v2 as the control-plane layer, and what the migration path looks like. Readers are platform engineers. Sources are dated 2026-11-04 unless noted.

## Problem solved

- FACT: Crossplane describes itself as "a framework for building cloud native control planes without needing to write code". It has "a highly extensible backend that enables you to build a control plane that can orchestrate applications and infrastructure no matter where they run, and a highly configurable frontend that puts you in control of the schema of the declarative API it offers" ([Crossplane README](../../external-sources/crossplane-core-readme.md), main, fetched 2026-11-04).
- FACT: Crossplane v2's four major changes are: composite resources are now namespaced, managed resources are now namespaced, composition supports any Kubernetes resource, and Operations enable operational workflows ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: Crossplane v2 "is better suited to building control planes for applications, not just infrastructure. It removes the need for awkward abstractions like claims and provider-kubernetes Objects" ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- OPINION: Crossplane solves the problem of exposing infrastructure and application APIs as Kubernetes-native custom resources, letting platform teams define their own APIs (XRs) and letting application teams consume them without knowing the underlying provider details. The v2 shift to namespaced resources and arbitrary Kubernetes composition makes it a general-purpose control-plane builder, not just an infrastructure provisioning tool.

## Core concepts

### Composite Resource (XR) and Composite Resource Definition (XRD)

- FACT: A composite resource (XR) is "a set of Kubernetes resources as a single Kubernetes object". Crossplane creates composite resources when users access a custom API, defined in the CompositeResourceDefinition ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: You use two Crossplane types to create a new custom API: a Composite Resource Definition (XRD) that defines the XR's schema, and a Composition that configures how the XR creates other resources ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- FACT: In v2, XRs are namespaced by default. A namespaced XR can compose any resource in its namespace. All of an XR's Crossplane machinery moves under `spec.crossplane` (compositionRef, compositionRevisionRef, resourceRefs). XRDs get a `scope` field; defaults to Namespaced in the v2 XRD API (`apiVersion: apiextensions.crossplane.io/v2`). Cluster-scoped XRs compose cluster-scoped or any-namespaced resources. With namespaced XRs there is no longer a need for claims - the new v2-style XRs do not support claims ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: v1-style XRD API scope defaults to LegacyCluster, which supports claims and is backward compatible ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).

### Composition and function pipelines

- FACT: A Composition is "a template for creating multiple Kubernetes resources as a single composite resource". A Composition composes individual resources together into a larger, reusable solution ([Compositions](../../external-sources/crossplane-compositions-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: In v2, a Composition is a pipeline of composition functions. Composition functions are "Crossplane extensions that template Crossplane resources". Crossplane calls the composition functions to determine what resources it should create when you create a composite resource ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: To use composition functions set the Composition `mode` to `Pipeline`. Define a `pipeline` of `steps`. Each `step` calls a Function via a `functionRef`. Some Functions also allow you to specify an `input`; the function defines the `kind` of input ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: When a Composition has a pipeline of two or more steps, Crossplane calls them all in order. It passes each Function the result of the previous Function. This enables powerful combinations of Functions ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: Composition functions don't run when you delete a composite resource. Crossplane handles deletion of composed resources automatically ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: v2 removes native patch-and-transform composition (deprecated v1.17; replaced by composition functions). The function-patch-and-transform composition function carries the v1 native patch-and-transform model forward ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md), [function-patch-and-transform README](../../external-sources/crossplane-function-patch-and-transform-readme.md), main, fetched 2026-11-04).
- FACT: function-patch-and-transform re-implements P&T as a pipeline step: everything is under `spec.pipeline[0].input.resources`, not `spec.resources`. It looks very similar to native P&T ([function-patch-and-transform README](../../external-sources/crossplane-function-patch-and-transform-readme.md)).
- FACT: The maintainers of function-patch-and-transform state: "There are a lot of good reasons to use a function to do P&T composition. In fact, it's so compelling that the Crossplane maintainers are considering deprecating native P&T" ([function-patch-and-transform README](../../external-sources/crossplane-function-patch-and-transform-readme.md)). Note: v2 has already removed native P&T; this README predates that removal.
- FACT: Available composition functions include: function-go-templating (v0.9.2), function-patch-and-transform (v0.8.2), function-kro (v0.3.0), function-python (v0.1.0), function-kcl (v0.11.2), and function-cue ([Get Started With Composition](../../external-sources/crossplane-get-started-composition.md), docs v2.4, fetched 2026-11-04).
- FACT: The Get Started guide shows five language options for composition: Templated YAML (Helm-like), YAML (small static compositions, no loops/conditionals), YAML+CEL (plain YAML wired with CEL expressions, dependencies resolved automatically), Python (full standard library), and KCL (fast and sandboxed) ([Get Started With Composition](../../external-sources/crossplane-get-started-composition.md)).

### Managed Resources (MRs)

- FACT: A managed resource (MR) "represents an external service in a Provider". When users create a new managed resource, the Provider reacts by creating an external resource inside the Provider's environment. Every external service managed by Crossplane maps to a managed resource ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: In v2, all MRs become namespaced, e.g. `apiVersion: s3.aws.m.upbound.io/v1beta1`, kind Bucket, with `metadata.namespace`. Namespaced MRs work with or without composition; namespaces enable fine-grained access control. Namespaced AWS MRs fully available in v2; maintainers actively updating Azure, GCP, Terraform, Helm, GitHub MRs for namespaced support. Cluster-scoped MRs are considered legacy and will be deprecated/removed later ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: v2 introduces managed resource definitions (MRDs) for selective activation of provider resources, reducing cluster overhead ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: The `spec.forProvider` of a managed resource maps to the parameters of the external resource. Crossplane considers the `forProvider` field the "source of truth" for external resources. Crossplane overrides any changes made to an external resource outside of Crossplane ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: Managed resources can reference other managed resources by external name, name reference (`nameRef`), selector (`matchLabels`), or controller reference (`matchControllerRef`) ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: Crossplane allows editing immutable fields of a managed resource but doesn't apply the change. Crossplane never deletes a resource based on a `forProvider` change. Terraform deletes and recreates a resource to change an immutable field; Crossplane only deletes an external resource if you delete its corresponding managed resource object from Kubernetes ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: Late initialization: Crossplane treats the managed resource as the source of truth by default; it expects to have all values under `spec.forProvider` including the optional ones. If not provided, Crossplane populates the empty fields with the values assigned by the provider ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: `initProvider` (beta) defines settings Crossplane applies only when creating a new managed resource. Crossplane ignores changes to `initProvider` fields after creation. Useful for initial values that a Provider may automatically change, like an auto scaling group ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: `managementPolicies` (beta, enabled by default) determine which actions Crossplane can take on a managed resource and its corresponding external resource. The Provider determines support for management policies ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).

### Operations (alpha)

- FACT: Operations are an alpha feature introduced in v2. An `Operation` runs a function pipeline once to completion to perform operational tasks that don't fit the typical resource creation pattern. Unlike compositions that continuously reconcile desired state, Operations focus on tasks like backups, rolling upgrades, configuration validation, and scheduled maintenance ([Operation](../../external-sources/crossplane-operation-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: Operations are like Kubernetes Jobs - they run once to completion rather than continuously reconciling. Like compositions, Operations use function pipelines to implement their logic, but they're designed for operational workflows instead of resource composition ([Operation](../../external-sources/crossplane-operation-docs.md)).
- FACT: Three modes: Operation (run once), CronOperation (schedule), WatchOperation (run when resources change) ([Operations](../../external-sources/crossplane-operations-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: You must enable Operations by adding `--enable-operations` to Crossplane's arguments ([Operation](../../external-sources/crossplane-operation-docs.md)).
- FACT: Operation functions vs composition functions: composition functions create and maintain resources with continuous reconciliation; operation functions perform operational tasks that run once to completion. Functions can support both modes by declaring the appropriate capabilities in their package metadata ([Operation](../../external-sources/crossplane-operation-docs.md)).
- FACT: Operations automatically retry when they fail. Each retry resets the entire pipeline. Operations use exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, then 60s max. After reaching `retryLimit` (default 5), the Operation becomes `Succeeded=False` ([Operation](../../external-sources/crossplane-operation-docs.md)).
- FACT: You can preview the output of any Operation using `crossplane operation render` locally with Docker. The CLI hides alpha commands by default; run `crossplane config set features.enableAlpha true` to make it visible ([Operation](../../external-sources/crossplane-operation-docs.md)).
- FACT: At launch, only function-python supports operations ([Operation](../../external-sources/crossplane-operation-docs.md)).
- OPINION: Operations fill a real gap: without them, Crossplane can only express continuously-reconciled desired state, not one-shot or scheduled tasks. But the feature is alpha, only function-python supports it at launch, and it requires a feature flag. Treat it as experimental.

### Providers and the package manager

- FACT: Providers enable Crossplane to provision infrastructure on an external service. Providers create new Kubernetes APIs and map them to external APIs. Providers are responsible for all aspects of connecting to non-Kubernetes resources including authentication, making external API calls and providing Kubernetes Controller logic for any external resources ([Providers](../../external-sources/crossplane-providers-docs.md), docs v2.4, fetched 2026-11-04).
- FACT: Examples of providers: provider-upjet-aws, provider-azure, provider-gcp, provider-kubernetes ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Install a Provider with a Crossplane `Provider` object setting `spec.package` to the provider package location, e.g. `xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0`. By default, the Provider pod installs in `crossplane-system` ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Crossplane supports installing Providers during initial installation with the Helm chart via `--set provider.packages='{xpkg.crossplane.io/...}'` ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Installing Crossplane Providers offline requires a local container registry like Harbor. Crossplane only supports installing Provider packages from a container registry, not directly from Kubernetes volumes ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Provider install options: `packagePullPolicy` (IfNotPresent/Always/Never), `revisionActivationPolicy` (Automatic/Manual), `revisionHistoryLimit` (default 1), `packagePullSecrets` for private registries, `skipDependencyResolution`, `ignoreCrossplaneConstraints` ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Crossplane supports image digests instead of tags for deterministic installations ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Crossplane v2 removes the default package registry (`--registry` flag dropped): packages must use fully qualified registry URLs in `spec.package` ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: Crossplane can automatically upgrade a package's dependency version to the minimum valid version that satisfies all constraints (alpha, requires `--enable-dependency-version-upgrades`). Automatic dependency downgrades are disabled by default; enable with `packageManager.enableAutomaticDependencyDowngrade=true`. Downgrading can cause CRDs missing, data loss, or storage version changes ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: ProviderConfig determines settings the Provider uses communicating to the external provider. The AWS provider supports two types: ProviderConfig (namespace-scoped, applies only to MRs in the same namespace) and ClusterProviderConfig (cluster-wide, applies to MRs across all namespaces). If you omit `providerConfigRef`, it defaults to `name: default, kind: ClusterProviderConfig` ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: A single Provider can authenticate with multiple users or accounts through ProviderConfigs. Each account's credentials tie to a unique ProviderConfig ([Providers](../../external-sources/crossplane-providers-docs.md)).

### Upjet

- FACT: Upjet is a code generation framework and Kubernetes controller runtime that transforms Terraform providers into Crossplane providers. It generates Kubernetes CRDs, reconciliation controllers, and example manifests while providing runtime libraries for API conversions, Terraform state management, and resource lifecycle operations. It powers the official AWS, Azure, and GCP providers along with 50+ community providers ([Upjet README](../../external-sources/crossplane-upjet-readme.md), main, fetched 2026-11-04).
- FACT: Upjet supports multiple Terraform execution modes: Terraform CLI (fork-based), Terraform Plugin SDK v2 (Go library, no CLI), Terraform Plugin Framework (protov6, no CLI) ([Upjet README](../../external-sources/crossplane-upjet-readme.md)).
- FACT: Upjet is ideal when a Terraform provider already exists for your target platform, you want Terraform's resource logic, broad coverage quickly. Consider a native provider when no TF provider exists, you need customized reconciliation, precise API control, or performance beyond Terraform execution ([Upjet README](../../external-sources/crossplane-upjet-readme.md)).
- FACT: provider-upjet-aws v2.9.0 (2026-10-08) introduces Plan: an offline, credential-free preview of what applying a managed resource would change, computed by the provider itself. It adds 26 new managed resources. The Terraform AWS provider stays at v6.65.0 ([provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md), fetched 2026-11-04).
- FACT: provider-upjet-aws v2.9.0 has one breaking change: OriginRequestPolicy.cloudfront external name is now the policy ID, not the name. Compositions setting the crossplane.io/external-name annotation to choose the policy name must be updated ([provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md)).
- FACT: The offline diff server (alpha) computes CREATE, UPDATE, REPLACE, NO_OP actions without connecting to Kubernetes or making cloud API calls. It accepts a PlanRequest with the desired resource, an optional actual resource, and an in-memory store with the required ProviderConfig and referenced Secrets. Supports namespaced and cluster-scoped MRs including previously served API versions. Runs without cloud credentials. Exposed via the internal diff-server subcommand (PlanService.Plan gRPC); advertised through the DiffServer package capability. Limitations: some resources need cloud calls during planning; accurate plans depend on complete observed state; the gRPC API is experimental; coverage varies between providers ([provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md)).
- OPINION: Upjet is the reason Crossplane has broad cloud coverage quickly, but it inherits Terraform's execution model and limitations. The offline Plan/diff server is a significant step toward Terraform-like plan workflows inside Crossplane, but it's alpha and coverage varies.

### provider-kubernetes

- FACT: provider-kubernetes is a Crossplane Provider that enables deployment and management of arbitrary Kubernetes objects on clusters typically provisioned by Crossplane. It provides: a Provider resource type that only points to a credentials Secret, an Object resource type that manages Kubernetes Objects, and a managed resource controller that reconciles Object typed resources ([provider-kubernetes README](../../external-sources/crossplane-provider-kubernetes-readme.md), main, fetched 2026-11-04).
- FACT: The provider builds one client per distinct ProviderConfig credential set (kubeconfig plus identity) and keeps it in an LRU cache. At startup it sizes the cache from the cluster's ProviderConfigs (+10% or 4 entries headroom, min 8) and reports metrics. A sustained eviction rate means the credential sets in use no longer fit the bound ([provider-kubernetes README](../../external-sources/crossplane-provider-kubernetes-readme.md)).
- FACT: Known limitation: write-only fields cannot be reconciled (e.g. Secret.stringData). With server-side apply (default since v1.2.0) drift detection never sees them, and manifests whose owned fields are all absent from observed state fail with `ExtractInto ... expected map, got nil` and stick at Synced False. Prefer round-trippable fields: for Secrets set base64 data, not stringData ([provider-kubernetes README](../../external-sources/crossplane-provider-kubernetes-readme.md)).
- OPINION: provider-kubernetes is useful for kind-only local demos (no cloud credentials needed) and for composing arbitrary Kubernetes objects, but the write-only-field limitation is a real gotcha for Secrets.

## Architecture

## Alternatives

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|

## Migration path

## Conflicting sources

## Open questions

## Requests for res-lab

- Question: … | Success criterion: … | Pinned versions: …

## Tentative recommendation

OPINION: …

## Related

- [Sources](./sources.md)
- [PoC](./poc/README.md)
- [Report](./report.md)
