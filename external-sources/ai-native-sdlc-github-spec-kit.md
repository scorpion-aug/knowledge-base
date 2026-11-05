---
date_fetched: 2026-11-05
preservation: text-extracted
media_type: text/html
author: GitHub
description: "GitHub's open-source toolkit for spec-driven development (SDD) with AI coding agents: structured processes, templates, quality gates, extensions, presets, and workflows. 142.9k stars at fetch time."
title: GitHub — github/spec-kit
type: source
source_url: https://github.com/github/spec-kit
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - ai-native-sdlc
---
# Spec Kit (github/spec-kit) — README

Repo state at fetch time: public, MIT License, 142,928 stars, 12,806 forks, 716 watchers, default branch main, 235 releases / 237 tags, created 2025-08-21. Website: github.github.com/spec-kit.

Tagline: "Build with a spec, fix a bug, or assess an idea — with your coding agent."

Spec Kit is an open source toolkit that gives AI coding agents structured processes, reusable templates, and documented outcomes. Start with a ready-made process, customize it, or bring your own.

## Choose your process

| What you need | Process | Outcome |
| Build a feature or application | Spec-Driven Development | A specification carried through planning, implementation, and convergence |
| Diagnose and repair broken behavior | Bug fixing | An assessed cause, scoped fix, and recorded verification |
| Decide whether an idea deserves investment | Idea assessment | An evidence-backed go, clarify, or stop decision |
| Adopt or create a different process | Your own process | A process adapted or assembled from reusable primitives |

These are independent entry points, not mandatory phases. SDD ships in core; bug fixing and assessment are bundled extensions you install when needed.

## Capabilities (mechanisms)

Integration (connect/switch coding agents), Extension (add a command, quality gate, or complete process; connect to external tools; react to coding-agent lifecycle events; extension hooks), Preset (adapt templates, commands, terminology, methodology; enforce organizational or regulatory standards), project-local overrides, Workflow (automate prompts, commands, gates, shell tasks), Workflow overlays, custom workflow steps, Bundle (curated setup for a role/team), Catalog (community components; private catalogs possible; "Catalog listings are not audits or endorsements"), authentication for private catalogs, air-gapped/local sources, artifact inventory.

## Get started

Requires Python 3.11+, uv, and a supported AI coding agent on Linux, macOS, or Windows. Example uses GitHub Copilot:

```
uv tool install specify-cli
specify init my-project --integration copilot
cd my-project
```

## Spec-Driven Development

Define what to build and why, then turn the specification into a plan, tasks, and working code. Create a constitution once per project and repeat the remaining steps for each feature. Run these skills in your agent's chat, not your terminal, one at a time, reviewing each result before continuing.

```
/speckit-constitution Create principles focused on code quality, testing, and maintainability.
/speckit-specify Build a photo organizer with albums grouped by date and a tile preview of each album.
/speckit-plan Use Vite with vanilla JavaScript. Keep images local and store metadata in SQLite.
/speckit-tasks
/speckit-implement
/speckit-converge
```

Repeat implement and converge until convergence reports `Converged`.

## Bug fixing

Assess the cause, fix the bug, and verify the original symptom is resolved. Install via `specify extension add bug`. Commands: `/speckit-bug-assess`, `/speckit-bug-fix`, `/speckit-bug-test`. The final verdict is `verified`, `partial`, or `failed`; only `verified` confirms a successful fix.

## Idea assessment

Gather evidence to decide whether an idea is worth pursuing. Install via `specify extension add assess`. Commands: `/speckit-assess-intake`, `/speckit-assess-research`, `/speckit-assess-define`, `/speckit-assess-shape`, `/speckit-assess-decide`. Final decision: `go`, `needs-clarification`, or `kill`. A `go` decision's handoff summary feeds `/speckit-specify`.

## Customize or bring your own process

Adapt an existing process with a preset; bring your own process via extensions and integrations; automate via workflows/overlays/steps; share via bundles. "Start with the smallest change that meets your needs; you do not have to replace the whole process."

## In the news
- Open Source Friday: Spec Kit Part 2 (October 16, 2026) — Spec Kit 1.0 and the expanded toolkit.
- Open Source Friday with Spec Kit (May 8, 2026) — introduction and SDD demonstration.

License: MIT.
