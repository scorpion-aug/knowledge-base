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

### v2 architecture overview

- FACT: Crossplane v2 makes four major changes: composite resources are now namespaced, managed resources are now namespaced, composition supports any Kubernetes resource, and Operations enable operational workflows ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: In v2, an XR can compose any resource: a Crossplane MR (RDSInstance), a plain Kubernetes resource (Deployment, Service), or a third-party CR (CloudNativePG Cluster, Cluster API Cluster). You must grant Crossplane access to compose non-Crossplane resources via an RBAC ClusterRole that aggregates to Crossplane's primary ClusterRole ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md), [Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: Crossplane's service account has access to create, update, and delete any resource installed by a provider, or defined by an XRD. This includes all MRs and XRs. It also has access to some types of Kubernetes resources that it needs to function - for example it can create deployments. You must grant Crossplane access to compose any other kind of resource ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: The v2 XRD API is `apiVersion: apiextensions.crossplane.io/v2`. The `scope` field defaults to Namespaced. v1 XRD API scope defaults to LegacyCluster ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: Crossplane tracks changes to Compositions as Composition revisions. A composite resource can use a `compositionUpdatePolicy` to manually or automatically reference newer Composition revisions. The default is "Automatic." Change to `Manual` to prevent automatic upgrades ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- FACT: A composite resource can select a specific Composition revision via `compositionRevisionRef`, or select based on labels via `compositionRevisionSelector` ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- FACT: Crossplane adds the `crossplane.io/composite` label to all composed resources, matching the name of the composite ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- FACT: A composite resource has two status conditions: Synced and Ready. Synced is True when Crossplane can reconcile the XR. Ready is True when the composition function pipeline reports all composed resources are ready ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- FACT: Crossplane supports pausing composite resources via the `crossplane.io/paused` annotation, per-resource poll interval via `crossplane.io/poll-interval`, and immediate reconciliation via `crossplane.io/reconcile-requested-at` ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).

### Function architecture

- FACT: Installing a Function creates a function pod. Crossplane sends requests to this pod to ask it what resources to create when you create a composite resource. By default, the Function pod installs in `crossplane-system` ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: Function response caching (alpha, `--enable-function-response-cache`) stores function responses on disk based on a hash of the request. Only caches responses with a nonzero TTL. The cache stores files in `/cache/xfn/` in the Crossplane pod. For better performance, mount an emptyDir volume with `medium: Memory` ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: Crossplane advertises capabilities in every RunFunctionRequest. Functions should test for a capability before relying on the corresponding feature and fall back when it is absent. Capabilities include: CAPABILITY_CAPABILITIES, CAPABILITY_REQUIRED_RESOURCES, CAPABILITY_CREDENTIALS, CAPABILITY_CONDITIONS, CAPABILITY_REQUIRED_SCHEMAS ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- FACT: Functions can write to the pipeline context. Crossplane passes the context to all following functions. When Crossplane has called all functions it discards the pipeline context ([Compositions](../../external-sources/crossplane-compositions-docs.md)).

### Package manager

- FACT: Crossplane's package manager handles Providers, Functions, and Configurations as OCI packages from a container registry. Packages must use fully qualified registry URLs in v2 ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md), [Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: When Crossplane installs a different version of the same Provider package it creates a new revision. By default Crossplane maintains one Inactive revision. The `Active` package revision is the package controller actively reconciling resources ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Crossplane v2 automatically creates a default ManagedResourceActivationPolicy (MRAP) that activates all managed resources (`*`). You can replace it with a targeted MRAP that activates only the resources you need ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md), docs v2.4, fetched 2026-11-04).

### GitOps fit with Argo CD

- FACT: Argo CD is a declarative GitOps continuous delivery tool for Kubernetes ([Argo CD README](../../external-sources/argocd-argo-cd-readme.md), master, fetched 2026-11-03). It reconciles Application manifests from Git to cluster state.
- FACT: Crossplane XRs and Compositions are Kubernetes custom resources. They can be stored in Git and applied by Argo CD like any other manifest. Argo CD's health assessment for custom resources relies on the resource's status conditions; Crossplane XRs expose Synced and Ready conditions ([Composite Resources](../../external-sources/crossplane-composite-resources-docs.md)).
- OPINION: Crossplane and Argo CD operate at different layers. Argo CD is a GitOps reconciler: it applies manifests from Git to a cluster and reports drift. Crossplane is a control-plane framework: it defines new APIs (XRs) and reconciles them into cloud resources and Kubernetes objects. A typical pattern is: Argo CD applies the Crossplane XRDs, Compositions, ProviderConfigs, and XR instances from Git; Crossplane then reconciles those XRs into actual infrastructure. Argo CD manages the Crossplane configuration; Crossplane manages the infrastructure. This is complementary, not overlapping.
- OPINION: The namespaced XR/MR model in v2 fits Argo CD's ApplicationSet multi-tenancy model better than v1's cluster-scoped model: each tenant can have XRs in their own namespace, and Argo CD can sync them per-namespace.

