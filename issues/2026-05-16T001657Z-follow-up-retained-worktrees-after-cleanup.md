# Follow up retained worktrees after cleanup

## Background

The worktree cleanup on 2026-05-16 removed clean worktrees whose branch HEAD was already an ancestor of the repo default branch. The entries below were intentionally retained because deleting them could discard local changes, drop unmerged work, or remove a default/detached checkout that needs manual inspection.

Cleanup logs:

- `/tmp/moonrepo-worktree-cleanup-20260516084711.log`
- `/tmp/moonrepo-worktree-cleanup-continue-20260516084738.log`
- `/tmp/moonrepo-worktree-cleanup-final-20260516084819.log`

## Summary

- Dirty worktrees: 13
- Unmerged worktrees: 24
- Default or detached worktrees: 4

## Dirty worktrees

These worktrees have uncommitted changes. Review, commit, stash, or intentionally discard the changes before removing the worktree and branch.

- [ ] `worktrees/codex-app-server-shared-app-server-shared-core-20260509` (`codex/app-server-shared-core`)
- [ ] `worktrees/domainprocessschema.mbt-app-server-schema-session-20260509` (`codex/app-server-schema-session`)
- [ ] `worktrees/domainprocessschema.mbt-expression-language-v1-r2-20260509` (`codex/expression-language-v1-r2`)
- [ ] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r2-20260509` (`codex/generated-artifact-goldens-r2`)
- [ ] `worktrees/domainprocessschema.mbt-normalized-schema-output-r2-20260509` (`codex/normalized-schema-output-r2`)
- [ ] `worktrees/domainprocessschema.mbt-package-metadata-refresh-20260509` (`codex/package-metadata-refresh`)
- [ ] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r2-20260509` (`codex/runtime-adapter-boundary-r2`)
- [ ] `worktrees/domainprocessschema.mbt-schema-contract-v1-r2-20260509` (`codex/schema-contract-v1-r2`)
- [ ] `worktrees/domainprocessschema.mbt-structured-diagnostics-r2-20260509` (`codex/structured-diagnostics-r2`)
- [ ] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r2-20260509` (`codex/transition-semantics-v1-r2`)
- [ ] `worktrees/domainprocessschema.mbt-versioned-manifest-envelope-r2-20260509` (`codex/versioned-manifest-envelope-r2`)
- [ ] `worktrees/papyr.mbt-app-server-authoring-publish-20260509` (`codex/app-server-authoring-publish`)
- [ ] `worktrees/vizprocess.mbt-app-server-process-workspace-20260509` (`codex/app-server-process-workspace`)

## Unmerged worktrees

These worktrees are clean, but their branch HEAD is not an ancestor of the detected default branch. Decide whether to finish, merge, push, archive, or explicitly delete them.

- [ ] `worktrees/domainprocessschema-mbt-cloudflare-worker` (`chore/cloudflare-worker-deploy`)
- [ ] `worktrees/domainprocessschema-mbt-contract-v1-envelope-diagnostics` (`spec/contract-v1-envelope-diagnostics`)
- [ ] `worktrees/domainprocessschema-mbt-issue2-wasm` (`issue2-moonbit-wasm`)
- [ ] `worktrees/domainprocessschema.mbt-app-server-schema-runtime-session-r6-20260510` (`codex/app-server-schema-runtime-session-r6`)
- [ ] `worktrees/domainprocessschema.mbt-audit-event-manifest-r2-20260509` (`codex/audit-event-manifest-r2`)
- [ ] `worktrees/domainprocessschema.mbt-basic-plan-r6-20260510` (`codex/basic-plan-r6`)
- [ ] `worktrees/domainprocessschema.mbt-expression-language-v1-r5-20260510` (`codex/expression-language-v1-r5`)
- [ ] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r4-20260510` (`codex/generated-artifact-goldens-r4`)
- [ ] `worktrees/domainprocessschema.mbt-manifest-envelope-r4-20260510` (`codex/manifest-envelope-r4`)
- [ ] `worktrees/domainprocessschema.mbt-normalized-schema-output-r5-20260510` (`codex/normalized-schema-output-r5`)
- [ ] `worktrees/domainprocessschema.mbt-package-metadata-refresh-r4-20260510` (`codex/package-metadata-refresh-r4`)
- [ ] `worktrees/domainprocessschema.mbt-reference-lookup-contract-r2-20260509` (`codex/reference-lookup-contract-r2`)
- [ ] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r3-20260510` (`codex/runtime-adapter-boundary-r3`)
- [ ] `worktrees/domainprocessschema.mbt-schema-contract-v1-r4-20260510` (`codex/schema-contract-v1-r4`)
- [ ] `worktrees/domainprocessschema.mbt-schema-editor-production-app-20260512` (`codex/schema-editor-production-app`)
- [ ] `worktrees/domainprocessschema.mbt-structured-diagnostics-r4-20260510` (`codex/structured-diagnostics-r4`)
- [ ] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r5-20260510` (`codex/transition-semantics-v1-r5`)
- [ ] `worktrees/domainprocessschema.mbt-versioned-contract-roadmap-r4-20260510` (`codex/versioned-contract-roadmap-r4`)
- [ ] `worktrees/mhx.mbt-runtime-npm-boundaries-20260511` (`codex/runtime-npm-boundaries`)
- [ ] `worktrees/orbit.mbt-fs-agent-permissions-20260509-cc` (`cc/fs-agent-permissions`)
- [ ] `worktrees/orbit.mbt-multi-agent-orchestration-20260509-cc` (`cc/multi-agent-orchestration`)
- [ ] `worktrees/orbit.mbt-replay-debugger-20260509-cc` (`cc/replay-debugger`)
- [ ] `worktrees/orbit.mbt-streaming-chat-ui-20260509-cc` (`cc/streaming-chat-ui`)
- [ ] `worktrees/vizprocess.mbt-practical-cloudflare-app-20260512` (`codex/practical-cloudflare-app`)

## Default or detached worktrees

These were retained because the branch was the detected default branch or `HEAD`. Inspect whether they are active checkouts, temporary worktrees, or old detached states before deleting.

- [ ] `worktrees/domainprocessschema-mbt-issue1` (`issue1-complete`)
- [ ] `worktrees/papyr-mbt-publish` (`HEAD`)
- [ ] `worktrees/papyr.mbt-deploy-ci-fix-20260515` (`HEAD`)
- [ ] `worktrees/vizprocess.mbt-process-workspace-session-store-20260510` (`main`)

## Acceptance criteria

- Each retained worktree is either removed or documented as intentionally retained.
- Dirty worktree changes are committed, stashed, copied into an active task, or explicitly discarded.
- Unmerged branches are merged, pushed for review, archived, or explicitly deleted.
- Remote branches are deleted only after their local branch is safe to remove.
