# Flutter Storefront – Phase 1 Kanban Board

## Overview
Visual tracking board for Flutter Storefront Phase 1 MVP. This Kanban captures the state of all Phase 1 tasks and enables transparent progress tracking across the team.

**Repository:** flutter-storefront  
**Phase:** Phase 1 (MVP Foundation)  
**Goal:** Establish CI/CD, state management wiring, cart persistence, checkout skeleton, and initial test coverage.

---

## 📋 Board Columns

| Column | Purpose | Entry Criteria | Exit Criteria |
|--------|---------|----------------|---------------|
| **Backlog** | Issues not yet prioritized or blocked | New issue created | Reviewed & prioritized |
| **Ready / Aligned** | Issues ready to start (dependencies clear, requirements defined) | Accepted, no blockers | Work begins (moved to In Progress) |
| **In Progress** | Active development | Developer assigned, work started | Code review initiated |
| **In Review / QA** | Code review or testing phase | PR created and linked | Approved & merged |
| **Done** | Completed and merged to main | PR merged | Closed issue |

---

## 🎯 Phase 1 Backlog Status

### Ready / Aligned (In Project – Todo Status)

| # | Title | Size | Labels | Status | Assignee | Issue Link |
|---|-------|------|--------|--------|----------|-----------|
| 1 | Harden CI & Analyzer | S | `infra` `critical` `tests` | ⛳ In Progress | @GeoAziz | [#9](https://github.com/GeoAziz/flutter-storefront/issues/9) |
| 2 | Route Name Standardization | S | `infra` `critical` | ✅ Todo | @GeoAziz | [#10](https://github.com/GeoAziz/flutter-storefront/issues/10) |
| 3 | ProviderScope Wiring & ProductRepository Toggle | S | `backend` `infra` | ✅ Done | @GeoAziz | [#11](https://github.com/GeoAziz/flutter-storefront/issues/11) |

### In Progress

| # | Title | Size | Labels | Status | Assignee | Issue Link |
|---|-------|------|--------|--------|----------|-----------|
| — | — | — | — | — | — | — |

### In Review / QA

| # | Title | Size | Labels | Status | Assignee |
|---|-------|------|--------|--------|----------|
| — | — | — | — | — | — |

### Backlog (Schedule for later in Phase 1)

| # | Title | Size | Labels | Status | Blocking | Depends On | Issue Link |
|---|-------|------|--------|--------|----------|-----------|-----------|
| 4 | Cart Provider & Local Persistence | M | `backend` `enhancement` | ✅ Done | Issue #5, #6 | #3 (ProviderScope) | [#12](https://github.com/GeoAziz/flutter-storefront/issues/12) |
| 5 | Complete Home & Product Screens Provider Wiring | M | `backend` `product` | ✅ Done | Issue #4, #7 | #3 (ProviderScope) | [#13](https://github.com/GeoAziz/flutter-storefront/issues/13) |
| 6 | Checkout Skeleton & Payment Adapter | M | `backend` `enhancement` | ✅ Todo | — | #4 (Cart), #3 | [#14](https://github.com/GeoAziz/flutter-storefront/issues/14) |
| 7 | Add End-to-End Smoke Tests | M | `tests` `critical` | ✅ Todo | — | #1 (CI) | [#15](https://github.com/GeoAziz/flutter-storefront/issues/15) |
| 8 | Backend Contract: Products API | S | `backend` `critical` | ✅ Todo | — | #3 (ProviderScope) | [#16](https://github.com/GeoAziz/flutter-storefront/issues/16) |

---

## 🏷️ Labels Guide

| Label | Color | Purpose | Use When |
|-------|-------|---------|----------|
| `infra` | ![#d4af37](https://via.placeholder.com/15/d4af37/000000?text=+) Gold | Infrastructure, build, CI/CD, tooling | Build system, workflows, deployment, configuration |
| `backend` | ![#0366d6](https://via.placeholder.com/15/0366d6/000000?text=+) Blue | State management, data layer, API integration | Providers, repositories, local storage, API contracts |
| `product` | ![#28a745](https://via.placeholder.com/15/28a745/000000?text=+) Green | Feature work, UI wiring, user-facing changes | Screens, navigation, new features, UX improvements |
| `tests` | ![#fbca04](https://via.placeholder.com/15/fbca04/000000?text=+) Yellow | Test coverage, unit/widget/integration tests | Adding or fixing tests, test infrastructure |
| `enhancement` | ![#a2eeef](https://via.placeholder.com/15/a2eeef/000000?text=+) Cyan | Non-critical feature improvements | Optional improvements, nice-to-haves |
| `ui` | ![#e99695](https://via.placeholder.com/15/e99695/000000?text=+) Red | User interface, styling, responsive design | UI bugs, design system, responsive fixes |
| `critical` | ![#d73a49](https://via.placeholder.com/15/d73a49/000000?text=+) Dark Red | Must-have, blocks other work, high priority | Blockers, security issues, essential features |
| `design` | ![#9d4edd](https://via.placeholder.com/15/9d4edd/000000?text=+) Purple | Design system, accessibility, brand guidelines | Design specs, a11y improvements, brand consistency |

---

## 📊 Phase 1 Timeline & Milestones

### Milestone 1: Foundation (Issues #1–3)
**Goal:** Establish CI/CD pipeline, clean up codebase, wire core state management  
**Expected Duration:** 1–2 weeks  
**Success Criteria:**  
- ✅ CI workflow passes all checks (flutter analyze, tests)
- ✅ Route names standardized across app
- ✅ ProviderScope wraps entire app, repositories wired correctly

### Milestone 2: Features (Issues #4–6)
**Goal:** Implement cart persistence, complete provider wiring for all screens, checkout skeleton  
**Expected Duration:** 2–3 weeks  
**Success Criteria:**  
- ✅ Cart persists across app restarts
- ✅ All major screens (Home, Product, Discovery) consume providers
- ✅ Checkout flow skeleton created with payment adapter

### Milestone 3: Quality (Issues #7–8)
**Goal:** Comprehensive testing, finalize API contracts  
**Expected Duration:** 1–2 weeks  
**Success Criteria:**  
- ✅ E2E smoke tests cover all major flows
- ✅ CI includes test execution
- ✅ Backend API contract finalized, ready for integration

---

## 📝 How to Use This Board

### For Developers
1. **Check Ready / Aligned:** Pick an issue, assign yourself, move to In Progress
2. **Work:** Create a feature branch, link it to the issue
3. **Code Review:** Create a PR, move issue to In Review / QA
4. **Merge:** Once approved, merge PR and move issue to Done
5. **Update Board:** Move issues manually as status changes (or use GitHub Project Automation)

### For Team Lead
- Review backlog weekly; align on priorities and dependencies
- Unblock In Progress issues; resolve conflicts
- Update Kanban.md after each milestone (or automate via GitHub Projects)
- Track velocity (completed story points / sprint)

### For Product
- Review Done column for completed features
- Prioritize new Backlog items based on impact
- Monitor critical path (issues marked `critical`)

---

## 🔄 Workflow Rules

1. **Pull Requests:**
   - Branch naming: `feature/issue-#N-short-description` (e.g., `feature/issue-1-harden-ci`)
   - Link PR to issue: "Closes #N" in PR description
   - Require 1+ approvals before merge
   - All CI checks must pass

2. **Issue Management:**
   - Always assign issues to owner
   - Apply all relevant labels (at least 1)
   - Add to project board immediately (Ready or Backlog)
   - Link blocking issues in description

3. **Commits:**
   - Format: `[#N] Short description` (e.g., `[#1] Fix analyzer warnings in CI`)
   - Squash before merge if multiple small commits
   - Write clear commit messages (what + why)

4. **Reviews:**
   - Comment with code suggestions
   - Approve only when ready to merge
   - Request changes for rework (move back to In Progress)

---

## 📌 Current Status Summary

**Total Issues:** 8  
**In Todo (Ready):** 5  
**In Progress:** 1  
**Done:** 3  

**Phase 1 Progress:** 37.5% (3 / 8 issues complete)

**Next Action:** Begin Phase 1 work on Issues #9 & #10 (Harden CI & Analyzer, Route Name Standardization). Move issues to In Progress as work begins. Update Kanban.md as issues progress.

**Quick Links to Issues:**
- [Issue #9: Harden CI & Analyzer](https://github.com/GeoAziz/flutter-storefront/issues/9)
- [Issue #10: Route Name Standardization](https://github.com/GeoAziz/flutter-storefront/issues/10)
- [Issue #11: ProviderScope Wiring](https://github.com/GeoAziz/flutter-storefront/issues/11)
- [All Phase 1 Issues](https://github.com/GeoAziz/flutter-storefront/issues?q=is%3Aissue+label%3Acritical+OR+label%3Ainfra+OR+label%3Abackend+OR+label%3Aenhancement+OR+label%3Atests)

---

## 🚀 Quick Links

- **Project Board:** [Flutter Storefront – Phase 1](https://github.com/abuanwar072/flutter-storefront/projects/1)
- **Repository:** [flutter-storefront](https://github.com/abuanwar072/flutter-storefront)
- **PROJECT_GUIDE.md:** [Strategic Roadmap](./PROJECT_GUIDE.md)
- **REMOTE_REPO_SETUP.md:** [API Architecture](./REMOTE_REPO_SETUP.md)

---

## 📋 Template: Issue Description

Use this template when creating issues:

```markdown
## Description
[Brief description of what this issue addresses]

## Acceptance Criteria
- [ ] Specific task 1
- [ ] Specific task 2
- [ ] Specific task 3

## Technical Notes
[Any relevant architecture decisions, file paths, or dependencies]

## Related Issues
[Link to blocking/dependent issues, e.g., "Depends on #1"]

## Labels
[List labels: infra, backend, tests, critical, etc.]
```

---

**Last Updated:** 2025-12-15  
**Maintained By:** @devmahnx  
**Review Schedule:** Weekly syncs or milestone completions

---

## 🤖 Automation (GitHub Actions)

We run a small, conservative GitHub Action to help keep the Kanban board and PR labels tidy. It is intentionally limited in scope and uses the repository-provided token (no external services).

Behavior summary:
- On PR opened:
   - If the PR is a draft: the Action adds the `Draft` label and posts a short comment explaining how to convert the PR to ready-for-review.
   - If the PR is opened non-draft: the Action adds the `In Review` label and posts a short confirmation comment.
- On PR -> "Ready for review": the Action removes `Draft`, ensures `In Review` is present, and posts a short note.
- On PR closed & merged: the Action marks the PR `Done`, attempts to find `Closes #N` (or `Fixes #N`, `Resolves #N`) statements in the PR body and will close those linked issues and comment on them.
- On PR closed without merge: the Action marks the PR `Abandoned` and notifies in a comment.

Why this exists:
- Small automation reduces manual label management and makes the project board state more consistent.

How to opt out / notes for maintainers:
- If you don't want a comment or label on a particular PR, you can remove the label after the Action runs or omit `Closes #N` lines if you don't want the issue closed automatically.
- The Action uses the labels `Draft`, `In Review`, `Done`, and `Abandoned`. Ensure those labels exist in the repository settings so the Action can add them.

If you'd like the Action to move project cards (GitHub Projects) or perform other advanced behaviors, we'll treat that as a follow-up (requires additional permissions or a GitHub App).
