# Resolve unmerged retained worktrees

## Background

The retained-worktree cleanup inventory on 2026-05-16 found clean worktrees whose branch HEAD was not an ancestor of the detected default branch. These were intentionally left in place because deleting them could drop unmerged work.

Source issue: `issues/2026-05-16T001657Z-follow-up-retained-worktrees-after-cleanup.md`

## Resolution

Completed on 2026-05-27 with a conservative archive policy:

- The legacy root `worktrees/` directories were removed through `git worktree remove --force`.
- Local and remote branches were kept so unmerged commits remain recoverable.
- Branches with gone upstreams were treated as archived local branches.
- Branches whose upstream still exists were treated as review/archive branches and left intact.

## Worktrees

- [x] `worktrees/domainprocessschema-mbt-cloudflare-worker` (`chore/cloudflare-worker-deploy`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema-mbt-contract-v1-envelope-diagnostics` (`spec/contract-v1-envelope-diagnostics`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema-mbt-issue2-wasm` (`issue2-moonbit-wasm`)
  - Kept branch with `origin/pr6-comment-fix` review target; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-app-server-schema-runtime-session-r6-20260510` (`codex/app-server-schema-runtime-session-r6`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-audit-event-manifest-r2-20260509` (`codex/audit-event-manifest-r2`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-basic-plan-r6-20260510` (`codex/basic-plan-r6`)
  - Kept branch with `origin/pr-21-r2` review/archive target; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-expression-language-v1-r5-20260510` (`codex/expression-language-v1-r5`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r4-20260510` (`codex/generated-artifact-goldens-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-manifest-envelope-r4-20260510` (`codex/manifest-envelope-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-normalized-schema-output-r5-20260510` (`codex/normalized-schema-output-r5`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-package-metadata-refresh-r4-20260510` (`codex/package-metadata-refresh-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-reference-lookup-contract-r2-20260509` (`codex/reference-lookup-contract-r2`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r3-20260510` (`codex/runtime-adapter-boundary-r3`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-schema-contract-v1-r4-20260510` (`codex/schema-contract-v1-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-schema-editor-production-app-20260512` (`codex/schema-editor-production-app`)
  - Kept branch with `origin/codex/schema-editor-production-app` review/archive target; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-structured-diagnostics-r4-20260510` (`codex/structured-diagnostics-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r5-20260510` (`codex/transition-semantics-v1-r5`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/domainprocessschema.mbt-versioned-contract-roadmap-r4-20260510` (`codex/versioned-contract-roadmap-r4`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/mhx.mbt-runtime-npm-boundaries-20260511` (`codex/runtime-npm-boundaries`)
  - Archived local branch; removed the worktree.
- [x] `worktrees/orbit.mbt-fs-agent-permissions-20260509-cc` (`cc/fs-agent-permissions`)
  - Kept branch with `origin/cc/fs-agent-permissions` review/archive target; removed the worktree.
- [x] `worktrees/orbit.mbt-multi-agent-orchestration-20260509-cc` (`cc/multi-agent-orchestration`)
  - Kept branch with `origin/cc/multi-agent-orchestration` review/archive target; removed the worktree.
- [x] `worktrees/orbit.mbt-replay-debugger-20260509-cc` (`cc/replay-debugger`)
  - Kept branch with `origin/cc/replay-debugger` review/archive target; removed the worktree.
- [x] `worktrees/orbit.mbt-streaming-chat-ui-20260509-cc` (`cc/streaming-chat-ui`)
  - Kept branch with `origin/cc/streaming-chat-ui` review/archive target; removed the worktree.
- [x] `worktrees/vizprocess.mbt-practical-cloudflare-app-20260512` (`codex/practical-cloudflare-app`)
  - Archived local branch; removed the worktree.

## Acceptance criteria

- [x] Every listed branch has an explicit decision: merge, review, archive, or delete.
- [x] Any branch kept for review is pushed and has a recorded PR or review target.
- [x] Deleted worktrees are removed through `git worktree remove` from the owning repo.
- [x] Local and remote branches are deleted only after the branch decision is complete.
