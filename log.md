---
title: Work Log
description: Append-only audit trail of changes to this knowledge base.
---

# Work Log

Append-only audit trail. Add one dated entry per turn that creates, edits, or restructures content. The knowledge-base skill describes what to log and the entry shape.

## 2026-11-03: argocd PoC (res-lab)

- Argo CD v3.5.6 on kind: Application + ApplicationSet auto-sync and self-heal PASS; Flux 2.9.6 to 2.10.0 RBAC break reproduced (PASS); Argo CD footprint measured, Flux half pending approval (PARTIAL).
- Files touched: [research/argocd/poc/README](./research/argocd/poc/README.md) plus small manifests and scripts in the same folder
- Open follow-ups: Flux footprint run, PoC-2 (3.6 compression), PoC-3 (image update)

## 2026-11-03: argocd report draft

- res-writer drafted the argocd report and one guide from findings and PoC results (status: draft, awaiting owner review).
- Files touched: [research/argocd/report](./research/argocd/report.md), [research/argocd/guide-bootstrap-argocd](./research/argocd/guide-bootstrap-argocd.md)
- Sources ingested: none
- Open follow-ups: Flux footprint run (needs owner approval), PoC-2 and PoC-3 not run, fluxcd/flux2#6139 not ingested, app-of-apps not covered

## 2026-11-04: crossplane PoC (res-lab)

- Crossplane v2.4.3 + provider-kubernetes v1.4.1 + fn-p&t v0.11.2 on kind: namespaced `App` XR composing a Deployment + Service through a Pipeline, InjectedIdentity (no cloud creds). create/update/delete all PASS; drift revert PARTIAL (whole-object + leaf-field drift self-heal in ~2-20s with `spec.watch:true`, but list-field `ports[]` drift under SSA errors with ReconcileError).
- Files touched: [research/crossplane/poc/README](./research/crossplane/poc/README.md) plus `00-06` manifests in the same folder
- Open follow-ups: confirmed the `upbound/provider-aws` repo 301-redirect (PoC-4 pin needs re-verification); the SSA list-field drift limitation (unverified whether a newer provider or non-alpha management-policy fixes it) could be re-checked.

## 2026-11-04: crossplane report draft

- res-writer drafted the crossplane report and one how-to guide from findings and the default PoC (status: draft, awaiting owner review). Recommendation is tentative: core XR loop works; provider-kubernetes `Object` drift handling is weak (10m default poll, list-field SSA error).
- Files touched: [research/crossplane/report](./research/crossplane/report.md), [research/crossplane/guide-namespaced-xr-app](./research/crossplane/guide-namespaced-xr-app.md)
- Sources ingested: none
- Open follow-ups: PoC-2 to PoC-5 not run; direct-composition drift test; source for provider-kubernetes poll default and `watch` maturity; kind version mismatch in PoC record

## 2026-11-09: k8s-cost-monitoring report draft

- res-writer drafted a screen-level report comparing OpenCost, Robusta KRR and Goldilocks (status: draft, no findings or PoC). Only OpenCost tracks costs; KRR and Goldilocks recommend CPU/memory settings. Tentative recommendation: OpenCost, plus KRR for right-sizing.
- Files touched: [research/k8s-cost-monitoring/report](./research/k8s-cost-monitoring/report.md)
- Sources ingested: none
- Open follow-ups: KRR/Goldilocks install prerequisites; OpenCost allocation accuracy vs cloud bill; preserved Kubernetes docs for requests/limits and VPA; optional PoC
