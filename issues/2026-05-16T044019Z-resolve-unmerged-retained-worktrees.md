# Resolve unmerged retained worktrees

## Background

The retained-worktree cleanup inventory on 2026-05-16 found 24 clean worktrees whose branch HEAD was not an ancestor of the detected default branch. These were intentionally left in place because deleting them could drop unmerged work.

Source issue: `issues/2026-05-16T001657Z-follow-up-retained-worktrees-after-cleanup.md`

## Worktrees

Review each branch, then merge, push for review, archive, or explicitly delete it. Remove the worktree and local branch only after the branch decision is complete.

- [ ] `worktrees/domainprocessschema-mbt-cloudflare-worker` (`chore/cloudflare-worker-deploy`)
  - Status: `ahead=19`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Add Cloudflare Worker deploy tasks for wasm demo`
- [ ] `worktrees/domainprocessschema-mbt-contract-v1-envelope-diagnostics` (`spec/contract-v1-envelope-diagnostics`)
  - Status: `ahead=23`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `feat: stabilize manifest and diagnostic contracts`
- [ ] `worktrees/domainprocessschema-mbt-issue2-wasm` (`issue2-moonbit-wasm`)
  - Status: `ahead=3`, `behind=11` vs `origin/issue1-complete`
  - Top commit: `feat: add interactive wasm transition demo`
- [ ] `worktrees/domainprocessschema.mbt-app-server-schema-runtime-session-r6-20260510` (`codex/app-server-schema-runtime-session-r6`)
  - Status: `ahead=67`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `docs: clarify app server session tool shapes`
- [ ] `worktrees/domainprocessschema.mbt-audit-event-manifest-r2-20260509` (`codex/audit-event-manifest-r2`)
  - Status: `ahead=40`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Define audit event manifest`
- [ ] `worktrees/domainprocessschema.mbt-basic-plan-r6-20260510` (`codex/basic-plan-r6`)
  - Status: `ahead=68`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Merge pull request #35 from f4ah6o/codex/app-server-schema-runtime-session-r6`
- [ ] `worktrees/domainprocessschema.mbt-expression-language-v1-r5-20260510` (`codex/expression-language-v1-r5`)
  - Status: `ahead=64`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `fix: use invalid expr code for empty rules`
- [ ] `worktrees/domainprocessschema.mbt-generated-artifact-goldens-r4-20260510` (`codex/generated-artifact-goldens-r4`)
  - Status: `ahead=56`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `test: freeze generated artifact goldens`
- [ ] `worktrees/domainprocessschema.mbt-manifest-envelope-r4-20260510` (`codex/manifest-envelope-r4`)
  - Status: `ahead=51`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Close manifest envelope issue`
- [ ] `worktrees/domainprocessschema.mbt-normalized-schema-output-r5-20260510` (`codex/normalized-schema-output-r5`)
  - Status: `ahead=58`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `docs: close normalized schema output issue`
- [ ] `worktrees/domainprocessschema.mbt-package-metadata-refresh-r4-20260510` (`codex/package-metadata-refresh-r4`)
  - Status: `ahead=45`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Refresh package metadata`
- [ ] `worktrees/domainprocessschema.mbt-reference-lookup-contract-r2-20260509` (`codex/reference-lookup-contract-r2`)
  - Status: `ahead=38`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Define reference lookup contract`
- [ ] `worktrees/domainprocessschema.mbt-runtime-adapter-boundary-r3-20260510` (`codex/runtime-adapter-boundary-r3`)
  - Status: `ahead=43`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Address runtime adapter review`
- [ ] `worktrees/domainprocessschema.mbt-schema-contract-v1-r4-20260510` (`codex/schema-contract-v1-r4`)
  - Status: `ahead=49`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Close schema contract v1 issue`
- [ ] `worktrees/domainprocessschema.mbt-schema-editor-production-app-20260512` (`codex/schema-editor-production-app`)
  - Status: `ahead=1`, `behind=2` vs `origin/issue1-complete`
  - Top commit: `Add Cloudflare schema editor app`
- [ ] `worktrees/domainprocessschema.mbt-structured-diagnostics-r4-20260510` (`codex/structured-diagnostics-r4`)
  - Status: `ahead=54`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Include full diagnostics in session JSON`
- [ ] `worktrees/domainprocessschema.mbt-transition-semantics-v1-r5-20260510` (`codex/transition-semantics-v1-r5`)
  - Status: `ahead=61`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `docs: fix transition semantics mapping`
- [ ] `worktrees/domainprocessschema.mbt-versioned-contract-roadmap-r4-20260510` (`codex/versioned-contract-roadmap-r4`)
  - Status: `ahead=47`, `behind=10` vs `origin/issue1-complete`
  - Top commit: `Document versioned contract roadmap`
- [ ] `worktrees/mhx.mbt-runtime-npm-boundaries-20260511` (`codex/runtime-npm-boundaries`)
  - Status: `ahead=1`, `behind=0` vs `origin/main`
  - Top commit: `Clarify runtime and npm boundaries`
- [ ] `worktrees/orbit.mbt-fs-agent-permissions-20260509-cc` (`cc/fs-agent-permissions`)
  - Status: `ahead=3`, `behind=18` vs `origin/main`
  - Top commit: `docs(issues): complete fs-agent permissions closure`
- [ ] `worktrees/orbit.mbt-multi-agent-orchestration-20260509-cc` (`cc/multi-agent-orchestration`)
  - Status: `ahead=1`, `behind=18` vs `origin/main`
  - Top commit: `feat(examples): add multi-agent orchestration demo (M-demo-4)`
- [ ] `worktrees/orbit.mbt-replay-debugger-20260509-cc` (`cc/replay-debugger`)
  - Status: `ahead=1`, `behind=18` vs `origin/main`
  - Top commit: `feat(examples): add replay-debugger demo (M-demo-6)`
- [ ] `worktrees/orbit.mbt-streaming-chat-ui-20260509-cc` (`cc/streaming-chat-ui`)
  - Status: `ahead=2`, `behind=18` vs `origin/main`
  - Top commit: `docs(issues): close streaming-chat-ui demo issue`
- [ ] `worktrees/vizprocess.mbt-practical-cloudflare-app-20260512` (`codex/practical-cloudflare-app`)
  - Status: `ahead=1`, `behind=0` vs `origin/main`
  - Top commit: `Build practical Cloudflare preview app`

## Acceptance criteria

- [ ] Every listed branch has an explicit decision: merge, review, archive, or delete.
- [ ] Any branch kept for review is pushed and has a recorded PR or review target.
- [ ] Deleted worktrees are removed through `git worktree remove` from the owning repo.
- [ ] Local and remote branches are deleted only after the branch decision is complete.
