# moonrepo

MoonBit / Rust の dependency を複数リポジトリに対して一括で更新・運用するための管理リポジトリです。
モノレポではありません。

## 目的

- 複数の非 monorepo なリポジトリをまとめて clone / update
- `moon-dst` を使って依存更新を一括で実行
- `moon fmt/check/build/clean/test` を turbo 風に一括実行

## 前提

- `gh`（GitHub CLI, `gh skill` 拡張を含む）
- `just`
- `moon` / `moon-dst`
- `jq`
  - [moon-dst](https://github.com/f4ah6o/moon-dst-rs)
  - `cargo install moon-dst`

## 初期セットアップ

skill を明示的に初期化する場合:

```sh
just skills-init
```

`moonbit-agent-guide` と `moonbit-refactoring` を [moonbitlang/moonbit-agent-guide](https://github.com/moonbitlang/moonbit-agent-guide) から codex の user scope (`~/.codex/skills/`) に `gh skill install` します。

関連する skill marketplace:

- <https://github.com/moonbitlang/skills>
- <https://github.com/moonbitlang/moonbit-agent-guide>

## Codex 実装フロー

`repos/<repo>` 配下の実装変更は、親 thread が直接その clone を触るのではなく、`just codex-start <repo> <task-slug>` を入口にして専用 worktree へ切り出す運用を標準にします。

- 親 thread は moonrepo 側に残って orchestration だけを行う
- 実装変更は対象 worktree を所有する Codex worker sub agent に寄せる
- 親 thread は最後に review / verification / push / draft PR 作成を担当する

`just codex-start` は clone の clean 状態と upstream を確認し、`worktrees/<repo>-<task-slug>-<YYYYMMDD>/` と `codex/<task-slug>` branch、`.codex/tasks/<repo>-<task-slug>.json` manifest を作ります。完了後に worker 起動用の Codex prompt を出力します。

状態確認と PR 作成:

```sh
just codex-status <repo> <task-slug>
just codex-pr <repo> <task-slug>
```

`just codex-pr` は worktree の clean 状態、upstream、`gh` 認証、base branch の required checks を確認し、通過時だけ draft PR を作成します。

## 使い方

1. `repository.ini` を初期生成

GitHub topic で対象 repo を絞り込みます（OR 条件）。初期状態は全てコメントアウトしています。
```sh
just init <owner> --topics moonbit rust
```

`--topics` 未指定時は `moonbit rust` が使われます。

2. `repository.ini` の `#` / `;` コメントを外して有効化

3. clone（初回）

```sh
just clone
```

`just clone` は各リポジトリを bare clone (`repos/<name>.git/`) として取得し、その既定ブランチ（`origin/HEAD`）を `repos/<name>/` に `git worktree add` します。`repos/<name>/.git` はディレクトリではなく gitlink ファイルになります。複数ブランチで並行作業したい場合は、bare 側から追加 worktree を生やしてください（例: `git -C repos/<name>.git worktree add ../<name>-feat feat-branch`）。レイアウト変更時は `just --set FORCE 1 cclone` で作り直してください。

4. pull（既存リポジトリの更新）

```sh
just pull
```

一括系 recipe は既定で `repository.ini` の有効行だけを対象にします。`repos/` にある全 clone を対象にしたい場合は `REPO_SCOPE=cloned` を明示します。

```sh
just --set REPO_SCOPE cloned status-all
```

5. 依存更新

```sh
just deps-apply-all
```

6. topic 運用

既存 `.mbt` 命名ルールで拾える repo に `moonbit` topic を追加する migration（dry-run 既定）:
```sh
just topics-migrate-moonbit
just topics-migrate-moonbit --apply
```

`repository.ini` の有効行に任意 topic を追加（dry-run 既定）:
```sh
just topics-add-from-ini rust
just topics-add-from-ini rust --apply
```

7. `repos/` 配下の実装作業を始める場合

```sh
just codex-start <repo> <task-slug>
```

出力された prompt に従って worker を起動し、実装は作成済み worktree で進めます。親 thread は `just codex-status` で状態を見て、最後に `just codex-pr` で draft PR を開きます。

## よく使うコマンド

- 前提と対象状態の確認
  - `just doctor`
- 余剰 clone の確認 / 削除
  - `just repos-prune`
  - `just repos-prune --apply`
- 依存の一覧
  - `just deps-scan-all`
- 依存更新（dry-run）
  - `just deps-apply-all --dry-run`
- topic migration（dry-run / apply）
  - `just topics-migrate-moonbit`
  - `just topics-migrate-moonbit --apply`
- `repository.ini` 対象に topic を追加（dry-run / apply）
  - `just topics-add-from-ini rust`
  - `just topics-add-from-ini rust --apply`
- f4ah6o の `moonbit` topic 付き repo 全部の moonbit toolchain を一括更新
  - `just moonbit-bump-scan`
  - `just moonbit-bump 0.1.20260215`
  - `just moonbit-bump 0.1.20260215 --apply`
  - `.tool-versions` と `.github/workflows/*.yml` の install 行のみを更新します。`moonbitlang/*` deps の更新は `just deps-apply-all` を別途実行してください。
- justfile 追加
  - `just deps-just-all`
- moon 一括
  - `just moon-fmt-all`
  - `just moon-check-all`
  - `just moon-build-all`
  - `just moon-clean-all`
  - `just moon-test-all`
- 全 clone を対象にしたい場合
  - `just --set REPO_SCOPE cloned <recipe>`
- `repos/` を全削除して作り直す
  - `just --set FORCE 1 clean`
  - `just --set FORCE 1 cclone`
- failed workflow の rerun（dry-run 既定）
  - `just gh-runs-rerun-failed-all`
  - `just gh-runs-rerun-failed-all --apply`
- 単一 repo の refactoring 準備（moonbit-refactoring skill を使う）
  - `just refactor <repo>`
  - 対象 repo の clean 状態、moon モジュール認識、skill インストール済みを検証し、ブランチ作成と skill 起動の手順を出力します。
  - 将来的には `just codex-start <repo> <task-slug>` ベースの入口へ寄せる前提ですが、現状は MoonBit refactoring 専用の軽量フローとして残します。

## 詳細

運用フローは `AGENTS.md` を参照してください。
