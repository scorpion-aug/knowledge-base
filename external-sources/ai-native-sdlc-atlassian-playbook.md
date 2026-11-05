---
author: Matthew Canham (Senior Group Product Manager, AI, Atlassian)
date_fetched: 2026-11-05
description: "Atlassian's approach to the AI-native SDLC: platform investments (context graph, measurement) plus workflow shifts across planning, design, development, review, maintenance. Published 2026-10-01."
media_type: text/html
preservation: text-extracted
source_url: https://www.atlassian.com/blog/ai-at-work/ai-sdlc-transformation-playbook
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - ai-native-sdlc
title: The AI SDLC transformation playbook — Inside Atlassian
type: source
---
> Partial capture: web_extract returned head (~11k chars) + tail (~3.7k chars) of 25,670 total; the middle of the Measurement section, the Workflow shifts detail (planning/design/development/review/maintenance subsections), and Navigating change were elided. Captured: intro, traditional-vs-AI-native comparison table in full, context-graph section, and the measurement section intro.

# The AI SDLC transformation playbook

October 1, 2026. Published in AI at Work. Author: Matthew Canham, Senior Group Product Manager, AI.

Teams across the industry are sprinting to reinvent their software development processes with agentic AI. This guide shares Atlassian's approach and best practices, informed by our own internal AI SDLC transformation and collaborative learnings from top engineering organizations.

## Making the shift to AI-native SDLC

The AI-native software development lifecycle (SDLC) goes far beyond having developers adopt coding agents. As less time is spent writing code by hand, coding itself is evolving from a synchronous, single-threaded task into an asynchronous, multi-threaded one. This exposes the processes and steps _before_ and _after_ code (planning, design, review, and maintenance) as the largest bottlenecks and opportunities. Furthermore, team collaboration becomes an even greater bottleneck as the rate of work accelerates.

To successfully transform the entire SDLC, organizations must simultaneously invest in key platform foundations—context and measurement—while also shifting from traditional SDLC processes to AI-native ways of working. Together, these investments and workflow shifts become the modern software factory: faster, more autonomous, more event-driven, and reshaped around critical human judgment.

(Figure 1: The 7 pillars of AI SDLC transformation — image not captured.)

Platform investments and new SDLC workflows are mutually dependent: new SDLC workflows only work effectively when supported by powerful enterprise context and feedback loops. Inversely, reliable context and measurement are only possible when metadata from new SDLC workflows is consistently captured and accessible. As part of that loop, developer–agent interactions themselves become a new form of context, making the whole workflow smarter over time.

Systems of record tie these pillars together, wherever development happens. They support humans in applying the critical judgment that moves software forward. In turn, agents rely on those same systems for the structured, connected data that lets people and AI work effectively together.

## Traditional vs. AI-native SDLC workflows

An AI-native SDLC is the next evolution. It builds on the same vision and collapses remaining hand-offs into continuous, AI-supported loops where product, design, and engineering co-create in real time, and where agents help humans do the work at a new pace and scale.

Today, most organizations sit somewhere between the traditional and AI-native models. To realize the full benefits of an AI-native SDLC at enterprise scale, it's essential that work activity and knowledge are captured in systems of record in order to provide AI with continuous context and consistent measurement abilities.

| Workflow | Traditional SDLC | AI-native SDLC | Atlassian approach |
| Planning | Requirements are defined manually with incomplete knowledge of the code, causing downstream problems with significant time spent aligning teams. | AI synthesizes customer needs and code context into requirements, captured as versioned spec files in the repo. | Teamwork Graph pulls in relevant context from across the org (Jira, Confluence, third-party sources), so plans reflect what other teams are doing. Jira Product Discovery evaluates ideas against customer feedback; Jira turns them into connected, agent-ready tasks. |
| Design | Static mockups and manually written briefs are handed off to developers for every change. | Agent sessions are guided by standards that are stored alongside the code. Live prototypes replace static frames; designers can contribute UI code and bug fixes directly. | Design standards are grounded in the Teamwork Graph. Agents in Jira let designers and PMs ship UI updates and bug fixes directly, and Loom video feedback drives AI revisions. |
| Development | Developers pick up tasks, research and plan implementation, then start writing code. Velocity and quality are bottlenecked by individual throughput and skill. | Developers work with agents for planning, generating, and testing code. Quality depends on AI context and velocity relies on effective agent orchestration. | Coding agents use the Teamwork Graph CLI to combine code and organizational context. Each session's decisions flow back to the graph, so knowledge compounds across teams. |
| Review | Humans manually review every change, standards are inconsistent, and feedback is slow. | AI reviews changes first, applying shared standards across new and existing code. | Atlassian's AI Reviewer and third-party coding agents validate changes against dependencies mapped in the Teamwork Graph. Standards are centrally defined and governance is auditable in the system of record. |
| Maintenance | Incidents and errors are manually triaged and resolved; KTLO and reliability work often gets deprioritized due to limited engineering capacity. | Agents help triage, resolve, and document routine work, escalating only when needed. Teams shift more capacity toward new capabilities. | Jira Service Management automates incident triage. Agents trace impact across teams via the graph and feed related work items back into planning. Governed agent loops in Jira continuously scan for well-defined work and turn backlog items into pull requests. |

## Platform investments

### Context graph

WHY IT MATTERS: AI agents may have the intelligence to write, refactor, and review code, but they face the same challenge development teams always have: making sense of the context surrounding each task. Agents need the same context supplied to them for every task in order to produce high-quality output.

WHAT GOOD LOOKS LIKE: a context graph containing interconnected data spanning code repositories, work items, documentation, technical standards, meeting recordings, and chat, made accessible to humans and agents through a permissions-aware layer.

ATLASSIAN APPROACH: the Teamwork Graph combines data from 50+ connected sources with Jira, Confluence, and Loom: a living map of work, code, people, decisions, and dependencies. Governance and permissions are enforced at the data layer, so what a person can see is exactly what an agent can act on. Reachable from Atlassian apps, terminals, IDEs, or any agent surface via MCP or CLI. Agent and human activity flows back into the graph, so the system of record maintains itself autonomously.

Research at a glance: In internal benchmarks, agents with access to the Teamwork Graph delivered 44% more accurate results while using 48% fewer tokens compared to agents operating without it. (Vendor-reported internal benchmark; methodology not published.)

### Measurement

(Section intro captured; detail elided. The playbook holds that reliable measurement is only possible when metadata from new SDLC workflows is consistently captured and accessible.)

## Workflow shifts / Navigating change

(Elided middle. Per Atlassian's related coverage: "Preserve accountability. Keep humans clearly in charge of judgment, quality, and governance while AI handles execution and enforcement. Governed agent loops (scoped, standards-aware, and captured in systems of record) are the ones that scale.")

## Related Atlassian claims (from tail of page)

- "The AI-native SDLC is paying off: 19% more PRs and 2–3 hours saved per developer per week" (linked Atlassian blog; also cites "93% of developers use AI tools and nearly 30% of code is AI-authored").
- "Atlassian brings the AI-native SDLC from playbook to production" cites a 2026 AI SDLC study: 94% of engineering leaders said their teams are already using AI, yet only 6% said they have [a mature/operating model — truncated].

(Nav/footer boilerplate stripped.)
