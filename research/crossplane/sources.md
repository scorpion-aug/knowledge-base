
## Scope

Topic: how to use Crossplane (github.com/crossplane/crossplane). Screened the core project, official docs, and the package ecosystem needed to run Crossplane v2 (providers, composition functions, codegen). Decision: what res-researcher digs into for findings.md and the usage guide. Search date: 2026-11-04; health data fetched same day unless marked unverified. Crossplane is CNCF Graduated since 2025-10-28 ([CNCF page](https://www.cncf.io/projects/crossplane/), TODO: needs ingest). v2 usage differs sharply from v1-era tutorials: claims removed, native patch-and-transform removed, namespaced XRs/MRs, fully-qualified package images required.

## Candidates

| Candidate | What it is | Last release (date) | Commit activity | Maintainers | License | Adoption | Verdict | Reason | Sources |
|---|---|---|---|---|---|---|---|---|---|
| [crossplane/crossplane](https://github.com/crossplane/crossplane) | Core control-plane framework: XRs, compositions, function runtime, Operations, package manager, CLI | v2.4.3 (2026-10-22); v2.5 due Nov 2026 (README EOL table) | main merge 2026-11-02; 9,265 commits; 4 active release lines (v1.20/v2.2/v2.3/v2.4) | CNCF project; visible leads lsviben, jbw976, adamwg | Apache-2.0 | 12.2k stars, 1.3k forks; CNCF Graduated 2025-10-28 | dig deeper | Healthy; v1.20 EOL Nov 2026 makes v2-only guidance the right target | [README](../../external-sources/crossplane-core-readme.md), [v2 what's-new](../../external-sources/crossplane-v2-whats-new-docs.md) |
| [Official docs v2.4](https://docs.crossplane.io/latest/) | Canonical usage path: Install, Control Plane Projects, Composition, Managed Resources, Operations quickstarts + guides | n/a (v2.4 latest; v2.3/2.2/1.20 kept) | n/a | Crossplane project | CC-BY-4.0 | only official doc set | dig deeper | Get Started defines the current v2 workflow: xpkg.crossplane.io packages, functions instead of native P&T | [Get Started index](https://docs.crossplane.io/latest/get-started/) (TODO: ingest), [v2 what's-new](../../external-sources/crossplane-v2-whats-new-docs.md) |

Rows below continue after the docs row; cells marked unverified were not read from commit graphs or license files.

## Preserved sources

Links to `external-sources/<topic>-*.md` captured for dig-deeper candidates.