### Multi-tenancy and RBAC

- FACT: Namespaced XRs and MRs enable fine-grained access control via Kubernetes namespaces ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)).
- FACT: The AWS provider supports two types of ProviderConfig: ProviderConfig (namespace-scoped, applies only to MRs in the same namespace) and ClusterProviderConfig (cluster-wide, applies to MRs across all namespaces) ([Providers](../../external-sources/crossplane-providers-docs.md)).
- FACT: Crossplane's RBAC manager automatically grants Crossplane access to Crossplane resources (MRs, XRs, etc.). You only need to create more ClusterRoles for other Kubernetes resources that your Operations or Compositions need to access ([Operation](../../external-sources/crossplane-operation-docs.md)).
- OPINION: The v2 namespaced model is a significant multi-tenancy improvement over v1. In v1, XRs were cluster-scoped and required claims for namespace-level isolation. In v2, XRs live in namespaces natively, so standard Kubernetes RBAC and namespace isolation apply directly. Combined with namespaced ProviderConfigs, this lets each team manage its own cloud resources without cluster-admin involvement.

### Scaling and provider memory

- FACT: v2 introduces managed resource definitions (MRDs) for selective activation of provider resources, reducing cluster overhead ([What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md)). Without MRDs, installing a large provider like provider-upjet-aws installs CRDs and controllers for every supported AWS service, consuming significant memory and etcd space.
- FACT: The default MRAP activates all managed resources (`*`); replacing it with a targeted MRAP that activates only needed resources reduces cluster overhead ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: provider-kubernetes builds one client per distinct ProviderConfig credential set and keeps it in an LRU cache, sized at startup from the cluster's ProviderConfigs (+10% or 4 entries headroom, min 8). It reports `provider_kubernetes_client_cache_size`, `..._entries`, `..._events_total` with hit/miss/evict labels. A sustained eviction rate means the credential sets in use no longer fit the bound ([provider-kubernetes README](../../external-sources/crossplane-provider-kubernetes-readme.md)).
- FACT: Function response caching (alpha) can reduce repeated function calls for expensive computations or external API calls ([Compositions](../../external-sources/crossplane-compositions-docs.md)).
- OPINION: The MRD/MRAP mechanism is the primary lever for controlling Crossplane's memory footprint. Large Upjet-generated providers install hundreds of CRDs; activating only what you use is essential for production. The function response cache is alpha and only useful for expensive functions; don't rely on it for general scaling.

## Alternatives

### Terraform/OpenTofu

- FACT: Upjet transforms Terraform providers into Crossplane providers. It generates Kubernetes CRDs, reconciliation controllers, and example manifests while providing runtime libraries for API conversions, Terraform state management, and resource lifecycle operations ([Upjet README](../../external-sources/crossplane-upjet-readme.md)).
- FACT: Crossplane behaves differently than Terraform for immutable fields: Terraform deletes and recreates a resource to change an immutable field. Crossplane never deletes a resource based on a `forProvider` change ([Managed Resources](../../external-sources/crossplane-managed-resources-docs.md)).
- FACT: provider-upjet-aws v2.9.0 pins Terraform AWS provider at v6.65.0 ([provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md)).
- OPINION: Terraform/OpenTofu is the incumbent for infrastructure-as-code with a mature plan-apply workflow and broad provider coverage. Crossplane (via Upjet) reuses Terraform's provider ecosystem but wraps it in Kubernetes controllers with continuous reconciliation. Choose Terraform when you want explicit plan-apply with human gates; choose Crossplane when you want Kubernetes-native APIs, continuous drift correction, and self-service control planes.

### Pulumi Kubernetes Operator

