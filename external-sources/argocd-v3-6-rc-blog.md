---
author: Eugene Doudine (Argo Project blog)
date_fetched: 2026-11-03
date_published: 2026-09-16
description: "First release candidate for Argo CD 3.6: UI improvements, ApplicationSet OCI generator and progressive sync enhancements, controller memory reductions."
media_type: text/html
preservation: text-extracted
source_url: https://blog.argoproj.io/argo-cd-v3-6-rc1-is-here-c0b562dc78d1
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - argocd
title: Argo CD v3.6 Less Memory, Faster UI, Better Rollout Visibility (RC1 blog)
type: source
---
> Fetched from blog.argoproj.io (Medium), published 2026-09-16 by Eugene Doudine (Argo CD 3.6 release champion). **Partial and selective capture:** the fetcher returned the head and tail of the post. A ~1.1k-char middle (Repository Server enhancements through the start of the OTLP section) was not captured. Sections kept below are verbatim. These sections were trimmed for length but exist in the source: Settings List Pages Overhaul, Advanced Settings View, Web UI navigation, regex search, lazy loading, other web UI features, CLI enhancements, partial JSON unmarshalling and related memory items, custom health checks, the full bug-fix list, and the Medium newsletter widget. Link targets dropped.

# Argo CD v3.6 Less Memory, Faster UI, Better Rollout Visibility

**We're excited to announce the first release candidate for Argo CD 3.6!**

This release candidate brings multiple enhancements to existing features, some brand new ones along with a ton of bug fixes. In this blog post, we'll highlight the most significant updates you should be aware of.

## Better Web UI User Experience

### The New Resources Explorer View

Now you can list, search, filter and view details on managed resources from all your Applications in the global Resources Explorer view:

The view aggregates managed resources from all accessible Applications while respecting existing RBAC. It supports standard sorting and filtering options with filter state persisted in view preferences and URL query params. It also supports Summary view: pie charts for sync status, health, namespaces, clusters, and resource kinds.

### Virtual Scrolling for Application Lists/Tiles when all is selected

Thanks to @aali309 (Red Hat) this release introduces virtual scrolling for the Applications list and tiles views, solving a long-standing problem for large-scale deployments. Previously, selecting "All" as the items-per-page option on an Applications view with thousands of apps could cause the UI to slow to a crawl or even crash outright, because every row or tile was rendered to the DOM at once. Now, when the app count exceeds the threshold of 50 applications Argo CD automatically switches to virtualized rendering: only the rows or tiles currently in the viewport are drawn.

## Appset Controller Improvements

### New OCI Generator

Thanks to @robinlieb ApplicationSets gain the OCI generator, bringing OCI artifacts up to parity with the existing Git generators.

Instead of pointing an ApplicationSet at a Git repository and scanning for directories or config files, you can now point it at an OCI artifact and have Argo CD discover directories and parse files inside it, using the same include/exclude pattern semantics you already know from the Git directory and file generators. So the teams who have moved their manifests, Helm charts, or config bundles into an OCI registry no longer have to keep a Git repository around purely to drive ApplicationSet generation.

### Progressive Sync Enhancements

Thanks to @ranakan19's (Red Hat) relentless work on the Progressive Sync feature it got three important improvements in correctness, diagnosability, and observability:

When the ApplicationSet controller detects a change in any of its owned Applications, it now adds a refresh annotation to all owned Applications and waits for them to finish reconciling before starting the rollout, so the controller is never making step decisions on stale state. A new `--refresh-grace-period-seconds` flag lets operators define a minimum grace period before a progressive sync starts refreshing outdated Applications, giving webhooks time to land first.

Progressive sync was previously hard to observe in aggregate. This release adds four new metrics:

- **argocd_appset_progressive_sync_app_status**, a gauge of how many Applications sit in each step by status
- **argocd_appset_progressive_sync_syncs_triggered_total**, a counter of sync operations triggered per step
- **argocd_appset_progressive_sync_detection_to_trigger_seconds**, a histogram measuring the time between detecting that a sync is needed and actually triggering it.
- **argocd_appset_app_refresh_total**, a count of application refreshes triggered by the ApplicationSet for progressive sync.

All the metrics are labeled by namespace and AppSet name (and step, where relevant), so you can now build a dashboard that answers "which step a rollout is stuck on and for how long," and configure alerts on stuck rollouts.

