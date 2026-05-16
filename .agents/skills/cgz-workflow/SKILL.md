---
name: cgz-workflow
description: Use the installed cgz CLI as a read-only development aid for code exploration, impact checks, context gathering, and affected-test selection without making moonrepo manage the codegraph repository.
---

# cgz Workflow

## When To Use

Use this skill when a task may benefit from CodeGraph's local index:

- exploring an unfamiliar code area
- finding symbols or indexed files
- gathering compact implementation context before planning
- checking likely affected test files from changed files
- validating whether a project already has `.codegraph/`

This skill treats `cgz` as an installed CLI. The `codegraph` repository is not a
moonrepo target and should not be added to `repository.ini` for this workflow.

## Preconditions

- Run from any workspace that has access to the target project path.
- `cgz` is installed and available on `PATH`.
- Target projects may or may not already have `.codegraph/`.

Check the command first:

```bash
command -v cgz
```

## Read-Only Workflow

1. Check index state before relying on CodeGraph:

   ```bash
   cgz status <path>
   ```

2. If the project is not initialized, ask before indexing or recommend the
   explicit command:

   ```bash
   cgz init -i <path>
   ```

3. Use focused read commands while planning:

   ```bash
   cgz files --path <path>
   cgz query --path <path> <symbol-or-term>
   cgz context --path <path> <task>
   cgz affected --path <path> <changed-files...>
   ```

4. Treat `cgz` output as navigation help, not final proof. Run the target
   repository's normal checks and tests before claiming the task is verified.

## moonrepo Helpers

moonrepo exposes thin wrappers for read-only usage:

```bash
just cgz-status <path>
just cgz-context <path> <task>
just cgz-affected <path> <files...>
```

These helpers never run `cgz init`, `cgz index`, or any command that creates or
updates `.codegraph/`.

## Change Requests For cgz

Record `cgz` product changes in the `codegraph` repository's local `issues/`
directory. GitHub Issues are disabled for `f4ah6o/codegraph`, so use the local
markdown issue convention from the `issues-migrate` skill:

```text
issues/YYYY-MM-DDThhmmss-spec-short-title.md
```

Include the reason, expected behavior, and any command examples needed to make
the request actionable.
