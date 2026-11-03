---
title: Flux version 2 (README)
description: Flux is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy.
type: source
source_url: https://raw.githubusercontent.com/fluxcd/flux2/main/README.md
media_type: text/markdown
date_fetched: 2026-11-03
author: Flux project (CNCF)
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - argocd
---
> Fetched from the main branch README. Badge block and image embeds trimmed; link targets dropped; text otherwise verbatim.

# Flux version 2

Flux is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy.

Flux version 2 ("v2") is built from the ground up to use Kubernetes' API extension system, and to integrate with Prometheus and other core components of the Kubernetes ecosystem. In version 2, Flux supports multi-tenancy and support for syncing an arbitrary number of Git repositories, among other long-requested features.

Flux v2 is constructed with the GitOps Toolkit, a set of composable APIs and specialized tools for building Continuous Delivery on top of Kubernetes.

Flux is a Cloud Native Computing Foundation (CNCF) graduated project, used in production by various organisations and cloud providers.

## Quickstart and documentation

To get started check out this guide on how to bootstrap Flux on Kubernetes and deploy a sample application in a GitOps manner.

For more comprehensive documentation, see the following guides:
- Ways of structuring your repositories
- Manage Helm Releases
- Automate image updates to Git
- Manage Kubernetes secrets with Flux and SOPS

## GitOps Toolkit

The GitOps Toolkit is the set of APIs and controllers that make up the runtime for Flux v2. The APIs comprise Kubernetes custom resources, which can be created and updated by a cluster user, or by other automation tooling.

You can use the toolkit to extend Flux, or to build your own systems for continuous delivery -- see the developer guides.

### Components

- Source Controllers
    - GitRepository CRD
    - OCIRepository CRD
    - HelmRepository CRD
    - HelmChart CRD
    - Bucket CRD
    - ExternalArtifact CRD
    - ArtifactGenerator CRD
- Kustomize Controller
    - Kustomization CRD
- Helm Controller
    - HelmRelease CRD
- Notification Controller
    - Provider CRD
    - Alert CRD
    - Receiver CRD
- Image Automation Controllers
  - ImageRepository CRD
  - ImagePolicy CRD
  - ImageUpdateAutomation CRD

## Community

- Ask questions on the GH Discussions page; #flux channel on CNCF Slack.
- Propose features on GitHub Discussions; dev meetings; flux-dev mailing list; project roadmap (https://fluxcd.io/roadmap/).
