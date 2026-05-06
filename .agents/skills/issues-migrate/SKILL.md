---
name: issues-migrate
description: Migrate GitHub Issues to a local issues/ directory in repos/<repo> following the shiguredo/http3-rs convention (timestamp-based naming). Use when migrating issues from GitHub to local markdown files.
---

# Issues Migrate

## When To Use

Use this skill when you want to migrate GitHub Issues into a local `issues/` directory under a target repo:

- Pull open/closed issues from GitHub via `gh issue list` / `gh issue view`
- Convert each issue to a markdown file in `issues/` (open) or `issues/closed/` (closed)
- Follow naming convention: `{YYYY-MM-DDThhmmss}-{category}-{slug}.md`
- Update `AGENTS.md` / `CLAUDE.md` with issues workflow documentation
- Update `README.md` with reference to shiguredo/http3-rs
- Close the migrated issues on GitHub (with a migration comment)

This skill is designed for `moonrepo` layout and expects a target path like `repos/mhx.mbt`.

## Preconditions

- Run from the `moonrepo` workspace.
- Target repo exists at `repos/<repo_name>` and has a `.git` directory.
- `gh` CLI is authenticated and available.
- Commands available: `bash`, `gh`, `jq`.

## Primary Command

```bash
bash .agents/skills/issues-migrate/scripts/migrate-issues.sh <repo_name>
```

Example:

```bash
bash .agents/skills/issues-migrate/scripts/migrate-issues.sh mhx.mbt
```

## Options

- `--dry-run`: show planned changes without writing files or closing issues.
- `--force`: overwrite existing issue files.
- `--skip-agents`: skip updating AGENTS.md/CLAUDE.md.
- `--skip-readme`: skip updating README.md.
- `--skip-close`: skip closing issues on GitHub (only create local files).
- `-h`, `--help`: print usage.

## Default Behavior

- Open issues → `issues/<file>.md`
- Closed issues → `issues/closed/<file>.md`
- Creates `issues/`, `issues/closed/`, `issues/pending/` directories as needed.
- Skips existing files unless `--force` is given.
- GitHub issues receive a migration comment then are closed.
- Appends issues workflow section to `AGENTS.md` and `CLAUDE.md`.
- Appends issues reference section (with shiguredo/http3-rs link) to `README.md`.

## Naming Convention

```
{YYYY-MM-DDThhmmss}-{category}-{slug}.md
```

- `timestamp`: ISO 8601 from `createdAt` (colon-free for filesystem safety)
- `category`: inferred from GitHub labels: `bug` → `bug`, `enhancement` → `enhance`, `documentation` → `docs`, default → `spec`
- `slug`: title, lowercased, hyphen-separated, max 50 chars

## Artifacts

- `references/agents-issues-section.md`: template for AGENTS.md/CLAUDE.md issues workflow section.
- `references/readme-issues-section.md`: template for README.md issue management section (with shiguredo/http3-rs link).

## Validate After Apply

```bash
cd repos/<repo_name>
ls issues/
ls issues/closed/
git status
```

Expected: `issues/` contains markdown files for open issues, `issues/closed/` contains closed issues, AGENTS.md / README.md are updated.

## Reference

This issue management approach is inspired by [shiguredo/http3-rs](https://github.com/shiguredo/http3-rs/blob/develop/AGENTS.md).
