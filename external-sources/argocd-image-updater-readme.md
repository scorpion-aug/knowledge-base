---
author: argoproj-labs
date_fetched: 2026-11-03
description: Argo CD Image Updater is a tool to automatically update the container images of Kubernetes workloads which are managed by Argo CD.
media_type: text/markdown
preservation: text-extracted
source_url: https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/master/README.md
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - argocd
title: Argo CD Image Updater (README)
type: source
---
> Fetched from the master branch README. Badge block trimmed; link targets dropped; text otherwise verbatim.

# Argo CD Image Updater

## Introduction

Argo CD Image Updater is a tool to automatically update the container images of Kubernetes workloads which are managed by Argo CD. In a nutshell, it uses a dedicated ImageUpdater CR to define how to track and update image versions for your Argo CD Applications. When a new image is available, it updates the application by setting parameter overrides, either through the Argo CD API or by committing changes to a Git repository.

Currently, it will only work with applications that are built using *Kustomize*, *Helm*, or *Plugin* (Config Management Plugin) tooling. Applications built from plain YAML are not supported yet (and maybe never will).

## Documentation

Read the documentation for more information on how to set up and run Argo CD Image Updater and to get known to its features and limitations.

Above URL points to the documentation for the current release. If you are interested in documentation of upcoming features, check out the latest documentation which is up-to-date with the master branch.

## Current status

Argo CD Image Updater is under active development. We would not recommend it yet for *critical* production workloads, but feel free to give it a spin.

We're very interested in feedback on usability and the user experience as well as in bug discoveries and enhancement requests.

## Contributing

You are welcome to contribute to this project by means of raising issues for bugs, sending & discussing enhancement ideas or by contributing code via pull requests.

In any case, please be sure that you have read & understood the currently known design limitations before raising issues.

Also, if you want to contribute code, please make sure that your code

* has its functionality covered by unit tests (coverage goal is 80%),
* is correctly linted,
* is well commented,
* and last but not least is compatible with our license and CLA

## License

`argocd-image-updater` is open source software, released under the Apache 2.0 license

## Things that are planned (roadmap)

The following things are on the roadmap

* [ ] Extend Argo CD functionality to be able to update images for other types of applications.
