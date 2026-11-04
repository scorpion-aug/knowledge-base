---
date_fetched: 2026-11-04
preservation: text-extracted
media_type: text/html
author: Crossplane project (CNCF), docs CC-BY-4.0
description: "v1-to-v2 upgrade guide: removed features with CLI conversion commands, upgrade path (v1.20 -> v2.0 -> v2.x), MRAP configuration, provider upgrade, composition API group migration (.m.), legacy behavior."
title: Upgrade to Crossplane v2 (docs v2.4)
type: source
source_url: https://docs.crossplane.io/latest/guides/upgrade-to-crossplane-v2/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
---
# Upgrade to Crossplane v2 · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: full capture. Nav boilerplate trimmed.

Crossplane v2 introduces significant improvements while maintaining backward compatibility with most v1 configurations. This guide helps you upgrade from Crossplane v1.x to v2.

Learn about new features in Crossplane v2 including namespaced resources, the ability to compose any Kubernetes resource, and new operational workflows.

Important: Only upgrade to Crossplane v2 from Crossplane `v1.20`, the final `v1.x` release. If you're running an earlier version, upgrade to `v1.20` first.

Important: Always upgrade Crossplane one minor version at a time, using the most recent patch version available for each.

For example, if you are on `v1.19` and want to upgrade to `v2.1`, you should first upgrade to `v1.20`, then `v2.0`, before finally upgrading to `v2.1`. The upgrade path in this example looks like `v1.19` -> `v1.20` -> `v2.0` -> `v2.1`.

Note: There's no automated tooling yet to migrate existing v1 cluster-scoped XRs and MRs to v2 namespaced style. You can upgrade to Crossplane v2 and start using the new namespaced features right away - your existing v1 resources continue working unchanged. See crossplane/crossplane#6726 for migration tooling progress.

## Prerequisites

Before upgrading, ensure:

- You're running Crossplane v1.20
- You're not using deprecated features (see removed features)
- All packages use fully qualified image names
- Helm version v3.2.0 or later

## Removed features

Crossplane v2 removes these deprecated features:

- Native patch and transform composition
- ControllerConfig type
- External secret stores
- Composite resource connection details
- Default registry flag

Tip: The Crossplane CLI can find these features for you. Run `crossplane beta upgrade check` with the v1.20 CLI against your control plane to scan for every removed feature below and report the resources that need attention before you upgrade to v2.

### Native patch and transform composition

Deprecated in: v1.17. Replaced by: Composition functions

If you're using `spec.mode: Resources` in your Compositions, migrate to composition functions before upgrading.

Migration help: use the Crossplane v1.20 CLI to automatically convert your Compositions:

```shell
# Convert patch and transform to function pipelines
crossplane beta convert pipeline-composition old-composition.yaml -o new-composition.yaml
```

### ControllerConfig type

Deprecated in: v1.11. Replaced by: DeploymentRuntimeConfig

Update any ControllerConfig resources to use DeploymentRuntimeConfig instead.

Migration help: use the Crossplane v1.20 CLI to automatically convert your ControllerConfigs:

```shell
# Convert ControllerConfig to DeploymentRuntimeConfig
crossplane beta convert deployment-runtime controller-config.yaml -o deployment-runtime-config.yaml
```

### External secret stores

Status: alpha feature, unmaintained

If you're using external secret stores, migrate to native Kubernetes secrets or External Secrets Operator before upgrading.

### Composite resource connection details

Removed: composite resources no longer have native connection details support.

Tip: This only affects XRs, managed resources aren't affected.

Managed resources (MRs) still support the `writeConnectionSecretToRef` field on any MR spec.

You can recreate this feature by composing your own connection details `Secret` as described in the connection details composition guide.

### Default registry flag

Removed: `--registry` flag for default package registry

All packages must now use fully qualified names including the registry host name. Check your packages with:

Update any packages without registry host names before upgrading. For example:

- BAD: `crossplane-contrib/provider-aws-s3:v1.23.0`
- GOOD: `xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v1.23.0`

## Who can upgrade

You can upgrade to Crossplane v2 if you meet these criteria:

- Running Crossplane v1.20
- Not using native patch and transform composition
- Not using ControllerConfig resources
- Not using external secret stores
- All packages use fully qualified image names

If you're using any removed features, migrate away from them first.

## Upgrade approach

The recommended upgrade approach:

1. Prepare for upgrade
2. Upgrade Crossplane core
3. Configure managed resource activation policies
4. Upgrade providers
5. Start using v2 features

### 1. Prepare for upgrade

Review your cluster for removed features and address any that you're using. Each removed feature section includes commands to inspect your cluster and migration tools to help convert resources.

### 2. Upgrade Crossplane core

Add the Crossplane Helm repository:

```shell
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
```

Upgrade to Crossplane v2:

```shell
helm upgrade crossplane \
  --namespace crossplane-system \
  crossplane-stable/crossplane
```

Verify the upgrade:

```shell
kubectl get pods -n crossplane-system
```

### 3. Configure managed resource activation policies

Crossplane v2 automatically creates a default MRAP that activates all managed resources (`*`). Before installing v2 providers, you can optionally customize this for better cluster resource efficiency.

Check what managed resources you use:

```shell
# See your managed resource types
kubectl get managed
```

Optionally, replace the default MRAP with a targeted one that activates only the resources you need:

```shell
# Delete the default catch-all MRAP
kubectl delete mrap default
```

