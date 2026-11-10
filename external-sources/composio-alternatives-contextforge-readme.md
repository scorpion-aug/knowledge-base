> Partial capture of https://raw.githubusercontent.com/IBM/mcp-context-forge/main/README.md, fetched 2026-11-10 via web_extract (head ~11.2k chars + tail ~3.7k chars of ~40.7k total). **The middle (~26k chars) was omitted by the fetcher** — the missing region likely covers the Installation/Configuration/Running/Cloud Deployment/API Reference/Testing sections. Claims below are grounded only in the captured head+tail; config and deployment details beyond what appears here are unverified.

# ContextForge

> An open source registry and proxy that federates MCP, A2A, and REST/gRPC APIs with centralized governance, discovery, and observability. Optimizes Agent & Tool calling, and supports plugins.

**ContextForge** is an open source registry and proxy that federates tools, agents, and APIs into one clean endpoint for your AI clients. It provides centralized governance, discovery, and observability across your AI infrastructure:

- **Tools Gateway** — MCP, REST, gRPC-to-MCP translation, and TOON compression
- **Agent Gateway** — A2A protocol, OpenAI-compatible and Anthropic agent routing
- **API Gateway** — Rate limiting, auth, retries, and reverse proxy for REST services
- **Plugin Extensibility** — 40+ plugins for additional transports, protocols, and integrations
- **Observability** — OpenTelemetry tracing with Phoenix, Jaeger, Zipkin, and other OTLP backends

It runs as a fully compliant MCP server, deployable via PyPI or Docker, and scales to multi-cluster environments on Kubernetes with Redis-backed federation and caching.

## Overview & Goals

ContextForge federates any MCP server, A2A server, or REST/gRPC API, providing centralized governance, discovery, and observability. It currently supports:

* Federation across multiple MCP and REST services
* **A2A (Agent-to-Agent) integration** for external AI agents (OpenAI, Anthropic, custom)
* **gRPC-to-MCP translation** via automatic reflection-based service discovery
* Virtualization of legacy APIs as MCP-compliant tools and servers
* Transport over HTTP, JSON-RPC, WebSocket, SSE (with configurable keepalive), and Streamable HTTP; stdio transport available for server-side use
* An Admin UI for real-time management, configuration, and log monitoring (with airgapped deployment support)
* A redesigned, more user-friendly Web UI that runs in a separate container
* Built-in auth, retries, and rate-limiting with user-scoped OAuth tokens and unconditional X-Upstream-Authorization header support
* **OpenTelemetry observability** with Phoenix, Jaeger, Zipkin, and other OTLP backends
* Scalable deployments via Docker or PyPI, Redis-backed caching, and multi-cluster federation

### Gateway Layer with Protocol Flexibility
* Federates any MCP server or REST API
* Lets you choose your MCP protocol version (e.g., `2025-11-25`)
* Exposes a single, unified interface for diverse backends

### Virtualization of REST/gRPC Services
* Wraps non-MCP services as virtual MCP servers
* Registers tools, prompts, and resources with minimal configuration
* gRPC-to-MCP translation via server reflection protocol; automatic service discovery and method introspection

### REST-to-MCP Tool Adapter
* Automatic JSON Schema extraction; support for headers, tokens, and custom auth; retry, timeout, and rate-limit policies

### Unified Registries
* **Prompts**: Jinja2 templates, multimodal support, rollback/versioning
* **Resources**: URI-based access, MIME detection, caching, SSE updates
* **Tools**: Native or adapted, with input validation and concurrency controls

### Admin UI, Observability & Dev Experience
* Admin UI built with HTMX 2.0.3 (bundled) + Alpine.js
* Real-time log viewer with filtering, search, and export capabilities
* Auth: Basic, JWT, or custom schemes
* Structured logs, health endpoints, metrics
* 7,000+ tests, Makefile targets, live reload, pre-commit hooks

### OpenTelemetry Observability
* Vendor-agnostic tracing with OTLP; backends: Phoenix, Jaeger, Zipkin, Tempo, DataDog, New Relic
* Distributed tracing across federated gateways and services
* Automatic instrumentation of tools, prompts, resources, gateway operations
* LLM-specific metrics: token usage, costs, model performance
* Zero-overhead when disabled

## Quick Start - PyPI

Published on PyPI as `mcp-contextforge-gateway`.

> **`JWT_SECRET_KEY` and `AUTH_ENCRYPTION_SECRET` are required in every environment — including local development.** The gateway will not start without them. Generate with `python3 -m mcpgateway.scripts.init_secrets`.

TLDR: generate secrets → export JWT_SECRET_KEY + AUTH_ENCRYPTION_SECRET → `uvx --from mcp-contextforge-gateway mcpgateway --host 0.0.0.0 --port 4444`. Admin API and UI are opt-in via `MCPGATEWAY_UI_ENABLED` / `MCPGATEWAY_ADMIN_API_ENABLED`.

Prerequisite: Python ≥ 3.11. Bearer-token smoke test via `python3 -m mcpgateway.utils.create_jwt_token`.

## Troubleshooting (tail excerpt)
- Compose failures: missing CI wheel closure → use `ghcr.io/ibm/mcp-context-forge:latest`; `SecurityConfigurationError: jwt_secret_key` → run `init_secrets --patch-env .env`; nginx-cache pull denied → `docker compose build nginx`.
- SQLite "disk I/O error" on macOS — avoid iCloud-synced dirs.
- Port 4444 on WSL2 needs Docker Desktop WSL integration.

## License
Apache License 2.0.
