# Resolve dirty retained worktrees

## Background

The retained-worktree cleanup inventory on 2026-05-16 found worktrees with uncommitted changes. They were intentionally left in place to avoid losing local work.

Source issue: `issues/2026-05-16T001657Z-follow-up-retained-worktrees-after-cleanup.md`

## Resolution

Completed on 2026-05-27 with a conservative archive policy:

- Useful local edits were preserved as local commits on the existing branches.
- The legacy root `worktrees/` directories were removed through `git worktree remove --force`.
- Local and remote branches were not deleted.
- `worktrees/papyr.mbt-app-server-authoring-publish-20260509` was already absent when this cleanup ran, so no additional action was needed for that entry.

## Worktrees

- [x] `worktrees/codex-app-server-shared-app-server-shared-core-20260509` (`codex/app-server-shared-core`)
  - Preserved local edits in commit `1474dac` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-app-server-schema-session-20260509` (`codex/app-server-schema-session`)
  - Preserved local edits in commit `1926da1` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-expression-language-v1-r2-20260509` (`codex/expression-language-v1-r2`)
  - Preserved local edits in commit `fda0e7b` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r2-20260509` (`codex/generated-artifact-goldens-r2`)
  - Preserved local edits in commit `8140f77` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-normalized-schema-output-r2-20260509` (`codex/normalized-schema-output-r2`)
  - Preserved local edits in commit `77b349b` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-package-metadata-refresh-20260509` (`codex/package-metadata-refresh`)
  - Preserved local edits in commit `0c7ed98` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r2-20260509` (`codex/runtime-adapter-boundary-r2`)
  - Preserved local edits in commit `8510120` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-schema-contract-v1-r2-20260509` (`codex/schema-contract-v1-r2`)
  - Preserved local edits in commit `658918c` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-structured-diagnostics-r2-20260509` (`codex/structured-diagnostics-r2`)
  - Preserved local edits in commit `30dc594` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r2-20260509` (`codex/transition-semantics-v1-r2`)
  - Preserved local edits in commit `a512239` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-versioned-manifest-envelope-r2-20260509` (`codex/versioned-manifest-envelope-r2`)
  - Preserved local edits in commit `37c5d52` (`chore: preserve retained worktree changes`), then removed the worktree.
- [x] `worktrees/papyr.mbt-app-server-authoring-publish-20260509` (`codex/app-server-authoring-publish`)
  - Already absent at cleanup time; treated as resolved.
- [x] `worktrees/vizprocess.mbt-app-server-process-workspace-20260509` (`codex/app-server-process-workspace`)
  - Preserved local edits in commit `a50e4fe` (`chore: preserve retained worktree changes`), then removed the worktree.

## Acceptance criteria

- [x] Every listed worktree is clean or intentionally deleted.
- [x] Any useful local changes are committed, stashed, or copied into an active task before deletion.
- [x] Deleted worktrees are removed through `git worktree remove` from the owning repo.
- [x] Local and remote branches are deleted only after the branch is safe to remove.