- OPINION: Pulumi's Kubernetes Operator runs Pulumi programs inside a cluster, similar to how Crossplane runs compositions. Pulumi supports multiple languages (TypeScript, Python, Go, .NET) while Crossplane compositions use function pipelines (YAML, CEL, Python, KCL, Go templates). Pulumi has its own state backend; Crossplane stores state in Kubernetes etcd. Not directly compared in sources; this is an architectural inference.

### AWS Controllers for Kubernetes (ACK)

- FACT: ACK is AWS-only service controllers ([sources](./sources.md)).
- OPINION: ACK is a single-cloud alternative with no composition layer. It maps AWS APIs directly to Kubernetes resources but doesn't let you define custom composite APIs or compose multiple resources. Choose ACK if you only use AWS and don't need composition; choose Crossplane for multi-cloud or custom API layers.

### Google Config Connector (KCC)

- FACT: KCC is GCP-only ([sources](./sources.md)).
- OPINION: Same pattern as ACK but for GCP. Single-cloud, no composition layer.

### kubernetes-sigs/kro

- FACT: kro is a Kubernetes SIG Cloud Provider subproject for composing Kubernetes resources via ResourceGraphDefinition, vendor-neutral, no provider layer ([sources](./sources.md)). Crossplane docs pin function-kro v0.3.0 as a composition function ([Get Started With Composition](../../external-sources/crossplane-get-started-composition.md)).
- OPINION: kro overlaps with Crossplane's composition layer but lacks the provider ecosystem (no managed resources for cloud APIs). Crossplane integrates kro as a composition function, so they interoperate. kro alone is not a Crossplane replacement for infrastructure management.

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|
| **Crossplane v2** | Kubernetes-native APIs; continuous reconciliation; multi-cloud via providers; namespaced XRs/MRs for multi-tenancy; composition of any K8s resource; Operations for one-shot tasks; CNCF Graduated | Function pipeline model has learning curve; Operations are alpha; large providers consume significant memory without MRDs; v2 removed native P&T and other v1 features | Medium-high: needs K8s cluster, Crossplane pods, provider pods, function pods; memory scales with active MRs | Medium: XRDs/Compositions are portable YAML, but the control-plane model is Crossplane-specific; migration to another tool means rewriting APIs |
| **Terraform/OpenTofu** | Mature plan-apply workflow; broad provider coverage; strong state management; large ecosystem | No continuous reconciliation; manual drift detection; not Kubernetes-native; state file management overhead | Low-medium: CLI tool, state backend (local/S3/Terraform Cloud) | Low: HCL is widely known; state can be imported/exported; OpenTofu fork reduces HashiCorp license risk |
| **Pulumi K8s Operator** | Multi-language support; familiar programming model; runs in-cluster | Pulumi-specific state backend; smaller community than Terraform; operator model less mature | Medium: needs K8s cluster, operator, Pulumi service or self-hosted backend | Medium: Pulumi programs are portable code, but the operator model ties you to Pulumi's state |
| **ACK** | AWS-native; direct API mapping; no composition overhead | AWS-only; no custom API layer; no composition | Low: single controller per AWS service | Low: standard K8s resources, but ACK-specific |
| **KCC** | GCP-native; direct API mapping | GCP-only; no custom API layer; no composition | Low: single controller | Low: standard K8s resources, but KCC-specific |
| **kro** | Vendor-neutral composition; simple ResourceGraphDefinition; SIG-sponsored | No provider layer; no cloud resource management; no package ecosystem | Low: single controller | Low: standard K8s CRDs |

## Migration path

### v1 to v2 upgrade

