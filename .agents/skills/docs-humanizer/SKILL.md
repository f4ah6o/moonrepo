---
name: docs-humanizer
description: Review and improve tracked documents in repos/<repo> with a Japanese anti-AI-writing checklist, a mechanical audit pass, and a codex worktree workflow. Use when editing README, AGENTS, CLAUDE, docs/, issues/, specs, or other repository documents managed from moonrepo.
---

# Docs Humanizer

## When To Use

Use this skill when you want to inspect or rewrite documents under `repos/<repo>` so they read like deliberate human-written technical documentation instead of generic LLM output.

Typical targets:

- `README.md`, `README.mbt.md`
- `AGENTS.md`, `CLAUDE.md`
- `docs/**/*.md`
- `issues/**/*.md`
- Any other tracked `.md`, `.mdx`, `.txt`, `.rst`, `.adoc`

## Preconditions

- Run from the `moonrepo` workspace.
- Target repo exists at `repos/<repo_name>` or in a codex-created worktree under `worktrees/`.
- Commands available: `bash`, `git`, `jq`, `rg`.

## Primary Commands

Mechanical audit:

```bash
bash .agents/skills/docs-humanizer/scripts/audit-docs.sh <repo_name>
```

Or audit an explicit worktree path:

```bash
bash .agents/skills/docs-humanizer/scripts/audit-docs.sh --path /abs/path/to/worktree
```

Start the full codex workflow:

```bash
bash .agents/skills/docs-humanizer/scripts/docs-workflow.sh <repo_name> <task-slug>
```

Equivalent `just` entrypoints:

```bash
just docs-audit <repo_name>
just docs-audit-all
just docs-review <repo_name> <task-slug>
```

## Workflow

1. Run the mechanical audit first. Treat the audit as a triage pass, not as the final judge. It only covers patterns that are easy to detect with regex.
2. Prioritize high-signal documents first: `README*`, `AGENTS.md`, `CLAUDE.md`, `docs/`, then issue/spec files.
3. Remove machine-like patterns first:
   - em dash / fullwidth dash
   - inline-heading bullets
   - chatbot residue
   - templated introductions and conclusions
   - excessive hedging and vague sourcing
4. Then do a content pass using `references/anti-ai-checklist-ja.md`.
5. Re-run the audit until remaining matches are either gone or clearly intentional.
6. If you change commands, examples, or process docs, validate the commands against the repository where possible.

## Editing Rules

- Prefer direct statements over inflated significance.
- Prefer simple predicates over roundabout copula-avoidance phrases.
- Keep bullets plain unless the distinction is meaningful enough to deserve a true subsection.
- Delete filler transitions such as repeated `さらに` / `加えて` when the sentence already flows.
- Replace vague claims with concrete facts, file paths, commands, dates, or observed behavior.
- Introduce a small amount of authorial judgment where it clarifies tradeoffs, but do not add fluff.

## Reference

- Read `references/anti-ai-checklist-ja.md` before rewriting.
- The checklist is derived from the Zenn article below and the humanizer projects it references:
  - <https://zenn.dev/m0370/articles/205c9340a418c3>
  - <https://github.com/blader/humanizer>
  - <https://github.com/matsuikentaro1/humanizer_academic>

## Validate After Apply

```bash
bash .agents/skills/docs-humanizer/scripts/audit-docs.sh <repo_name>
git -C repos/<repo_name> diff --stat
```

Expected: obvious mechanical findings are reduced, tracked document diffs stay intentional, and rewritten docs read as specific technical writing rather than generic AI prose.
