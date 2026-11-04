---
date_fetched: 2026-11-04
preservation: text-extracted
media_type: text/html
author: Crossplane project (CNCF), docs CC-BY-4.0
description: "Provider concept page: install via Provider object or Helm, offline install, pull policy, revision activation/history, private registry, dependency management, ProviderConfig and ClusterProviderConfig for multi-account."
title: Providers (Crossplane docs v2.4)
type: source
source_url: https://docs.crossplane.io/latest/packages/providers/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
---
# Providers · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle (dependency management detail, revision upgrade mechanics, runtime configuration). The head (what providers are, install via Provider object, Helm install, offline install, install options: pull policy, revision activation, history limit, private registry, dependency skip, version constraints) and tail (ProviderConfig, namespaced ProviderConfig vs ClusterProviderConfig, multi-account) are captured verbatim. Nav boilerplate trimmed.

Providers enable Crossplane to provision infrastructure on an external service. Providers create new Kubernetes APIs and map them to external APIs.

Providers are responsible for all aspects of connecting to non-Kubernetes resources. This includes authentication, making external API calls and providing Kubernetes Controller logic for any external resources.

Examples of providers include:

- Provider AWS (crossplane-contrib/provider-upjet-aws)
- Provider Azure (upbound/provider-azure)
- Provider GCP (upbound/provider-gcp)
- Provider Kubernetes (crossplane-contrib/provider-kubernetes)

Providers define every external resource they can create in Kubernetes as a Kubernetes API endpoint. These endpoints are Managed Resources.

## Install a provider

Installing a provider creates new Kubernetes resources representing the Provider's APIs. Installing a provider also creates a Provider pod that's responsible for reconciling the Provider's APIs into the Kubernetes cluster. Providers constantly watch the state of the desired managed resources and create any external resources that are missing.

Install a Provider with a Crossplane `Provider` object setting the `spec.package` value to the location of the provider package.

For example, to install the AWS Provider:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-contrib-provider-aws-s3-s3
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0
```

By default, the Provider pod installs in the same namespace as Crossplane (`crossplane-system`).

Note: Providers are part of the `pkg.crossplane.io` group. The `meta.pkg.crossplane.io` group is for creating Provider packages.

### Install with Helm

Crossplane supports installing Providers during an initial Crossplane installation with the Crossplane Helm chart.

Use the `--set provider.packages` argument with `helm install`.

For example, to install the AWS S3 Provider:

```shell
helm install crossplane \
crossplane-stable/crossplane \
--namespace crossplane-system \
--create-namespace \
--set provider.packages='{xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0}'
```

### Install offline

Installing Crossplane Providers offline requires a local container registry like Harbor to host Provider packages. Crossplane only supports installing Provider packages from a container registry.

Crossplane doesn't support installing Provider packages directly from Kubernetes volumes.

### Installation options

Providers support multiple configuration options to change installation related settings.

Tip: Crossplane supports installations with image digests instead of tags to get deterministic and repeatable installations.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-contrib-provider-aws-s3
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-aws-s3@sha256:ee6bece46dbb54cc3f0233961f5baac317fa4e4a81b41198bdc72fc472d113d0
```

#### Provider pull policy

Use a `packagePullPolicy` to define when Crossplane should download the Provider package to the local Crossplane package cache.

The `packagePullPolicy` options are:

- `IfNotPresent` - (default) Only download the package if it isn't in the cache.
- `Always` - Check for new packages every minute and download any matching package that isn't in the cache.
- `Never` - Never download the package. Packages are only installed from the local package cache.

Tip: The Crossplane `packagePullPolicy` works like the Kubernetes container image image pull policy.

Crossplane supports the use of tags and package digest hashes like Kubernetes images.

#### Revision activation policy

The `Active` package revision is the package controller actively reconciling resources.

By default Crossplane sets the most recently installed package revision as `Active`.

Control the Provider upgrade behavior with a `revisionActivationPolicy`.

The `revisionActivationPolicy` options are:

- `Automatic` - (default) Automatically activate the last installed Provider.
- `Manual` - Don't automatically activate a Provider.

#### Package revision history limit

When Crossplane installs a different version of the same Provider package Crossplane creates a new revision.

By default Crossplane maintains one Inactive revision.

Change the number of revisions Crossplane maintains with a Provider Package `revisionHistoryLimit`.

The `revisionHistoryLimit` field is an integer. The default value is `1`. Disable storing revisions by setting `revisionHistoryLimit` to `0`.

#### Install a provider from a private registry

Like Kubernetes uses `imagePullSecrets` to install images from private registries, Crossplane uses `packagePullSecrets` to install Provider packages from a private registry.

Use `packagePullSecrets` to provide a Kubernetes secret to use for authentication when downloading a Provider package.

Important: The Kubernetes secret must be in the same namespace as Crossplane.

The `packagePullSecrets` is a list of secrets.

Note: Configured `packagePullSecrets` aren't passed to any Provider package dependencies.

#### Ignore dependencies

