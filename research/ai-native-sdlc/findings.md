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

FACT: Three distinct families of "AI-native SDLC" framing exist in the captured sources:

1. **Anthropic playbook (artifact-chain + agent harness).** Twelve plays across six stages, centered on `intent.md`/`spec.md`/`CLAUDE.md`/`REVIEW.md` artifacts, skills, hooks, and Claude Code execution surfaces ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)).

2. **Atlassian playbook (platform + context graph).** Same diagnosis, but the remedy is platform investment — a context graph (Teamwork Graph), measurement, systems of record — with workflow shifts layered on top. Agent-agnostic in principle, Atlassian-product-backed in the "approach" column ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)).

3. **Spec-driven development toolkits (agent-agnostic, repo-local).** GitHub's Spec Kit (142,928 stars, MIT, created 2025-08-21) operationalizes SDD as agent-chat commands (`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-implement`, `/speckit-converge`) with a per-project constitution, plus bug-fixing and idea-assessment extensions; integrations for multiple coding agents ([Spec Kit](../../external-sources/ai-native-sdlc-github-spec-kit.md)). The rvbhavsar community playbook is a stricter, governance-first variant: only the first three stages, every stage ending in an explicit human Approve/Revise/Pause gate, approval bound to exact artifact versions and repo revisions ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)).

FACT: The artifact vocabulary converges across vendors and community: Anthropic's `intent.md`/`spec.md`/`plan.md` appears nearly verbatim in the rvbhavsar playbook (`intent.md` → `spec.md` → `plan.md` with approval gates) and as Spec Kit's specify/plan/tasks flow ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md), [Spec Kit](../../external-sources/ai-native-sdlc-github-spec-kit.md)).

OPINION: The convergence on intent/spec/plan markdown artifacts across Anthropic, an independent community author, and GitHub's toolkit suggests this artifact shape is becoming a de facto standard — more durable than any single vendor's playbook. Anthropic's differentiators are the execution-side plays (hooks, parallel worktrees, eval loops, maintain-stage control bands); its plan/design artifacts are the commoditized part.

## Trade-offs

| Option | Pros | Cons | Operating cost | Lock-in risk |
|---|---|---|---|---|
| Anthropic AI-native SDLC (as published) | Concrete, stage-by-stage plays with worked config (hooks JSON, prompts); covers all six stages incl. maintain-loop; governance via hooks + managed settings aimed at regulated enterprises | Claude-only surfaces assumed (Claude Code, skills, hooks, Agent SDK, Claude Security); several referenced products are beta or hosted (Claude Design beta, Claude Security on "Claude Mythos 5"); Test-stage detail thin in public article | Highest: agent sessions, CI eval suites, MCP connections to systems of record, hosted scanning | High: artifacts are portable markdown, but hooks, skills, subagents, and review integrations are Claude-harness-specific |
| Atlassian platform approach | Addresses the context problem Anthropic assumes away (agents need org-wide context, not just repo files); vendor claims 44% accuracy gain / 48% token reduction with context graph (internal benchmark, unverified) | Requires consolidating work activity into systems of record (read: Atlassian's); measurement platform prerequisite; playbook detail lives in a gated PDF | High platform investment before workflow shifts pay off | High: Teamwork Graph is proprietary; Jira/Confluence/Loom-centric |
| Spec Kit / community spec-driven toolkits | Agent-agnostic (integrations for Copilot, Claude, others); MIT; huge adoption (142.9k stars); smallest-change adoption path ("you do not have to replace the whole process") | Covers specify→implement, not the full six-stage lifecycle; no deploy/maintain plays; governance is template-level, not enforced hooks | Low: CLI + repo-local files; no hosted dependency | Low: markdown artifacts, per-project overrides, swappable agent integrations |

FACT (row 1 con): The playbook itself flags managed-settings trade-offs: "Every deny trades against capability, and the right balance depends on the data classification of the repo" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

FACT (row 2 pro/con): The 44%/48% figures are "internal benchmarks" reported by Atlassian with no published methodology ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)). Treat as vendor-reported.

## Migration path

FACT: All sources argue for incremental adoption, not a big-bang replacement. Spec Kit: "Start with the smallest change that meets your needs; you do not have to replace the whole process" ([Spec Kit](../../external-sources/ai-native-sdlc-github-spec-kit.md)). The rvbhavsar playbook is adoption-gated by design: begin with `intent.md` only, "do not populate downstream artifacts as if they were approved" ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)).

FACT: The Anthropic playbook's implied sequence is stage-wise: start capturing `intent.md`, add `spec.md` generation, then build plays (`CLAUDE.md`, skills, parallel sessions), then test feedback loops, then deploy gates, and only last the autonomous maintain loop — the maintain stage is explicitly the stage where "no person [is] in the invocation path" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md), [Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)).