Until now, progressive sync exposed only one condition, and it reported that the rollout had completed even in cases where progressive sync never started at all. That made a successful rollout and a rollout that never began look identical. This change introduces two new reasons, ApplicationSetRolloutError and InvalidRolloutConfig, plus a new ApplicationSetConditionInvalidRolloutConfig condition type for situations that were previously only reported as warnings in the log, and it marks the ApplicationSet health as degraded when a RollingSync strategy has no steps defined.

### `tpl` Function Support in ApplicationSet go-templating

Thanks to @twobiers go-templates now allow to use the Helm-like `tpl` function, which renders a string as a Go template at runtime. It allows to put template expressions into values that are created by generators, for example from yaml files that are parsed by the Git generator. This closes a feature request that had been open since 2023.

### ApplicationSet Workqueue Rate Limiter flags

Thanks to @om7057 the ApplicationSet controller now exposes the same workqueue rate limiter flags that the Application controller has long supported. Previously, argocd-applicationset-controller relied on the controller-runtime default exponential backoff, which capped retries at roughly 16 minutes and offered no way to change it.

## Application Controller Improvements

### New "rollback" RBAC action

Thanks to @ppapapetrou76 Argo CD got a dedicated "rollback" RBAC action for Applications.

The action allows rolling back applications to previously synced revisions with some restrictions: it works only for non-autosynced Applications, can only rollback to revisions in the Application's revision history, only allows to override options 'dryRun' and 'prune' options and cannot perform partial sync on specific resources.

This feature is disabled by default for backwards compatibility. To enable it, set the `server.rbac.rollback.enforce.enable` flag in `argocd-cm` configmap.

### Label-based resource filtering

Thanks to @alexmt (Akuity) Argo CD now supports the resource.selectors key to argocd-cm that attaches a Kubernetes label selector to the list/watch calls Argo CD makes for a given API group/kind/cluster. Because the filtering happens server-side, non-matching objects are never transferred to Argo CD or loaded into the cluster cache at all, rather than being fetched and then discarded. For an Argo CD instance running against clusters with large volumes of irrelevant objects, this translates directly into a smaller cache footprint, lower memory use in the application controller, and reduced pressure on the Kubernetes API server

### Configurable Serialization and Compression for Cached Manifests

@adityaraj178 contributed configurable serialization and compression for cached manifests in the gitops-engine cluster cache. When enabled, each manifest is serialized and compressed into a single byte array before being stored and replacing the deeply nested map[string]interface{} tree with a single heap allocation. Benchmarks on a live Argo CD instance showed controller memory dropping from 3.27 GB to under 1 GB with the default JSON plus fast-gzip combination — roughly a 70% reduction — for about 2.5% additional CPU, and another test on a large production instance measured around 30% memory savings with no observable CPU or performance cost.

(... middle of post not captured: Repository Server Enhancements onward ...)

The change also introduces an otlp-sample-ratio setting (configurable per component via `<COMPONENT_NAME>_OTLP_SAMPLE_RATIO` env. variable), letting you export just a part of traces and keep telemetry volume under control on large installations.

### Hydration status label added to argocd_app_info

Until now, hydration health was only visible per-Application in the UI or API which made hydrator problems hard to diagnose and configure alerts on. Thanks to @crenshaw-dev (Intuit) Argo CD's source hydrator now reports its state through Prometheus. The `argocd_app_info` metric got a new `hydrator_status` label that reflects the Source Hydrator phase for any Application with spec.sourceHydrator configured.

## Notable Bug Fixes (selected verbatim entries)

This release contains more than 170 bugfixes, Here we selected several of them that we consider most notable, addressing issues affecting reliability, performance, and user experience:

- **server-side diff respects impersonation** (@pjiang-dev — Intuit): The diff dry-run used the controller's own credentials instead of the impersonated ServiceAccount, bypassing the least-privilege boundary.
- **ApplicationSet: restore ignoreApplicationDifferences after normalization** (@pjiang-dev): Regression from the concurrency refactor: the controller overwrote fields that ignore rules should protect. This broke the argocd-image-updater write-back pattern.
- **reduce unnecessary sync operations caused by refreshes** (@agaudreault): Every refresh during a sync re-ran the operation, with live GETs and repeated etcd writes. This is a large controller and API server load reduction for busy installs.

## Where Can I Get the New Release?

For installation instructions and the full changelog, check out the github release page. Please see detailed upgrade instructions in the upgrading guide (3.5-3.6).
