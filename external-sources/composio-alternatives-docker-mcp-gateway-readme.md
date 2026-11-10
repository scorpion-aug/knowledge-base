> Extract of https://raw.githubusercontent.com/docker/mcp-gateway/main/README.md, fetched 2026-11-10 via web_extract. Verbatim excerpts with boilerplate (badges, contributing, support footer) trimmed; middle truncated by fetcher.

# Docker MCP Plugin and Docker MCP Gateway

The MCP Toolkit, in Docker Desktop, allows developers to configure and consume MCP servers from the Docker MCP Catalog (https://hub.docker.com/mcp). Underneath, the Toolkit is powered by a docker CLI plugin: `docker-mcp`. This repository is the code of this CLI plugin. It can work in Docker Desktop or independently.

The main feature of this CLI is the **Docker MCP Gateway** which allows easy and secure running and deployment of MCP servers.

## Overview

Developers face critical barriers when integrating Model Context Protocol (MCP) tools into production workflows:
- **Managing MCP server lifecycle** Each local MCP server in the catalog runs in an isolated Docker container. npx and uvx servers are granted minimal host privileges.
- **Providing a unified interface** AI models access MCP servers through a single Gateway.
- **Handling authentication and security** Keep secrets out of environment variables using Docker Desktop's secrets management.
- **Supports dynamic tool discovery** and configuration. Each MCP client (e.g. VS Code, Cursor, Claude Desktop, etc.) connects to the same Gateway configuration, ensuring consistency across different clients.
- **Enables OAuth flows** for MCPs that require OAuth access token service connections.

## Features

- Container-based Servers: Run MCP servers as Docker containers with proper isolation.
- Server Management: List, inspect, and call MCP tools, resources and prompts from multiple servers.
- Secrets Management: Secure handling of API keys and credentials via Docker Desktop.
- OAuth Integration: Built-in OAuth flows for service authentication.
- Server Catalog: Manage and configure multiple MCP catalogs.
- Dynamic Discovery: Automatic tool, prompt, and resource discovery from running servers.

## Server references in a profile
- **Catalog references**: `catalog://mcp/docker-mcp-catalog/github`
- **OCI image references**: `docker://my-server:latest`
- **MCP Registry references**: `https://registry.modelcontextprotocol.io/v0/servers/<id>`
- **Local file references**: `file://./server.yaml`

## Catalog management

Manage the OCI-based catalogs available to the MCP gateway. The default catalog is the image `mcp/docker-mcp-catalog`.
- `docker mcp catalog ls` — list catalogs
- `docker mcp catalog show <oci-reference>` — show a catalog
- `docker mcp catalog create myorg/catalog:latest --title "My Catalog" --server catalog://... --server file://./my-server.yaml` — create a catalog from server references or an existing profile

## Running the gateway
- `docker mcp gateway run` — stdio, default profile
- `docker mcp gateway run --profile dev-tools` — specific profile
- streaming transport variant for servicing multiple clients

## Notes from the extracted text
- Feature flags stored in `~/.docker/config.json`.
- Build from source: `make docker-mcp`, install into `~/.docker/cli-plugins/`.
- License: MIT.