- FACT: Only upgrade to Crossplane v2 from Crossplane v1.20, the final v1.x release. If you're running an earlier version, upgrade to v1.20 first. Always upgrade one minor version at a time, using the most recent patch version available for each. Example path: v1.19 -> v1.20 -> v2.0 -> v2.1 ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: There's no automated tooling yet to migrate existing v1 cluster-scoped XRs and MRs to v2 namespaced style. You can upgrade to Crossplane v2 and start using the new namespaced features right away - your existing v1 resources continue working unchanged. See crossplane/crossplane#6726 for migration tooling progress ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: v2 removes: native patch-and-transform composition (deprecated v1.17), ControllerConfig type (deprecated v1.11), external secret stores (alpha, unmaintained), composite resource connection details (XRs only; MRs unaffected), and the default package registry flag ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: The Crossplane CLI can find removed features: run `crossplane beta upgrade check` with the v1.20 CLI against your control plane to scan for every removed feature and report resources that need attention ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: CLI conversion commands: `crossplane beta convert pipeline-composition` converts patch-and-transform Compositions to function pipelines; `crossplane beta convert deployment-runtime` converts ControllerConfig to DeploymentRuntimeConfig ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: The recommended upgrade approach: (1) prepare for upgrade (scan for removed features), (2) upgrade Crossplane core via Helm, (3) configure managed resource activation policies (MRAP), (4) upgrade providers to v2 versions, (5) start using v2 features ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: Existing Compositions work with Crossplane v2 with minimal changes. v2 managed resources are schematically identical to v1 managed resources - they're just namespaced. Don't update existing compositions that are actively used by composite resources in your control plane ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: To use v2 namespaced managed resources in compositions: update the API group from `.crossplane.io` to `.m.crossplane.io` (or `.upbound.io` to `.m.upbound.io`), and check the API version (v2 namespaced providers often reset to `v1beta1`). The `spec.forProvider` and `status.atProvider` fields are schematically identical ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: Namespace handling in compositions: Namespaced XRs - don't specify `metadata.namespace` in templates; Crossplane ignores template namespaces and uses the XR's namespace. Modern cluster-scoped XRs (`scope: Cluster`) - can compose resources in any namespace; include `metadata.namespace` in templates. Legacy cluster-scoped XRs (`scope: LegacyCluster`) - can't compose namespaced resources ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).
- FACT: Legacy resource behavior: existing v1 cluster-scoped XRs continue working with claims support; legacy cluster-scoped MRs continue working unchanged; existing Compositions continue working with legacy XRs. These use `LegacyCluster` scope internally and maintain full backward compatibility ([Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md)).

### From Terraform to Crossplane

- OPINION: There is no automated migration path from Terraform state to Crossplane managed resources. You would need to: (1) identify Terraform-managed resources, (2) import them into Crossplane by creating MRs with the correct external-name annotations and managementPolicies set to Observe, (3) gradually move management to Crossplane compositions. This is a manual, resource-by-resource process. The Upjet offline Plan server (alpha) may eventually help with previewing what Crossplane would change, but it's not a migration tool.

## Conflicting sources

