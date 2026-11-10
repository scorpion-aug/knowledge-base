---
title: IBM ContextForge (mcp-context-forge) repo and tags
description: Apache-2.0 MCP/A2A/REST gateway and registry from IBM with plugins and governance.
type: source
source_url: https://github.com/IBM/mcp-context-forge
media_type: text/html
date_fetched: 2026-11-10
author: IBM
preservation: text-extracted
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - composio-alternatives
---
> Excerpts of the repo page and https://github.com/IBM/mcp-context-forge/tags.

Repo: IBM/mcp-context-forge, Apache License 2.0, 4,769 stars, 963 forks, 30 releases, 35 tags, created 2025-05-08. Deploy artifacts: PyPI package, container image, Helm charts, Ansible.

Description: "An open source registry and proxy that federates MCP, A2A, and REST/gRPC APIs with centralized governance, discovery, and observability." Tools Gateway (MCP, REST, gRPC-to-MCP translation) and Agent Gateway (A2A, OpenAI-compatible and Anthropic agent routing); plugin system; guardrails.

Tags: v1.1.0 on Oct 20, 2026; v1.0.11 on Sep 28, 2026; v1.0.7-20260921 on Sep 21, 2026. Recent work includes an opt-in on-behalf-of (OBO) bearer bridge so a plugin can exchange the caller token for a downstream credential (Oct 15, 2026).

It is a gateway/registry; it does not ship a catalog of pre-built SaaS connectors with managed OAuth (not stated on the page).
