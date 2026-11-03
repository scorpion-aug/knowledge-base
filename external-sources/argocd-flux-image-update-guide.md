---
author: Flux project (CNCF)
date_fetched: 2026-11-03
description: Automate container image updates to Git with Flux.
media_type: text/html
preservation: text-extracted
source_url: https://fluxcd.io/flux/guides/image-update/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - argocd
title: Automate image updates to Git (Flux guide)
type: source
---
> Fetched from fluxcd.io ("Automate image updates to Git"), page last modified 2026-10-23 (website commit a2ebb070). **Partial capture:** the fetcher returned the head (~9k chars) and tail (~3k chars) of a ~25k-char page. The middle section (marker syntax, ImageUpdateAutomation spec, push-to-branch and commit templates) is **not preserved here**. Re-ingest from a shell-capable client to capture it. Captured text is verbatim; link targets dropped.

# Automate image updates to Git

Automate container image updates to Git with Flux.

This guide walks you through configuring container image scanning and deployment rollouts with Flux.

For a container image you can configure Flux to:

- scan the container registry and fetch the image tags
- select the latest tag based on the defined policy (semver, calver, regex)
- replace the tag in Kubernetes manifests (YAML format)
- checkout a branch, commit and push the changes to the remote Git repository
- apply the changes in-cluster and rollout the container image

For production environments, this feature allows you to automatically deploy application patches (CVEs and bug fixes), and keep a record of all deployments in Git history.

**Production CI/CD workflow**

- DEV: push a bug fix to the app repository
- DEV: bump the patch version and release e.g. `v1.0.1`
- CI: build and push a container image tagged as `registry.domain/org/app:v1.0.1`
- CD: pull the latest image metadata from the app registry (Flux image scanning)
- CD: update the image tag in the app manifest to `v1.0.1` (Flux cluster to Git reconciliation)
- CD: deploy `v1.0.1` to production clusters (Flux Git to cluster reconciliation)

For staging environments, this features allow you to deploy the latest build of a branch, without having to manually edit the app deployment manifest in Git.

**Staging CI/CD workflow**

- DEV: push code changes to the app repository `main` branch
- CI: build and push a container image tagged as `${GIT_BRANCH}-${GIT_SHA:0:7}-$(date +%s)`
- CD: pull the latest image metadata from the app registry (Flux image scanning)
- CD: update the image tag in the app manifest to `main-2d3fcbd-1611906956` (Flux cluster to Git reconciliation)
- CD: deploy `main-2d3fcbd-1611906956` to staging clusters (Flux Git to cluster reconciliation)

## Prerequisites

You will need a Kubernetes cluster version 1.16 or newer and kubectl version 1.18. For a quick local test, you can use Kubernetes kind. Any other Kubernetes setup will work as well.

In order to follow the guide you'll need a GitHub account and a personal access token that can create repositories (check all permissions under `repo`).

## Install Flux

#### Enable image automation components

If you bootstrapped Flux before, you need to add `--components-extra=image-reflector-controller,image-automation-controller` to your bootstrapping routine as image automation components are not installed by default. Please note that you need to delete the `flux-system` secret before rerunning bootstrap to rotate the deploy key.

Install Flux with the image automation components:

```sh
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=$GITHUB_USER \
  --repository=flux-image-updates \
  --branch=main \
  --path=clusters/my-cluster \
  --read-write-key \
  --personal
```

The bootstrap command creates a repository if one doesn't exist, and commits the manifests for the Flux components to the default branch at the specified path. It then configures the target cluster to synchronize with the specified path inside the repository.

#### GitLab and other Git platforms

You can install Flux and bootstrap repositories hosted on GitLab, BitBucket, Azure DevOps and any other Git provider that support SSH or token-based authentication. When using SSH, make sure the deploy key is configured with write access `--read-write-key`.

## Configure image scanning

Create an `ImageRepository` to tell Flux which container registry to scan for new tags:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
```

For private images, you can create a Kubernetes secret in the same namespace as the `ImageRepository` with `kubectl create secret docker-registry`. Then you can configure Flux to use the credentials by referencing the Kubernetes secret in the `ImageRepository`.

Create an `ImagePolicy` to tell Flux which semver range to use when filtering tags:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: podinfo
  policy:
    semver:
      range: 5.0.x
```

A semver range that includes stable releases can be defined with `1.0.x` (patch versions only) or `>=1.0.0 <2.0.0` (minor and patch versions). If you want to include pre-release e.g. `1.0.0-rc.1`, you can define a range like: `^1.x-0` or `>1.0.0-rc <2.0.0-rc`.

For policies that make use of CalVer, build IDs or alphabetical sorting, have a look at the examples.

## Configure image updates

Edit the `podinfo-deployment.yaml` and add a marker to tell Flux which policy to use when updating the container image:

(... middle of page not captured ...)

(... tail of page follows ...)

change the underlying software without you knowing. This also makes the updates traceable in your Git history.

With the right `ImagePolicy` configuration Flux is capable of polling image digests for a fixed tag. To configure Flux to watch the digest for `latest`, you can use an `ImagePolicy` like the following:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: podinfo
  filterTags:
    pattern: '^latest$'
  policy:
    alphabetical: {}
  digestReflectionPolicy: Always
  interval: 10m
```

The trick is filtering a single tag, the one you want to follow, and setting `digestReflectionPolicy` to `Always`, which will tell Flux to fetch the digest for that tag according to the specified `interval`, once every ten minutes in the example above.

Then in the manifest where you want to use the `latest` tag, you can do the following:

```yaml
          image: ghcr.io/stefanprodan/podinfo:latest@sha256:ec0119616bb8be9199575c05bfc23a6bf0fbdb0690ee15834e7b43bc3f4f6017 # {"$imagepolicy": "flux-system:podinfo"}
```

Or if you have a `HelmRelease` where `repository`, `tag` and `digest` are separate values:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: default
spec:
  values:
    image:
      repository: ghcr.io/stefanprodan/podinfo # {"$imagepolicy": "flux-system:podinfo:name"}
      tag: latest  # {"$imagepolicy": "flux-system:podinfo:tag"}
      digest: sha256:ec0119616bb8be9199575c05bfc23a6bf0fbdb0690ee15834e7b43bc3f4f6017 # {"$imagepolicy": "flux-system:podinfo:digest"}
```

### Achieving immutability for tags

Another common use case is preventing images from ever changing after a new tag is released. If later for whatever reason this tag is pushed with a different image, i.e. a different digest, and you don't want it to be updated e.g. due to the reasons of how you test and ship your software, you can set `digestReflectionPolicy` to `IfNotPresent` in the `ImagePolicy`:

```yaml
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: podinfo
  policy:
    semver:
      range: 5.0.x
  digestReflectionPolicy: IfNotPresent
```

In this case the digest will only be updated in the `ImagePolicy` status if a new tag is elected as latest, in which case both the tag and the digest will be updated together. Setting an `interval` in this case is not allowed.
