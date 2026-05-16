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

## Inventory result 2026-05-16

- Removed clean default/detached worktrees: 4
- Intentionally retained dirty worktrees: 13
- Intentionally retained clean unmerged worktrees: 24
- Remote branches were not deleted in this pass.

Follow-up tracking:

- `issues/2026-05-16T044019Z-resolve-dirty-retained-worktrees.md`
- `issues/2026-05-16T044019Z-resolve-unmerged-retained-worktrees.md`

## Dirty worktrees

These worktrees have uncommitted changes. Review, commit, stash, or intentionally discard the changes before removing the worktree and branch.

- [x] Retained: `worktrees/codex-app-server-shared-app-server-shared-core-20260509` (`codex/app-server-shared-core`) has local edits in `docs/2026-05-09.md`, `src/index.test.ts`; branch is otherwise merged with `origin/main`.
- [x] Retained: `worktrees/domainprocessschema.mbt-app-server-schema-session-20260509` (`codex/app-server-schema-session`) has local edits in `README.mbt.md`, `docs/2026-05-09.md`, `issues/`; branch is otherwise merged with `origin/issue1-complete`.
- [x] Retained: `worktrees/domainprocessschema.mbt-expression-language-v1-r2-20260509` (`codex/expression-language-v1-r2`) has staged local doc/issue moves and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r2-20260509` (`codex/generated-artifact-goldens-r2`) has staged fixture/test/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-normalized-schema-output-r2-20260509` (`codex/normalized-schema-output-r2`) has staged README/doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-package-metadata-refresh-20260509` (`codex/package-metadata-refresh`) has local edits in `moon.mod.json`, `issues/closed/2026-05-06T195750-chore-refresh-package-metadata.md`; branch is otherwise merged with `origin/issue1-complete`.
- [x] Retained: `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r2-20260509` (`codex/runtime-adapter-boundary-r2`) has staged README/doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-schema-contract-v1-r2-20260509` (`codex/schema-contract-v1-r2`) has staged doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-structured-diagnostics-r2-20260509` (`codex/structured-diagnostics-r2`) has staged doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-transition-semantics-v1-r2-20260509` (`codex/transition-semantics-v1-r2`) has staged README/doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/domainprocessschema.mbt-versioned-manifest-envelope-r2-20260509` (`codex/versioned-manifest-envelope-r2`) has staged doc/issue changes and is unmerged (`ahead=37`, `behind=10` vs `origin/issue1-complete`).
- [x] Retained: `worktrees/papyr.mbt-app-server-authoring-publish-20260509` (`codex/app-server-authoring-publish`) has local edits in `README.mbt.md`, `issues/20260509T093000Z-architecture-define-codex-app-server-authoring-and-publishing-contract.md`; branch is otherwise merged with `origin/main`.
- [x] Retained: `worktrees/vizprocess.mbt-app-server-process-workspace-20260509` (`codex/app-server-process-workspace`) has staged README/doc/example/issue changes; branch is otherwise merged with `origin/main`.

## Unmerged worktrees

These worktrees are clean, but their branch HEAD is not an ancestor of the detected default branch. Decide whether to finish, merge, push, archive, or explicitly delete them.

- [x] Retained: `worktrees/domainprocessschema-mbt-cloudflare-worker` (`chore/cloudflare-worker-deploy`) is clean but unmerged (`ahead=19`, `behind=10` vs `origin/issue1-complete`); top commit: `Add Cloudflare Worker deploy tasks for wasm demo`.
- [x] Retained: `worktrees/domainprocessschema-mbt-contract-v1-envelope-diagnostics` (`spec/contract-v1-envelope-diagnostics`) is clean but unmerged (`ahead=23`, `behind=10` vs `origin/issue1-complete`); top commit: `feat: stabilize manifest and diagnostic contracts`.
- [x] Retained: `worktrees/domainprocessschema-mbt-issue2-wasm` (`issue2-moonbit-wasm`) is clean but unmerged (`ahead=3`, `behind=11` vs `origin/issue1-complete`); top commit: `feat: add interactive wasm transition demo`.
- [x] Retained: `worktrees/domainprocessschema.mbt-app-server-schema-runtime-session-r6-20260510` (`codex/app-server-schema-runtime-session-r6`) is clean but unmerged (`ahead=67`, `behind=10` vs `origin/issue1-complete`); top commit: `docs: clarify app server session tool shapes`.
- [x] Retained: `worktrees/domainprocessschema.mbt-audit-event-manifest-r2-20260509` (`codex/audit-event-manifest-r2`) is clean but unmerged (`ahead=40`, `behind=10` vs `origin/issue1-complete`); top commit: `Define audit event manifest`.
- [x] Retained: `worktrees/domainprocessschema.mbt-basic-plan-r6-20260510` (`codex/basic-plan-r6`) is clean but unmerged (`ahead=68`, `behind=10` vs `origin/issue1-complete`); top commit: `Merge pull request #35 from f4ah6o/codex/app-server-schema-runtime-session-r6`.
- [x] Retained: `worktrees/domainprocessschema.mbt-expression-language-v1-r5-20260510` (`codex/expression-language-v1-r5`) is clean but unmerged (`ahead=64`, `behind=10` vs `origin/issue1-complete`); top commit: `fix: use invalid expr code for empty rules`.
- [x] Retained: `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r4-20260510` (`codex/generated-artifact-goldens-r4`) is clean but unmerged (`ahead=56`, `behind=10` vs `origin/issue1-complete`); top commit: `test: freeze generated artifact goldens`.
- [x] Retained: `worktrees/domainprocessschema.mbt-manifest-envelope-r4-20260510` (`codex/manifest-envelope-r4`) is clean but unmerged (`ahead=51`, `behind=10` vs `origin/issue1-complete`); top commit: `Close manifest envelope issue`.
- [x] Retained: `worktrees/domainprocessschema.mbt-normalized-schema-output-r5-20260510` (`codex/normalized-schema-output-r5`) is clean but unmerged (`ahead=58`, `behind=10` vs `origin/issue1-complete`); top commit: `docs: close normalized schema output issue`.
- [x] Retained: `worktrees/domainprocessschema.mbt-package-metadata-refresh-r4-20260510` (`codex/package-metadata-refresh-r4`) is clean but unmerged (`ahead=45`, `behind=10` vs `origin/issue1-complete`); top commit: `Refresh package metadata`.
- [x] Retained: `worktrees/domainprocessschema.mbt-reference-lookup-contract-r2-20260509` (`codex/reference-lookup-contract-r2`) is clean but unmerged (`ahead=38`, `behind=10` vs `origin/issue1-complete`); top commit: `Define reference lookup contract`.
- [x] Retained: `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r3-20260510` (`codex/runtime-adapter-boundary-r3`) is clean but unmerged (`ahead=43`, `behind=10` vs `origin/issue1-complete`); top commit: `Address runtime adapter review`.
- [x] Retained: `worktrees/domainprocessschema.mbt-schema-contract-v1-r4-20260510` (`codex/schema-contract-v1-r4`) is clean but unmerged (`ahead=49`, `behind=10` vs `origin/issue1-complete`); top commit: `Close schema contract v1 issue`.
- [x] Retained: `worktrees/domainprocessschema.mbt-schema-editor-production-app-20260512` (`codex/schema-editor-production-app`) is clean but unmerged (`ahead=1`, `behind=2` vs `origin/issue1-complete`); top commit: `Add Cloudflare schema editor app`.
- [x] Retained: `worktrees/domainprocessschema.mbt-structured-diagnostics-r4-20260510` (`codex/structured-diagnostics-r4`) is clean but unmerged (`ahead=54`, `behind=10` vs `origin/issue1-complete`); top commit: `Include full diagnostics in session JSON`.
- [x] Retained: `worktrees/domainprocessschema.mbt-transition-semantics-v1-r5-20260510` (`codex/transition-semantics-v1-r5`) is clean but unmerged (`ahead=61`, `behind=10` vs `origin/issue1-complete`); top commit: `docs: fix transition semantics mapping`.
- [x] Retained: `worktrees/domainprocessschema.mbt-versioned-contract-roadmap-r4-20260510` (`codex/versioned-contract-roadmap-r4`) is clean but unmerged (`ahead=47`, `behind=10` vs `origin/issue1-complete`); top commit: `Document versioned contract roadmap`.
- [x] Retained: `worktrees/mhx.mbt-runtime-npm-boundaries-20260511` (`codex/runtime-npm-boundaries`) is clean but unmerged (`ahead=1`, `behind=0` vs `origin/main`); top commit: `Clarify runtime and npm boundaries`.
- [x] Retained: `worktrees/orbit.mbt-fs-agent-permissions-20260509-cc` (`cc/fs-agent-permissions`) is clean but unmerged (`ahead=3`, `behind=18` vs `origin/main`); top commit: `docs(issues): complete fs-agent permissions closure`.
- [x] Retained: `worktrees/orbit.mbt-multi-agent-orchestration-20260509-cc` (`cc/multi-agent-orchestration`) is clean but unmerged (`ahead=1`, `behind=18` vs `origin/main`); top commit: `feat(examples): add multi-agent orchestration demo (M-demo-4)`.
- [x] Retained: `worktrees/orbit.mbt-replay-debugger-20260509-cc` (`cc/replay-debugger`) is clean but unmerged (`ahead=1`, `behind=18` vs `origin/main`); top commit: `feat(examples): add replay-debugger demo (M-demo-6)`.
- [x] Retained: `worktrees/orbit.mbt-streaming-chat-ui-20260509-cc` (`cc/streaming-chat-ui`) is clean but unmerged (`ahead=2`, `behind=18` vs `origin/main`); top commit: `docs(issues): close streaming-chat-ui demo issue`.
- [x] Retained: `worktrees/vizprocess.mbt-practical-cloudflare-app-20260512` (`codex/practical-cloudflare-app`) is clean but unmerged (`ahead=1`, `behind=0` vs `origin/main`); top commit: `Build practical Cloudflare preview app`.

