# Resolve dirty retained worktrees

## Background

The retained-worktree cleanup inventory on 2026-05-16 found 13 worktrees with uncommitted changes. These were intentionally left in place to avoid losing local work.

Source issue: `issues/2026-05-16T001657Z-follow-up-retained-worktrees-after-cleanup.md`

## Worktrees

Review each worktree, then commit, stash, copy the changes into an active task, or explicitly discard the changes. Remove the worktree and local branch only after its local changes are safe.

- [ ] `worktrees/codex-app-server-shared-app-server-shared-core-20260509` (`codex/app-server-shared-core`)
  - Local edits: `docs/2026-05-09.md`, `src/index.test.ts`
  - Branch status: otherwise merged with `origin/main`
- [ ] `worktrees/domainprocessschema.mbt-app-server-schema-session-20260509` (`codex/app-server-schema-session`)
  - Local edits: `README.mbt.md`, `docs/2026-05-09.md`, `issues/`
  - Branch status: otherwise merged with `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-expression-language-v1-r2-20260509` (`codex/expression-language-v1-r2`)
  - Local edits: staged README/doc/issue moves
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r2-20260509` (`codex/generated-artifact-goldens-r2`)
  - Local edits: staged fixture/test/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-normalized-schema-output-r2-20260509` (`codex/normalized-schema-output-r2`)
  - Local edits: staged README/doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-package-metadata-refresh-20260509` (`codex/package-metadata-refresh`)
  - Local edits: `moon.mod.json`, `issues/closed/2026-05-06T195750-chore-refresh-package-metadata.md`
  - Branch status: otherwise merged with `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r2-20260509` (`codex/runtime-adapter-boundary-r2`)
  - Local edits: staged README/doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-schema-contract-v1-r2-20260509` (`codex/schema-contract-v1-r2`)
  - Local edits: staged doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-structured-diagnostics-r2-20260509` (`codex/structured-diagnostics-r2`)
  - Local edits: staged doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r2-20260509` (`codex/transition-semantics-v1-r2`)
  - Local edits: staged README/doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/domainprocessschema.mbt-versioned-manifest-envelope-r2-20260509` (`codex/versioned-manifest-envelope-r2`)
  - Local edits: staged doc/issue changes
  - Branch status: unmerged, `ahead=37`, `behind=10` vs `origin/issue1-complete`
- [ ] `worktrees/papyr.mbt-app-server-authoring-publish-20260509` (`codex/app-server-authoring-publish`)
  - Local edits: `README.mbt.md`, `issues/20260509T093000Z-architecture-define-codex-app-server-authoring-and-publishing-contract.md`
  - Branch status: otherwise merged with `origin/main`
- [ ] `worktrees/vizprocess.mbt-app-server-process-workspace-20260509` (`codex/app-server-process-workspace`)
  - Local edits: staged README/doc/example/issue changes
  - Branch status: otherwise merged with `origin/main`

## Acceptance criteria

- [ ] Every listed worktree is clean or intentionally deleted.
- [ ] Any useful local changes are committed, stashed, or copied into an active task before deletion.
- [ ] Deleted worktrees are removed through `git worktree remove` from the owning repo.
- [ ] Local and remote branches are deleted only after the branch is safe to remove.
