---
title: "<Topic> — findings"
description: "Concepts, architecture and trade-offs for <topic>."
type: research-note
status: draft
date: 2026-11-05
author: res-researcher
cluster: <topic>
tags: [research, provisional, research-team, findings, <topic>]
sources: []
---

## Question

(Headless mode — rubric auto-proposed and auto-confirmed.)

**Question:** What does Anthropic's "AI-Native SDLC Playbook" propose as the operating model for integrating AI into the software development lifecycle, and how does it compare to adjacent industry framings (GitHub Copilot/agent mode, DX/"AI-native SDLC" vendor takes, spec-driven development with agents)?

**Dimensions to investigate:**
1. Problem the playbook solves (why the classic SDLC breaks under AI assistance)
2. Core concepts and new roles/artifacts the playbook introduces
3. The lifecycle architecture / stage-by-stage model it prescribes
4. Alternatives and adjacent framings (GitHub agent workflows, spec-driven development e.g. GitHub Spec Kit / Kiro, Thoughtworks/DX takes)
5. Trade-offs, adoption costs, and lock-in risk
6. What is measurable/verifiable vs vendor narrative

**Candidate sources:**
- The anchor article itself (claude.com/resources/articles/the-ai-native-sdlc-playbook)
- Adjacent Anthropic resources (Claude Code docs, building-effective-agents)
- GitHub's agent-mode / Spec Kit material (third-party comparison)
- An independent/industry take on "AI-native SDLC" (Thoughtworks, DX, or similar)

**Success criteria:** findings.md cites 3-6 preserved local sources; FACT/OPINION separated; conflicts and unverifiable claims flagged; PoC requests listed if any.

**Output format:** Path A (research article), topic folder `research/ai-native-sdlc/`.

## Context

The owner handed a single URL — Anthropic's AI-Native SDLC Playbook — as the topic anchor. The reader is an engineer evaluating whether and how to restructure their team's development process around AI coding agents (Claude Code and peers). Decision context: which parts of this playbook are durable process guidance vs vendor framing, and what it would cost to adopt.

## Problem solved

FACT: The playbook's premise is that AI code generation has collapsed the cost of the Build stage while the surrounding process still runs at human speed. The article states: "Many engineering teams still have the same approval gates, reviews, handoffs, and policies, stalling productivity gains made by using agentic coding solutions like Claude Code" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), 2026-08-21).

FACT: When build stops being the bottleneck, three things follow per the playbook: (1) the bottleneck moves left and right of build — plan, review/test, deploy still run at human speed; (2) controls stop matching reality — line-by-line human review "can't keep up once agents write most of the diff"; (3) governance costs increase because exceptions route through weekly/monthly committees ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT: Atlassian independently arrives at the same diagnosis: "coding itself is evolving from a synchronous, single-threaded task into an asynchronous, multi-threaded one. This exposes the processes and steps _before_ and _after_ code (planning, design, review, and maintenance) as the largest bottlenecks" ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md), 2026-10-01).

FACT: The community playbook frames the same problem from the risk side: "faster coding does not resolve unclear requirements, architecture ambiguity, security decisions, review bottlenecks, or unsafe autonomy... agents can produce more code while also producing more rework and risk" ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)).

OPINION: The problem statement is real and corroborated by three independent authors, but note all three sell a remedy. The claim "code is no longer the bottleneck" is a directional statement, not a measured one — none of the sources publish data showing where cycle time actually concentrates in an agent-heavy team.

## Core concepts

FACT: The playbook defines the AI-native SDLC as "a reimagined process that combines the old control objectives with new enforcement. Instead of a linear flow, the process becomes a loop, and AI is embedded at each point" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT: Named artifacts the playbook introduces as versioned, machine-actionable files:
- `intent.md` — "a proto-spec in the originator's own terms... what is wanted, why, and under which constraints" (Plan stage) ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).
- `spec.md` — the requirements-and-design document Claude produces from an approved `intent.md`, constrained by org skills (Design stage) ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md); also [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)).
- `CLAUDE.md` — "the context a new joiner would need, covering conventions, commands, architecture, and the mistakes the team sees most often"; kept under a page; updated "when Claude makes a mistake twice" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).
- `REVIEW.md` — a deploy-stage review artifact (named in the Coursera module summary: "Deploy behind a REVIEW.md, approval hooks, and non-interactive pipeline jobs") ([Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)).

