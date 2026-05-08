---
name: opencode-issue-review
description: Review and improve local issue documents with the opencode CLI until it returns LGTM. Use when refining `issues/**/*.md` in repos/<repo> or a moonrepo worktree through an external reviewer loop.
---

# Opencode Issue Review

## When To Use

Use this skill when you want to tighten issue or spec documents under `issues/` by running an external review loop with `opencode`:

- newly written issue files need a critical pass
- migrated GitHub issues need structure, acceptance criteria, or rationale
- a repo already has local issue docs and you want an explicit `LGTM` gate before commit

This skill is designed for the `moonrepo` layout and expects targets under `repos/<repo_name>` or `worktrees/<repo>-<task>-<date>`.

## Preconditions

- Run from the `moonrepo` workspace.
- `opencode` CLI is installed and callable.
- Target repo has a local `issues/` directory.
- Commands available: `opencode`, `git`, `rg`, `sed`.

## Review Loop

1. Narrow the review scope first. Review only the issue files you changed, not the whole repo.
2. Ask `opencode` for a strict output contract:
   - if the files are ready, output exactly `LGTM`
   - otherwise output only remaining actionable findings
3. Apply only the findings that materially improve the issue. Ignore style churn with no clear payoff.
4. Re-run the same focused review after each patch.
5. Stop only when `opencode` returns `LGTM`.

## Prompt Template

Run from the target repo:

```bash
opencode run "Review only the changed files under issues/ in this repo. If every changed issue file is implementation-ready and internally consistent, output exactly LGTM. Otherwise output only the remaining actionable findings.

Files:
- issues/<file-a>.md
- issues/<file-b>.md"
```

For a single file:

```bash
opencode run "Review only issues/<file>.md. If it is implementation-ready and internally consistent, output exactly LGTM. Otherwise output only the remaining actionable findings."
```

## What To Fix

Bias toward concrete issue quality:

- missing or weak acceptance criteria
- missing non-goals
- unclear dependency or blocking language
- contracts that are implied but not spelled out
- inconsistent terminology across related issues
- metadata drift from the repo's issue conventions
- examples that are too abstract to implement against

Do not expand scope just because the reviewer suggests adjacent work. Keep the issue aligned to its original intent.

## Editing Rules

- Prefer issue-ready prose over essay-style explanation.
- Make dependency statements explicit: blocked, not blocked, or future consumer.
- If a repo has a local issue template or metadata convention, conform to it before re-running review.
- When adding structured examples, keep them minimal but executable as a contract.
- Keep filenames and directory layout consistent with the repo's existing issue workflow.

## Validate After Apply

1. Re-run the focused `opencode` review and confirm it returns exactly `LGTM`.
2. Check `git status --short` in the target repo.
3. Commit only the issue files you intentionally changed.

Expected result: the changed `issues/*.md` files are sharper, implementation-oriented, and externally reviewed to `LGTM` before push.
