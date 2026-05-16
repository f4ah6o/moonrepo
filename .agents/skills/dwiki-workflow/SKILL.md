---
name: dwiki-workflow
description: Use the dwiki CLI for low-token repository overview, architecture lookup, topic discovery, and targeted codebase investigation before falling back to local file reads.
---

# dwiki Workflow

## When To Use

Use this skill when a task benefits from a quick, low-token overview of a
GitHub repository:

- understanding an unfamiliar repository
- finding architecture or module boundaries
- locating likely files before opening the local clone
- asking a focused question about repository behavior
- searching repo documentation or indexed source summaries

Use `dwiki` as orientation only. Verify important facts against local files
before editing code, writing issue conclusions, or claiming behavior.

## Preconditions

- Run from any workspace with shell access.
- `dwiki` is installed and available on `PATH`.
- The target repository can be named as `<owner>/<repo>`.

Check availability first:

```bash
command -v dwiki
```

If `dwiki` is missing, say so briefly and continue with normal exploration
using `rg`, local files, GitHub, or other repo tools.

## Low-Token Workflow

1. Check whether the repository is indexed:

   ```bash
   dwiki check <owner>/<repo> --output json
   ```

   Continue only when the repo is available in `dwiki`.

2. List available top-level topics:

   ```bash
   dwiki read <owner>/<repo> --output json | jq -r .result
   ```

3. Read only the relevant topic:

   ```bash
   dwiki read <owner>/<repo> <topic> --output json | jq -r .result
   ```

4. Ask focused questions when topic pages are too broad:

   ```bash
   dwiki ask <owner>/<repo> "Where is request routing implemented?" --output json | jq -r .result
   ```

5. Search for symbols, concepts, or file names:

   ```bash
   dwiki search <owner>/<repo> "SessionStore" --output json | jq -r .result
   ```

## Token Rules

- Prefer `--output json | jq -r .result` so the model sees only the useful
  content, not the JSON envelope.
- Start with topics, then read one focused page. Avoid dumping many topics.
- Keep `ask` prompts specific and factual.
- Do not paste large `dwiki` output into final answers; summarize and cite local
  files after verification.

## Failure Handling

- Missing command: continue with normal local exploration.
- Repo not indexed: fall back to local clone, GitHub, or `rg`.
- Ambiguous output: use `dwiki` to choose candidate files, then inspect those
  files directly.