## Default or detached worktrees

These were retained because the branch was the detected default branch or `HEAD`. Inspect whether they are active checkouts, temporary worktrees, or old detached states before deleting.

- [x] Removed: `worktrees/domainprocessschema-mbt-issue1` (`issue1-complete`) was clean and on the detected default branch.
- [x] Removed: `worktrees/papyr-mbt-publish` (`HEAD`) was clean, detached, and already merged into `origin/main`.
- [x] Removed: `worktrees/papyr.mbt-deploy-ci-fix-20260515` (`HEAD`) was clean, detached, and already merged into `origin/main`.
- [x] Removed: `worktrees/vizprocess.mbt-process-workspace-session-store-20260510` (`main`) was clean and on the detected default branch.

## Acceptance criteria

- [x] Each retained worktree is either removed or documented as intentionally retained.
- [x] Dirty worktree changes are committed, stashed, copied into an active task, or explicitly discarded. Remaining dirty work is copied into `issues/2026-05-16T044019Z-resolve-dirty-retained-worktrees.md`.
- [x] Unmerged branches are merged, pushed for review, archived, or explicitly deleted. Remaining unmerged work is copied into `issues/2026-05-16T044019Z-resolve-unmerged-retained-worktrees.md`.
- [x] Remote branches are deleted only after their local branch is safe to remove.