By default Crossplane installs any dependencies listed in a Provider package.

Crossplane can ignore a Provider package's dependencies with `skipDependencyResolution`.

#### Automatically update dependency versions

Crossplane can automatically upgrade a package's dependency version to the minimum valid version that satisfies all the constraints. It's an alpha feature that requires enabling with the `--enable-dependency-version-upgrades` flag.

Sometimes, Crossplane requires dependency version downgrade for proceeding with installations. Suppose configuration A, which depends on package X with the constraint `>=v0.0.0`, installs on the control plane. In this case, the package manager installs the latest version of package X, such as `v3.0.0`. Later, you decide to install configuration B, which depends on package X with the constraint `<=v2.0.0`. Since version `v2.0.0` satisfies both conditions, Crossplane must downgrade package X to allow the installation of configuration B, which Crossplane disables by default.

For enabling automatic dependency version downgrades, there is a configuration option as a helm value `packageManager.enableAutomaticDependencyDowngrade=true`. Downgrading a package can cause unexpected behavior, so this Crossplane disables this option by default. After enabling this option, the package manager automatically downgrades a package's dependency version to the maximum valid version that satisfies the constraints.

Important: Enabling automatic dependency downgrades may have unintended consequences, such as:

1. CRDs missing in the downgraded version, possibly leaving orphaned MRs without controllers to reconcile them.
2. Loss of data if downgraded CRD versions omit fields that you set before.
3. Changes in the CRD storage version, which may prevent package version update.

#### Ignore Crossplane version requirements

A Provider package may require a specific or minimum Crossplane version before installing. By default, Crossplane doesn't install a Provider if the Crossplane version doesn't meet the required version.

Crossplane can ignore the required version with `ignoreCrossplaneConstraints`.

### Manage dependencies

Providers packages may include dependencies on other packages including Configurations or other Providers.

If Crossplane can't meet the dependencies of a Provider package the Provider reports `HEALTHY` as `False`.

For example, this installation of the Getting Started Configuration is `HEALTHY: False`.

```shell
kubectl get providers
NAME                                     INSTALLED   HEALTHY   PACKAGE                                                       AGE
crossplane-contrib-provider-aws-s3       True        False     xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0   12s
```

To see more information on why the Provider isn't `HEALTHY` use `kubectl describe providerrevisions`.

[... middle omitted — provider revision mechanics and runtime configuration ...]

### Provider configuration

The `ProviderConfig` determines settings the Provider uses communicating to the external provider. Each Provider determines available settings of their `ProviderConfig`.

Provider authentication is usually configured with a `ProviderConfig`. For example, to use basic key-pair authentication with Provider AWS a `ProviderConfig` `spec` defines the `credentials` and that the Provider pod should look in the Kubernetes `Secrets` objects and use the key named `aws-creds`.

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  namespace: default
  name: aws-provider
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: creds
```

Important: Authentication configuration may be different across Providers.

#### ProviderConfig types

The AWS provider supports two types of ProviderConfig resources:

ProviderConfig (namespace-scoped):

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  namespace: default
  name: my-config
# Applies only to MRs in the same namespace
```

ClusterProviderConfig (cluster-wide):

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: my-cluster-config
# Applies to MRs across all namespaces
```

When referencing any ProviderConfig, managed resources must specify both `name` and `kind`:

```yaml
spec:
  providerConfigRef:
    name: my-cluster-config
    kind: ClusterProviderConfig
```

```yaml
spec:
  providerConfigRef:
    name: my-config
    kind: ProviderConfig  # References namespaced ProviderConfig
```

If you omit `providerConfigRef` entirely, it defaults to:

```yaml
spec:
  providerConfigRef:
    name: default
    kind: ClusterProviderConfig
```

ProviderConfig objects apply to individual Managed Resources. A single Provider can authenticate with multiple users or accounts through ProviderConfigs.

Each account's credentials tie to a unique ProviderConfig. When creating a managed resource, attach the desired ProviderConfig.

For example, two AWS ProviderConfigs, named `user-keys` and `admin-keys` use different Kubernetes secrets.

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  namespace: default
  name: user-keys
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: my-key
      key: secret-key
```

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  namespace: default
  name: admin-keys
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: admin-key
      key: admin-secret-key
```

Apply the ProviderConfig when creating a managed resource.

This creates an AWS `Bucket` resource using the `user-keys` ProviderConfig.

```yaml
apiVersion: s3.aws.m.upbound.io/v1beta1
kind: Bucket
metadata:
  namespace: default
  name: user-bucket
spec:
  forProvider:
    region: us-east-2
  providerConfigRef:
    name: user-keys
    kind: ProviderConfig
```

This creates a second `Bucket` resource using the `admin-keys` ProviderConfig.

```yaml
apiVersion: s3.aws.m.upbound.io/v1beta1
kind: Bucket
metadata:
  namespace: default
  name: admin-bucket
spec:
  forProvider:
    region: us-east-2
  providerConfigRef:
    name: admin-keys
    kind: ProviderConfig
```
