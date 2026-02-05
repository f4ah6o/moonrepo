---
description: strongly inspired https://github.com/tokuhirom/sabos/blob/main/CLAUDE.md
---

# Development Guide

## Build & Run

@../justfile

## Git Workflow

- Commit and push to the main branch frequently. Do not use PRs or branch-based workflows.
- Commit often and keep the state functional.
- Commit every time a single task (feature addition/fix) is completed. Do not commit multiple tasks at once.

## Development Principles

- Write a development diary in docs/YYYY-MM-DD.md. Record what you did that day, what you learned, and include screenshots.
- Never break a feature once it's built. Always ensure check/test/build success.
- Write plenty of comments. Since this is a learning project, leave detailed comments so that you can understand "why" and "what" you are doing when you read it later.
- When new technical terms appear, naturally explain their meaning within the diary text. Do not separate them into a glossary; write "this means X" within the flow of the text. This prevents "What was this again?" when re-reading.

## Daily Workflow

- Write the plan for the day in `docs/YYYY-MM-DD.md` at the start of the day and proceed according to that plan(in Japanese).
- For each task, write out a specific implementation plan (files to change, content of changes) before starting.
- Break tasks into small pieces. If they are too large, you'll enter "planning mode" and lose context.

## CI/CD

@../justfile

```bash
just check
just test
just build
```
