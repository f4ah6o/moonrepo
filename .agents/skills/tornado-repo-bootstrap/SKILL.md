---
name: tornado-repo-bootstrap
description: Add a standard tornado development setup to target-repos/<repo>.git/.wt/main in moonrepo by creating tornado.json and adding justfile recipes (just tornado, just tornado-validate) for dev=claude-code via opz z.ai and review=codex.
---

# Tornado Repo Bootstrap

## When To Use

Use this skill when you want to enable the same tornado workflow in a target repository under `target-repos/`:

- add `tornado.json`
- add `just tornado`
- add `just tornado-validate`

This skill is designed for `moonrepo` layout and expects a target path like `target-repos/FWD.mbt.git/.wt/main`.

## Preconditions

- Run from the `moonrepo` workspace.
- Target repo exists at `target-repos/<repo_name>.git/.wt/main`.
- Target repo has a `justfile`.
- Commands available in environment: `bash`, `rg`, `tornado`, `opz`, `just`.

## Primary Command

```bash
bash .agents/skills/tornado-repo-bootstrap/scripts/enable_tornado_repo.sh <repo_name>
```

Example:

```bash
bash .agents/skills/tornado-repo-bootstrap/scripts/enable_tornado_repo.sh FWD.mbt
```

## Options

- `--dry-run`: show planned changes without writing files.
- `--force`: overwrite existing `tornado.json`.
- `--review-model <model>`: set reviewer model in `tornado.json`.
- `--max-review-cycles <n>`: set `max_review_cycles` in `tornado.json`.
- `-h`, `--help`: print usage.

## Default Behavior

- `tornado.json`:
  - create if missing
  - skip if already present
  - overwrite only with `--force`
- `justfile` recipes:
  - append `tornado *args:` only when missing
  - append `tornado-validate:` only when missing
  - never overwrite existing recipes

## Artifacts

- `references/config-template.json`: template for `tornado.json`.
- `references/just-snippet.just`: recipe snippets used by the installer script.

## Validate After Apply

```bash
cd target-repos/<repo_name>.git/.wt/main
just --list
just tornado-validate
```

Expected: both `tornado` and `tornado-validate` are listed, and validation passes.

## Notes

- This skill does not modify global Codex settings (`~/.codex/config.toml`).
- If you need different provider behavior for `codex`, manage it outside this skill.