FACT: A realistic hybrid is directly supported by the sources: keep Jira/ServiceNow as source of truth (Anthropic's own legacy-systems play says to) while piloting markdown artifacts as working copies ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)).

OPINION: Sensible order for a team evaluating this: (1) pilot `intent.md`/`spec.md` artifacts on one team with any agent; (2) add the build-stage hygiene (`CLAUDE.md` or equivalent, single-command test target); (3) only then evaluate vendor-specific gates (hooks, managed settings) and the maintain-stage autonomous loop, which is the highest-risk play and the least independently validated.

## Conflicting sources

FACT: **Where the control plane should live.** Anthropic puts enforcement in the agent harness (hooks in `.claude/settings.json`, managed settings) ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)); Atlassian puts it in the platform/data layer ("Governance and permissions are enforced at the data layer, so what a person can see is exactly what an agent can act on") ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)); the community playbook puts it in process (human approval gates between stages, approval bound to artifact versions) ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)). These are complementary in theory but imply different primary investments.

FACT: **Test stage.** Anthropic's stage table replaces "QA gates at stage boundaries" with "continuous evals woven through implementation" ([Claude playbook](../../external-sources/ai-native-sdlc-claude-playbook.md)), while the community playbook retains hard stage gates with human approval before implementation ([rvbhavsar playbook](../../external-sources/ai-native-sdlc-github-rvbhavsar.md)). Not a direct contradiction (gates at different points), but a real philosophical difference on pre- vs post-build verification.

FACT: **Capture gaps in the primary source.** The web article's Test stage section was not captured by extraction (JS-rendered page); Test-stage claims here rely on the Coursera module listing, which is consistent with the stage table but is a secondary summary ([Coursera](../../external-sources/ai-native-sdlc-coursera-course.md)). Mark Test-stage detail as partially verified.

## Open questions

- Does the maintain-stage closed loop (breached control band → diagnosis → new `intent.md` with no human in the invocation path) work safely in production? Only Anthropic's own material describes it; no third-party validation was found. (TODO: needs source)
- Are the claimed productivity effects measured anywhere with methodology? Atlassian cites "19% more PRs and 2–3 hours saved per developer per week" and "93% of developers use AI tools / ~30% of code is AI-authored" but the underlying study was not captured ([Atlassian playbook](../../external-sources/ai-native-sdlc-atlassian-playbook.md)).
- How much of the playbook is Claude-harness-specific vs portable? Skills/hooks/subagents appear Claude-specific; the artifact chain appears portable (adopted by Spec Kit and the community playbook), but a portability matrix was not verified against Claude Code docs.
- The playbook's downloadable PDF version was not fetched — it may contain the full Test-stage plays and worked examples the web extraction missed.

## Requests for res-lab

- Question: Can a minimal intent→spec→plan artifact chain with human approval gates be run end-to-end on a scratch repo using only portable markdown files (no vendor harness), per the rvbhavsar playbook's three-skill model? | Success criterion: `intent.md` → `spec.md` → `plan.md` produced for a toy feature, each gated by an explicit recorded approval, with the artifacts committed to git | Pinned versions: rvbhavsar/ai-native-sdlc-playbook @ commit 05c54cc (2026-09-15); Python 3.11+ if its scripts are exercised.
- Question: Does GitHub Spec Kit's SDD flow (`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → `/speckit-converge`) reach `Converged` on a toy feature, and how does its artifact set map to Anthropic's `intent.md`/`spec.md`? | Success criterion: documented run on a scratch project with the resulting `.specify/` tree and a mapping table between the two artifact vocabularies | Pinned versions: specify-cli latest release at run time (record exact version; repo at 235 releases as of 2026-11-05), Python 3.11+, uv.

## Tentative recommendation

OPINION: Treat the Anthropic playbook as the most operationally detailed public description of where agent-centric delivery is heading, but adopt it in layers: the intent/spec artifact chain (portable, corroborated by Spec Kit and the community playbook) first; build-stage hygiene (`CLAUDE.md`-style memory, single-command feedback loops) second; vendor-specific enforcement (hooks, managed settings) only if already committed to Claude Code; and the autonomous maintain loop last, if ever, pending independent validation. The Atlassian platform framing is the more defensible long-term diagnosis (context is the bottleneck), but its remedy is a bigger, more lock-in-heavy bet.

## Related

- [Sources](./sources.md)
- PoC: not yet created — see Requests for res-lab above (will land at `research/ai-native-sdlc/poc/README.md`)
- Report: not yet created — res-writer will draft `research/ai-native-sdlc/report.md` from this findings doc
- Sibling research: [Crossplane — findings](../crossplane/findings.md) (same FACT/OPINION findings format on this team)