Create a targeted MRAP:

```yaml
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: ManagedResourceActivationPolicy
metadata:
  name: my-resources
spec:
  activate:
  # Legacy cluster-scoped resources (existing v1 resources)
  - buckets.s3.aws.upbound.io
  - instances.ec2.aws.upbound.io

  # Modern namespaced resources (new v2 resources)
  - buckets.s3.aws.m.upbound.io
  - instances.ec2.aws.m.upbound.io
```

Tip: Notice the distinction: `s3.aws.upbound.io` (legacy cluster-scoped) vs `s3.aws.m.upbound.io` (v2 namespaced). The `.m.` indicates modern namespaced managed resources.

### 4. Upgrade providers

Upgrade your providers to versions that support both namespaced and cluster-scoped managed resources:

```shell
# Check current provider versions
kubectl get providers
```

Update your provider manifests to use v2 versions:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-contrib-provider-aws-s3
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0
```

Note: Provider v2 releases support both legacy cluster-scoped and new namespaced managed resources. Your existing cluster-scoped MRs continue working unchanged.

### 5. Start using v2 features

After upgrading, you can begin using Crossplane v2 features:

- Namespaced managed resources: Try the managed resources getting started guide
- Composition functions: Follow the composition getting started guide
- Operations: Explore the operations getting started guide
- Managed resource definitions: See the MRDs guide

## Updating compositions for v2

Existing Compositions work with Crossplane v2 with minimal changes. v2 managed resources are schematically identical to v1 managed resources - they're just namespaced.

Important: Don't update existing compositions that are actively used by composite resources in your control plane.

Updating a live composition that's in use by existing XRs could disrupt or replace your resources. Use the below migration approach only when creating new compositions for new resources.

To use v2 namespaced managed resources in compositions:

1. Update the API group from `.crossplane.io` to `.m.crossplane.io`
2. Check the API version - v2 namespaced providers often reset the API version to `v1beta1`

For example `provider-aws-s3:v2.0.0` has two `Bucket` MRs:

- `apiVersion: s3.aws.upbound.io/v1beta2` - Legacy, cluster scoped
- `apiVersion: s3.aws.m.upbound.io/v1beta1` - Namespaced

The `spec.forProvider` and `status.atProvider` fields are schematically identical.

Tip: Use `kubectl get mrds` to see available MR API versions.

Note: Not all providers use `.crossplane.io` domains. For example, `provider-aws-s3` uses `.upbound.io` domains for historical reasons. The general pattern for namespaced resources is adding `.m` to the existing domain: `<domain>` becomes `m.<domain>` (like `upbound.io` -> `m.upbound.io` or `crossplane.io` -> `m.crossplane.io`).

Before (v1 cluster-scoped):

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: my-app
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1
    kind: XBucket
  mode: Pipeline
  pipeline:
  - step: create-bucket
    functionRef:
      name: crossplane-contrib-function-go-templating
    input:
      apiVersion: gotemplating.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline:
        template: |
          apiVersion: s3.aws.upbound.io/v1beta2
          kind: Bucket
          metadata:
            name: {{ .observed.composite.resource.metadata.name }}
          spec:
            forProvider:
              region: us-east-2
```

After (v2 namespaced):

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: my-app
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1
    kind: Bucket
  mode: Pipeline
  pipeline:
  - step: create-bucket
    functionRef:
      name: crossplane-contrib-function-go-templating
    input:
      apiVersion: gotemplating.fn.crossplane.io/v1beta1
      kind: GoTemplate
      source: Inline
      inline:
        template: |
          apiVersion: s3.aws.m.upbound.io/v1beta1  # Added .m, reset to v1beta1
          kind: Bucket
          metadata:
            name: {{ .observed.composite.resource.metadata.name }}
          spec:
            forProvider:
              region: us-east-2
```

Tip: Namespace handling in compositions:

- Namespaced XRs: Don't specify `metadata.namespace` in templates. Crossplane ignores template namespaces and uses the XR's namespace.
- Modern cluster-scoped XRs (`scope: Cluster`): Can compose resources in any namespace. Include `metadata.namespace` in templates to specify the target namespace.
- Legacy cluster-scoped XRs (`scope: LegacyCluster`): Can't compose namespaced resources.

## Legacy resource behavior

Your existing v1 resources continue working in Crossplane v2:

- Legacy cluster-scoped XRs: Continue working with claims support
- Legacy cluster-scoped MRs: Continue working unchanged
- Existing Compositions: Continue working with legacy XRs

These resources use `LegacyCluster` scope internally and maintain full backward compatibility.

For example, existing v1-style XRDs continue working with claims:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdatabases.example.crossplane.io
spec:
  # v1 XRDs default to LegacyCluster scope (shown explicitly)
  scope: LegacyCluster
  group: example.crossplane.io
  names:
    kind: XDatabase
    plural: xdatabases
  claimNames:
    kind: Database
    plural: databases
  # schema definition...
```

Users can create claims that work as before:

```yaml
apiVersion: example.crossplane.io/v1
kind: Database
metadata:
  name: my-database
  namespace: production
spec:
  engine: postgres
  size: large
```

## Next steps

After upgrading:

1. Explore namespaced resources: Try creating XRs and MRs in namespaces
2. Build app compositions: Use v2's ability to compose any Kubernetes resource
3. Try Operations: Experiment with operational workflows
4. Plan migration: Consider which existing resources to migrate to v2 patterns
