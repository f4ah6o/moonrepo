# moonrepo

MoonBit / Rust の dependency を複数リポジトリに対して一括で更新・運用するための管理リポジトリです。
モノレポではありません。

## 目的

- 複数の非 monorepo なリポジトリをまとめて clone / update
- `moon-dst` を使って依存更新を一括で実行
- `moon fmt/check/build/clean/test` を turbo 風に一括実行

## 前提

- `gh`（GitHub CLI, `gh skill` 拡張を含む）
- `git-wt`
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

git worktree / bare repo layout の参考:

- <https://zenn.dev/maruloop/articles/acdd949906a4d7>
- <https://github.com/k1LoW/git-wt>

## Codex 実装フロー

`target-repos/<repo>.git/.wt/main` は default branch の baseline checkout として固定します。この worktree で branch を切ったり tracked file を変更したりせず、実装変更は `just codex-start <repo> <task-slug>` または `just target-task-start <repo> <task-slug>` を入口にして専用 worktree へ切り出します。

- 親 thread は moonrepo 側に残って orchestration だけを行う
- 実装変更は対象 worktree を所有する Codex worker sub agent に寄せる
- 親 thread は最後に review / verification / push / draft PR 作成を担当する

`just codex-start` は `.wt/main` が default branch で clean、upstream が `origin/<default-branch>`、local ahead なしであることを確認し、`target-repos/<repo>.git/.wt/codex/<task-slug>/` と `codex/<task-slug>` branch、`.codex/tasks/<repo>-<task-slug>.json` manifest を作ります。完了後に worker 起動用の Codex prompt を出力します。

Codex worker を使わない手作業や recipe 用の worktree は、次で作ります。

```sh
just target-task-start <repo> <task-slug>
just target-main-check <repo>
just target-main-check-all
```

状態確認と PR 作成:

```sh
just codex-status <repo> <task-slug>
just codex-pr <repo> <task-slug>
```

`just codex-pr` は worktree の clean 状態、upstream、`gh` 認証、base branch の required checks を確認し、通過時だけ draft PR を作成します。

ドキュメント専用の review では、repo local skill `docs-humanizer` を使います。Zenn の anti-AI-writing 記事をもとに、日本語の repository docs 向けチェックリストと audit script を入れています。

## 使い方

1. `repository.ini` を初期生成

GitHub topic で対象 repo を絞り込みます（OR 条件）。初期状態は全てコメントアウトしています。
```sh
just init <owner> --topics moonbit rust
```

`--topics` 未指定時は `moonbit rust` が使われます。

2. `repository.ini` の `[repositories]` で `#` / `;` コメントを外して、今回 clone / 一括運用したい対象だけを有効化

`[rally.teams]` には、関連の強い target repo 群を ral team として定義できます。通常の clone / pull / deps 系 recipe は `[repositories]` だけを対象にします。

```ini
[repositories]
f4ah6o/papyr.mbt
f4ah6o/papyr-docs.mbt
f4ah6o/blog.mbt

[rally.teams]
papyr = papyr.mbt, papyr-docs.mbt, blog.mbt
```

3. clone（初回）

```sh
just clone
```

`just clone` は各リポジトリを bare clone (`target-repos/<name>.git/`) として取得し、その既定ブランチ（`origin/HEAD`）を `target-repos/<name>.git/.wt/main/` に `git worktree add` します。bare repo には `wt.basedir=.wt` を設定します。`.wt/main` は baseline として固定し、複数ブランチで並行作業したい場合は `just codex-start` または `just target-task-start` から追加 worktree を生やしてください。レイアウト変更時は `just --set FORCE 1 cclone` で作り直してください。

4. pull（既存リポジトリの更新）

```sh
just pull
```

一括系 recipe は既定で `repository.ini` の有効行だけを対象にします。`target-repos/` にある全 `.wt/main` worktree を対象にしたい場合は `REPO_SCOPE=cloned` を明示します。

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

7. 対象 repo の実装作業を始める場合

```sh
just codex-start <repo> <task-slug>
```

出力された prompt に従って worker を起動し、実装は作成済み worktree で進めます。親 thread は `just codex-status` で状態を見て、最後に `just codex-pr` で draft PR を開きます。

8. 対象 repo の document を監査・改善する場合

```sh
just docs-audit <repo>
just docs-review <repo> <task-slug>
```

`just docs-audit` は tracked documents を対象に、AI っぽい文体の機械検査を行います。`just docs-review` は `codex-start` で専用 worktree を作り、その worktree に対して `docs-humanizer` skill と audit の手順を出力します。

9. `cgz` を開発補助に使う場合

`cgz` はインストール済み CLI として扱います。moonrepo は `codegraph` リポジトリを clone 対象として管理しません。

```sh
just cgz-status <path>
just cgz-context <path> <task>
just cgz-affected <path> <files...>
```

これらは read-only helper です。`.codegraph/` の初期化や更新が必要な場合は、対象 repo で明示的に `cgz init -i <path>` や `cgz index <path>` を実行してください。

