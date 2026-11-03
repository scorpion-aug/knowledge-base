---
author: Flux project (CNCF); release signed by Matheus Pimenta
date_fetched: 2026-11-03
description: "Flux v2.10.0 is a feature release: object identity GA, SPIFFE mTLS, notification APIs v1, image update batching, Flux artifact storage for ImageRepository tags."
media_type: text/html
preservation: text-extracted
source_url: https://github.com/fluxcd/flux2/releases/tag/v2.10.0
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - argocd
title: Flux v2.10.0 release notes
type: source
---
> Fetched from the GitHub release page for fluxcd/flux2 v2.10.0. Highlights, compatibility, upgrade procedure and components changelog kept verbatim. The long CLI changelog (PR list), the New Contributors list and the Assets list were trimmed; see the source URL for them. Link targets dropped.

# v2.10.0

- Tag: v2.10.0
- Commit: 3fa784e
- github-actions released this 26 Oct 15:37 (2026-10-26T15:37:42Z)
- Verified signature: matheuscscp Matheus Pimenta, GPG key ID: FAC05FB85518B63C

## Highlights

Flux v2.10.0 is a feature release. Users are encouraged to upgrade for the best experience.

Overview of the new features:

- Object identity is generally available; the `ObjectLevelWorkloadIdentity` feature gate is retired
- SPIFFE mTLS for inter-controller communication
- Notification `Event`, `Alert` and `Provider` APIs promoted to `v1`
- `OCIRepository` as a chart source for `HelmRelease`
- SOPS decryption for files encrypted with comment regexes, and `--override-manager-before-dry-run` (`Kustomization`)
- Image update batching with `.spec.policyChangeDelay`, retry on rejected pushes, and `.Changed.Summary` (`ImageUpdateAutomation`)
- Flux artifact storage backend enabled by default for `ImageRepository` tags
- Cross-namespace artifacts, tenant namespace provisioning, and path-pattern discovery (`ArtifactGenerator`)
- New Zoom, incident.io and Mastodon notification providers
- Built with Kubernetes 1.37 and Go 1.27

Big thanks to all the Flux contributors that helped us with this release!

### Kubernetes compatibility

This release is compatible with the following Kubernetes versions:

| Kubernetes version | Minimum required |
|---|---|
| `v1.35` | `>= 1.35.2` |
| `v1.36` | `>= 1.36.1` |
| `v1.37` | `>= 1.37.0` |

Note

Note that the Flux project offers support only for the latest three minor versions of Kubernetes. Backwards compatibility with older versions of Kubernetes and OpenShift is offered by vendors such as ControlPlane that provide enterprise support for Flux.

### OpenShift compatibility

Flux can be installed on Red Hat OpenShift cluster directly from OperatorHub using Flux Operator. The operator allows the configuration of Flux multi-tenancy lockdown, network policies, persistent storage, sharding, vertical scaling and the synchronization of the cluster state from Git repositories, OCI artifacts, and S3-compatible storage.

## Upgrade procedure

**Breaking changes in this release:**

- Object identity is always enabled and the default Flux RBAC no longer grants the `create` verb on the `serviceaccounts/token` resource. If your installation relies on the default RBAC, bind a ClusterRole with this permission to the controller ServiceAccount before upgrading. See fluxcd/flux2#6139 for the required ClusterRole and ClusterRoleBinding.
- The notification `Alert` and `Provider` APIs are promoted to `v1`. Converting a `v1beta3` `Alert` or `Provider` to `v1` drops the deprecated `Alert.spec.summary` and `Provider.spec.interval` fields, the static JWT token for Azure Event Hub, and TLS or proxy configuration in `Provider.spec.secretRef`. Use `eventMetadata.summary`, `proxySecretRef` and `certSecretRef` instead.
- The Flux artifact storage backend is now the default for the `ImageRepository` tag database. Switching the gate wipes the local tag database, so the first reconciliation after the upgrade rescans every `ImageRepository`. Set `--feature-gates=FluxStorage=false` to keep using BadgerDB.
- Remote cluster authentication with `.spec.kubeConfig.configMapRef` uses object identity; replace the legacy `audiences` key with `credential.auth.fluxcd.io/audiences`.

Please follow the Upgrade Procedure for Flux v2.7+ for a smooth upgrade from older versions of Flux to v2.10.

## Components changelog

- source-controller v1.10.1
- kustomize-controller v1.10.1
- notification-controller v1.10.0
- helm-controller v1.7.1
- image-reflector-controller v1.3.0
- image-automation-controller v1.3.0
- source-watcher v2.3.1

## CLI changelog (selected verbatim entries)

- Update to Kubernetes 1.37 by @stefanprodan in #6082
- Breaking change: Harden RBAC for controllers by @matheuscscp in #6139
- [RFC-0014] Inter-controller mTLS via SPIFFE by @matheuscscp in #6127
- Add `--policy-change-delay` to create image update by @stefanprodan in #6146
- Bump minimum Kubernetes version to 1.35 by @stefanprodan in #6153

**Full Changelog**: v2.9.6...v2.10.0
