---
title: "provider-upjet-aws v2.9.0 release notes"
description: "AWS provider v2.9.0 (2026-10-08): offline Plan/diff server alpha, 26 new MRs, Terraform AWS pinned at 6.65.0, one breaking CloudFront OriginRequestPolicy external-name fix."
type: source
source_url: "https://github.com/crossplane-contrib/provider-upjet-aws/releases/tag/v2.9.0"
media_type: "text/html"
author: "crossplane-contrib (released by jonasz-lasut)"
date_fetched: "2026-11-04"
date_published: "2026-10-08"
preservation: "text-extracted"
tags: [source, immutable, layer-ingest, text, crossplane]
---

# provider-upjet-aws v2.9.0 release notes (fetched 2026-11-04)

Tag v2.9.0, commit 735590c, released 2026-10-08T12:41:47Z by jonasz-lasut. (Note: the long new-resources table and bug-fix lists are excerpted; full notes at source_url.)

## Overview

v2.9.0 is a minor release on top of v2.8.1. It introduces Plan: an offline, credential-free preview of what applying a managed resource would change, computed by the provider itself. It adds 26 new managed resources, including three new API groups (agentregistry, lambdacore, lambdamicrovms), filesystem mounts for CodeInterpreter.bedrockagentcore, and fixes for several perpetual update loops (PutBucketEncryption calls on every reconcile of BucketServerSideEncryptionConfiguration, rejected access_logs updates on Gateway Load Balancers, drift on RDS Cluster members).

The Terraform AWS provider stays at v6.65.0. Fork release moves v6.65.0-upjet.1 to v6.65.0-upjet.2. Field paths apply to both cluster-scoped (*.aws.upbound.io) and namespaced (*.aws.m.upbound.io) variants.

## Breaking bugfix API change

OriginRequestPolicy.cloudfront: external name is now the policy ID, not the name; name moves back into spec.forProvider (required when managementPolicies include Create, Update or *). On the cluster-scoped API name exists only in cloudfront.aws.upbound.io/v1beta2; the namespaced API uses cloudfront.aws.m.upbound.io/v1beta1. Compositions setting the crossplane.io/external-name annotation to choose the policy name must be updated (omit the annotation or set it to the policy ID), or the provider will try to re-create the policy.

## Offline Diff Server (alpha)

The provider now supports an offline gRPC-based diff server that computes diffs/plans for managed resources without connecting to Kubernetes or making cloud API calls. Computes CREATE, UPDATE, REPLACE, NO_OP actions; reports field-level changes; accepts a PlanRequest with the desired resource, an optional actual resource, and an in-memory store with the required ProviderConfig and referenced Secrets; supports namespaced and cluster-scoped MRs including previously served API versions; runs without cloud credentials. Exposed via the internal diff-server subcommand (PlanService.Plan gRPC); advertised through the DiffServer package capability. Limitations: some resources need cloud calls during planning (FAILED_PRECONDITION, fall back to raw diff); accurate plans depend on complete observed state; the gRPC API is experimental; coverage varies between providers. Design: upjet one-pager design/one-pager-upjet-plan-service.md, upjet #694/#765/#769, provider PR #2257.