10. `dwiki` で repo 概要を低トークンに調べる場合

repo local skill `dwiki-workflow` を使います。`dwiki` は任意のインストール済み CLI として扱い、moonrepo の必須コマンドには含めません。

```sh
command -v dwiki
dwiki check <owner>/<repo> --output json
dwiki read <owner>/<repo> --output json | jq -r .result
dwiki ask <owner>/<repo> "Where is request routing implemented?" --output json | jq -r .result
dwiki search <owner>/<repo> "SessionStore" --output json | jq -r .result
```

`dwiki` の結果は概要把握と候補ファイル探しに使います。実装変更や調査結論は、対象 repo の local file を読んで確認してください。

11. `ral` で agent 間の短い連絡を扱う場合

`ral` は任意の helper です。moonrepo の task state は `.codex/tasks/*.json`、git、GitHub を正とし、`ral` は親 thread、Codex worker、Claude Code、OpenCode reviewer の短い依頼や完了通知にだけ使います。

現時点では `ral skills` が crates.io の `2026.5.0` には入っていないため、`just rally-install` は `f4ah6o/rally-rs` の確認済み revision を指定して install します。
`just rally-install` は `cargo` を使います。
`ral install` は `~/.agents/skills/ral/` に skill、wrapper、SQLite DB、team 設定を作り、Codex 用の writable roots を `~/.codex/config.toml` に追記します。

```sh
just rally-install
just rally-status
just rally-skills
just rally-join <team> <agent>
just rally-whoami
just rally-inbox <team> <agent>
just rally-send <team> <from> <to> "<message>"
just rally-history <team>
just rally-team <team>
just rally-mode turn
```

Codex では `turn` mode を使います。team 名は `repo-task-slug` のように、対象 repo と作業内容が分かる名前にします。

関連 repo group を team として扱う場合は、`repository.ini` の `[rally.teams]` を使います。team 名は `repo-group-<group>`、agent 名は repo basename、親 thread は `moonrepo` です。changelog は `docs/rally/<group>/` に markdown として残し、`ral` が使える場合だけ短い通知も送ります。

```sh
just rally-groups
just rally-group papyr
just rally-group-validate
just rally-group-join papyr
just rally-group-send papyr moonrepo all "papyr content bridge follow-up"
just rally-changelog papyr papyr.mbt content-bridge "content bridge downstream follow-up"
```

## よく使うコマンド

- 前提と対象状態の確認
  - `just doctor`
- 余剰 clone の確認 / 削除
  - `just target-repos-prune`
  - `just target-repos-prune --apply`
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
- `target-repos/` を全削除して作り直す
  - `just --set FORCE 1 clean`
  - `just --set FORCE 1 cclone`
- failed workflow の rerun（dry-run 既定）
  - `just gh-runs-rerun-failed-all`
  - `just gh-runs-rerun-failed-all --apply`
- 単一 repo の refactoring 準備（moonbit-refactoring skill を使う）
  - `just refactor <repo>`
  - 対象 repo の clean 状態、moon モジュール認識、skill インストール済みを検証し、ブランチ作成と skill 起動の手順を出力します。
  - 将来的には `just codex-start <repo> <task-slug>` ベースの入口へ寄せる前提ですが、現状は MoonBit refactoring 専用の軽量フローとして残します。
- document audit / improvement
  - `just docs-audit <repo>`
  - `just docs-audit-all`
  - `just docs-review <repo> <task-slug>`
  - audit は tracked `.md` / `.mdx` / `.txt` / `.rst` / `.adoc` を対象に、機械検査で拾える AI っぽいパターンを報告します。改善時は repo local skill `docs-humanizer` を使います。
- `cgz` development helper
  - `just cgz-status <path>`
  - `just cgz-context <path> <task>`
  - `just cgz-affected <path> <files...>`
  - repo local skill `cgz-workflow` を使い、インストール済み `cgz` CLI を read-only な探索・影響確認に使います。
- `dwiki` overview helper
  - repo local skill `dwiki-workflow` を使い、`dwiki check/read/ask/search` で概要や候補ファイルを低トークンに調べます。
  - `dwiki` は任意コマンドなので、未インストール時は通常の local file 探索に戻ります。
- `ral` agent messaging helper
  - `just rally-install`
  - `just rally-status`
  - `just rally-skills`
  - `just rally-join <team> <agent>`
  - `just rally-whoami`
  - `just rally-inbox <team> <agent>`
  - `just rally-send <team> <from> <to> "<message>"`
  - `just rally-history <team>`
  - `just rally-team <team>`
  - `just rally-mode turn`
  - `just rally-groups`
  - `just rally-group <group>`
  - `just rally-group-validate`
  - `just rally-group-join <group>`
  - `just rally-group-inbox <group> <agent>`
  - `just rally-group-send <group> <from> <to|all> "<message>"`
  - `just rally-changelog <group> <source-repo> <slug> "<summary>"`
  - `ral` は任意コマンドです。`just doctor` の必須前提には含めません。

## 詳細

運用フローは `AGENTS.md` を参照してください。
