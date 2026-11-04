---
title: "Upjet README (crossplane/upjet, main)"
description: "Upjet is a code generation framework and runtime that transforms Terraform providers into Crossplane providers; powers official AWS/Azure/GCP providers and 50+ community providers."
type: source
source_url: "https://raw.githubusercontent.com/crossplane/upjet/main/README.md"
media_type: "text/markdown"
author: "Crossplane authors"
date_fetched: "2026-11-04"
preservation: "text-extracted"
tags: [source, immutable, layer-ingest, text, crossplane]
---

# Upjet README (main, fetched 2026-11-04)

Upjet is a code generation framework and Kubernetes controller runtime that transforms Terraform providers into Crossplane providers. It generates Kubernetes CRDs, reconciliation controllers, and example manifests while providing runtime libraries for API conversions, Terraform state management, and resource lifecycle operations. It powers the official AWS, Azure, and GCP providers along with 50+ community providers.

## Key Features

- Multiple Terraform execution modes: Terraform CLI (fork-based), Terraform Plugin SDK v2 (Go library, no CLI), Terraform Plugin Framework (protov6, no CLI).
- Automatic resource generation: CRDs conformant to the Crossplane Resource Model (XRM), reconcilers with full CRUD lifecycle, example manifests, partial API validation rules.
- Cross-resource references: Kubernetes-native reference resolution, automatic selector generation.
- Management policies (Crossplane v1.11+): fine-grained lifecycle control; observe-only mode for importing existing infrastructure.
- Advanced: external name mapping, late initialization, sync and async long-running operations, sensitive fields via connection secrets.

## When to use

Upjet is ideal when a Terraform provider already exists for your target platform, you want Terraform's resource logic, broad coverage quickly. Consider a native provider when no TF provider exists, you need customized reconciliation, precise API control, or performance beyond Terraform execution.

## Architecture

Build time: reads Terraform provider schema, generates Go types, CRDs, controllers. Runtime: generic reconcilers use Terraform resource logic while exposing a pure Kubernetes API. Components: codegen pipeline, generic CR reconcilers, docs scraper, migration framework (e.g. crossplane-contrib/provider-aws to upbound/provider-aws), API conversion framework, resource configuration framework.

## Providers built with Upjet

AWS (crossplane-contrib/provider-upjet-aws), Azure (provider-upjet-azure), GCP (provider-upjet-gcp), Grafana, GitHub, and more via the Upbound Marketplace (https://marketplace.upbound.io/providers).

## Docs highlights

Guides: generating a provider, configuring a resource, adding new resources, testing with Uptest, monitoring, upgrading upjet v1 to v2, managing CRD versions, template variables.

## Prior art / license

Originates from Terrajet. Apache 2.0 license with notice.