- The [function-patch-and-transform README](../../external-sources/crossplane-function-patch-and-transform-readme.md) says "the Crossplane maintainers are considering deprecating native P&T" — this predates v2, which has already removed native P&T. The README's framing is outdated relative to the v2 docs.
- The [provider-upjet-aws v2.9.0 notes](../../external-sources/crossplane-provider-upjet-aws-v2-9-0-notes.md) say the Terraform AWS provider stays at v6.65.0. The [sources.md](./sources.md) screening table lists this as "pinned at 6.65.0" — consistent.
- The [What's New in v2](../../external-sources/crossplane-v2-whats-new-docs.md) docs say "Most users can upgrade to Crossplane v2 without breaking changes." The [Upgrade to Crossplane v2](../../external-sources/crossplane-upgrade-v2-guide.md) guide lists five removed features and says "If you're using any removed features, migrate away from them first." These are consistent if you read "most users" as "users who don't use the removed features."
- The [sources.md](./sources.md) screening table lists function-patch-and-transform tag v0.11.0 (2026-09-25) as referenced in examples, but the [Get Started With Composition](../../external-sources/crossplane-get-started-composition.md) guide pins v0.8.2. The docs page pins specific versions for reproducibility; the repo has moved forward. Trust the docs for a first install, but check the repo for the latest release.
- The [sources.md](./sources.md) screening table lists Crossplane latest release as v2.4.3 (2026-10-22), a security-patch release. The [README](../../external-sources/crossplane-core-readme.md) lists maintained releases v1.20-v2.7 with v1.20 EOL Nov 2026. Consistent.

## Open questions

- How does Crossplane v2 handle large-scale deployments (thousands of XRs)? The docs mention MRDs for reducing overhead but don't give specific numbers or benchmarks. (TODO: needs source)
- What is the memory/CPU overhead of the function pipeline model vs native P&T? Each function runs as a pod; the cumulative cost of many functions is not quantified in sources read. (TODO: needs source)
- How does the offline Plan/diff server integrate with CI/CD pipelines? It's alpha and the gRPC API is experimental; no production usage patterns documented. (TODO: needs source)
- What is the upgrade path from provider-upjet-aws v2.x to future v3.x? The v2.9.0 notes mention one breaking change but no forward-looking migration guide. (TODO: needs source)
- How do Operations interact with GitOps? An Operation creates resources directly; if those resources are also managed by Argo CD, there could be conflicts. (TODO: needs source)

## Requests for res-lab

- Question: Can a kind-only cluster run Crossplane v2 with provider-kubernetes and function-patch-and-transform to create a namespaced XR that composes a Deployment and Service? | Success criterion: `kubectl get app` returns SYNCED=True, READY=True; `kubectl get deploy,service -l example.crossplane.io/app=my-app` shows the created resources; no cloud credentials used. | Pinned versions: Crossplane v2.4.3, provider-kubernetes v1.0.0, function-patch-and-transform v0.8.2, kind v0.20.0, Kubernetes v1.31.
- Question: Does the v2 namespaced model work with Argo CD: can Argo CD apply an XRD, Composition, and XR to a cluster, and does Argo CD report the XR's health correctly via Synced/Ready conditions? | Success criterion: Argo CD Application for the XR shows Healthy and Synced; XR shows SYNCED=True, READY=True. | Pinned versions: Argo CD v2.13, Crossplane v2.4.3, provider-kubernetes v1.0.0.
- Question: Does the function response cache (alpha) improve reconciliation latency for a composition with an expensive function? | Success criterion: with `--enable-function-response-cache` and a TTL-including function, the second reconciliation of the same XR is measurably faster (compare `crossplane beta trace` or metrics) than without the cache. | Pinned versions: Crossplane v2.4.3 with alpha flags enabled, function-go-templating v0.9.2.
- Question: Can the offline diff server (provider-upjet-aws v2.9.0, alpha) produce a correct plan for an S3 Bucket MR without cloud credentials? | Success criterion: the diff-server gRPC call returns CREATE with correct field-level changes for a new Bucket MR; no AWS credentials in the environment. | Pinned versions: provider-upjet-aws v2.9.0, upjet design doc reference, Crossplane v2.4.3.
- Question: Does the upgrade path from Crossplane v1.20 to v2.4 work on a kind cluster with a legacy Composition using native patch-and-transform? | Success criterion: after `crossplane beta upgrade check` and `crossplane beta convert pipeline-composition`, the converted Composition works on v2.4; the legacy XR continues to reconcile; no data loss. | Pinned versions: Crossplane v1.20 CLI, Crossplane v2.4.3, function-patch-and-transform v0.8.2.

## Tentative recommendation

OPINION: Adopt Crossplane v2 for new control-plane work. The v2 namespaced model is a significant improvement over v1 for multi-tenancy and RBAC, the function pipeline model is more flexible than native patch-and-transform, and the provider ecosystem (especially Upjet-generated providers) gives broad cloud coverage. Target v2 only: v1.20 reaches EOL when v2.5 ships in November 2026 ([Crossplane README](../../external-sources/crossplane-core-readme.md)).

OPINION: Start with function-patch-and-transform for simple compositions (it carries the familiar v1 P&T model), then evaluate function-go-templating or function-kro for more complex logic. Avoid Operations in production until the feature matures past alpha.

OPINION: Use managed resource definitions (MRDs) and targeted ManagedResourceActivationPolicies from day one to control memory usage. Large Upjet providers install hundreds of CRDs; activate only what you need.

OPINION: Pair Crossplane with Argo CD for GitOps: Argo CD manages the Crossplane configuration (XRDs, Compositions, ProviderConfigs, XR instances) from Git; Crossplane manages the infrastructure. This gives you auditability and drift correction at both layers.

OPINION: Do not migrate existing v1 production workloads to v2 yet. The upgrade guide explicitly says there's no automated tooling for migrating v1 cluster-scoped XRs/MRs to v2 namespaced style, and existing v1 resources continue working unchanged. Plan the migration for when crossplane/crossplane#6726 lands or when you have bandwidth for manual migration.

## Related

- [Sources](./sources.md)
- PoC (to be created by res-lab at `research/crossplane/poc/README.md`)
- Report (to be created by res-writer at `research/crossplane/report.md`)
- [Argo CD findings](../argocd/findings.md) — GitOps core comparison, complementary to this doc
