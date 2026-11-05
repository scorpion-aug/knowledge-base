---
date: 2026-11-05
cluster: ai-native-sdlc
author: res-researcher
description: Screened candidate sources for the AI-native SDLC topic, with health signals and verdicts.
title: AI-native SDLC — candidate sources
type: research-note
status: draft
tags:
  - research
  - provisional
  - research-team
  - sources
  - ai-native-sdlc
---
## Scope

Screened candidates for the AI-native SDLC topic (anchor: Anthropic's "The AI-native SDLC playbook", handed over by the owner 2026-11-05). Decision: which parts of the playbook are durable process guidance vs vendor framing, and what adoption costs. Search date: 2026-11-05. Search channel: web search for "AI-native SDLC" + direct fetches of the top adjacent sources.

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| Anthropic — The AI-native SDLC playbook (web article) | Vendor playbook: 12 plays across 6 SDLC stages, artifact-chain (intent.md/spec.md/CLAUDE.md/REVIEW.md), hooks, skills, maintain-loop | Published 2026-08-21 (page metadata) | n/a (article) | Anthropic Applied AI team / Louis Claxton | Proprietary content | unverified | dig deeper (anchor) | The topic anchor; most detailed public description of the agent-centric six-stage model | [source](../../external-sources/ai-native-sdlc-claude-playbook.md) |
| Anthropic Academy — AI-Native SDLC Playbook (Coursera) | Free 8-module course mirroring the playbook; module list reveals full 12-play structure incl. Test stage | Updated 2026-10 (page) | n/a (course) | Anthropic Academy | Free (no certificate) | 23 courses / 89,068 learners (Anthropic Academy overall) | dig deeper | Corroborates playbook structure; only captured source for the Test-stage plays | [source](../../external-sources/ai-native-sdlc-coursera-course.md) |
| Atlassian — The AI SDLC transformation playbook | Vendor playbook: platform investments (context graph, measurement) + 5 workflow shifts; downloadable PDF | 2026-10-01 | n/a (blog + PDF) | Atlassian (Matthew Canham, Sr Group PM AI) | Proprietary content | unverified | dig deeper | Independent diagnosis convergence; competing remedy (platform/data-layer vs agent harness) | [source](../../external-sources/ai-native-sdlc-atlassian-playbook.md) |
| GitHub — spec-kit | Open-source toolkit for spec-driven development with coding agents; SDD core + bug-fix and idea-assessment extensions | 235 releases (latest at fetch unverified) | Active (created 2025-08-21; 237 tags) | GitHub | MIT | 142,928 stars / 12,806 forks | dig deeper | Agent-agnostic, repo-local alternative; adoption leader for the artifact-chain pattern | [source](../../external-sources/ai-native-sdlc-github-spec-kit.md) |
| rvbhavsar/ai-native-sdlc-playbook | Community MIT playbook + 3 executable agent skills (intent/spec/plan readiness) with human approval gates | Last commit 2026-09-15 | Low (4 commits) | 1 maintainer (Rahul Bhavsar) | MIT | 2 stars / 0 forks | watch | Governance-first variant; converges on the same intent/spec/plan artifact vocabulary; tiny adoption | [source](../../external-sources/ai-native-sdlc-github-rvbhavsar.md) |
| Atlassian — "The AI-native SDLC is paying off" (metrics blog) | Claims 19% more PRs, 2–3 h saved/dev/week, 93% dev AI usage, ~30% AI-authored code | 2026 (linked from playbook tail) | n/a | Atlassian | Proprietary content | unverified | watch | Quantified claims worth chasing for the report; methodology not captured | (linked inside [Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md); not separately ingested — TODO) |
| Anthropic — downloadable playbook PDF | The same six stages, plays, worked examples "laid out for reading offline" | unverified | n/a | Anthropic | Proprietary content | unverified | watch | Likely contains the full Test-stage plays the web extraction missed | (referenced inside [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md); URL not captured — TODO) |

Mark any cell you could not verify as `unverified`.

## Preserved sources

- [ai-native-sdlc-claude-playbook](../../external-sources/ai-native-sdlc-claude-playbook.md) — anchor article (partial capture; JS-rendered page)
- [ai-native-sdlc-coursera-course](../../external-sources/ai-native-sdlc-coursera-course.md) — Coursera course page with full module listing
- [ai-native-sdlc-atlassian-playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md) — Atlassian transformation playbook (partial capture)
- [ai-native-sdlc-github-spec-kit](../../external-sources/ai-native-sdlc-github-spec-kit.md) — GitHub Spec Kit README (full capture)
- [ai-native-sdlc-github-rvbhavsar](../../external-sources/ai-native-sdlc-github-rvbhavsar.md) — community playbook README (partial capture)

Findings: [AI-native SDLC — findings](./findings.md)