FACT: Skills carry institutional knowledge — "standards encoded as skills, versioned in git" for brand, security, compliance, UX ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), Design stage table row).

FACT: Hooks as approval gates — governance enforced as the AI acts, e.g. a `PreToolUse` hook on `Bash` matching a `production-gate.sh` script in `.claude/settings.json` ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT: Legacy system as source of truth — "Jira, ServiceNow, or the requirements tool holds the authoritative record and the markdown artifacts are working copies," synced via MCP in the same session ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT: Human-in-the-loop is load-bearing in every variant. Anthropic: "human judgment and enterprise controls stay in place" ([Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)). Community: "Human control is a system property... The agent may inspect, interview, challenge, compare, recommend, draft, and evaluate. It may not silently make material decisions or approve its own work" with Approve/Revise/Pause gates at each stage ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)). Atlassian: "Keep humans clearly in charge of judgment, quality, and governance while AI handles execution and enforcement" ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)).

FACT: Atlassian adds a platform-layer concept absent from Anthropic's artifact-centric framing: a context graph (their Teamwork Graph, 50+ connected sources) plus continuous measurement, holding that "new SDLC workflows only work effectively when supported by powerful enterprise context and feedback loops" ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)).

## Architecture

FACT: The playbook structures twelve plays across six non-linear stages — Plan, Design, Build, Test, Deploy, Maintain ([Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)). Stage contents per the sources:

| Stage | Plays / mechanism | Source |
|---|---|---|
| Plan | Capture as `intent.md` via brainstorm with Claude; repeat processes encoded as skills | [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md) |
| Design | `intent.md` → `spec.md` in one prompted session, constrained by org skills; Claude Design (beta) for front-end mocks, exported to Claude Code | [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md) |
| Build | Plan mode as default starting point; lean `CLAUDE.md`; skills as institutional knowledge; parallel sessions with subagents, each in its own git worktree | [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md), [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md) |
| Test | "Give Claude a feedback loop" — a single-command target Claude can run itself; continuous evals in CI built from real tasks | [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md) (Test-stage section of the web article itself was not captured) |
| Deploy | AI in the PR review loop (managed Code Review service or claude-code-action in own CI, model calls via AWS Bedrock / Google Vertex / Microsoft Foundry); hooks as approval gates; managed settings for regulated enterprises; non-interactive pipeline jobs with scoped credentials, deployment tooling exposed via MCP | [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md) |
| Maintain | Closing the loop on metrics: stateless non-interactive Claude (CI runner or Agent SDK service in a sandboxed container); deterministic control bands that call Claude in tiers when a metric drifts; findings re-enter as new `intent.md`; recurring codebase scans via Claude Security (hosted, on "Claude Mythos 5") | [Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md) |

FACT: The maintain stage closes the loop: "A trigger invokes Claude with no person in the invocation path, and what it finds re-enters the pipeline as `intent.md`" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT: The article's worked `production-gate.sh` example wires a `PreToolUse` hook matching `Bash` to a repo-local script, configured in `.claude/settings.json` ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

OPINION: Architecturally this is an artifact-chain (intent → spec → code → review → metrics → intent) with the agent as the transport between artifacts. The loop shape is the genuinely new part; the individual plays are recognizable CI/CD and code-review hygiene re-pointed at an agent executor.

## Alternatives

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|

## Migration path

## Conflicting sources

## Open questions

## Requests for res-lab

- Question: … | Success criterion: … | Pinned versions: …

## Tentative recommendation

OPINION: …

## Related

- [Sources](./sources.md)
- [PoC](./poc/README.md)
- [Report](./report.md)
