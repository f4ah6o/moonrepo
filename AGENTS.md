## 概要

moonbit / rust リポジトリ群の依存更新・一括運用を行う管理リポジトリ。  
monorepo ではありません。

## Development Guide (MUST READ)

- 作業前に必ず `docs/DEVELOPMENT_GUIDE.md` を読むこと。

## 事前準備

- 必須コマンド
  - `gh`（`gh skill` 拡張を含む。skill 管理に使う）
  - `git-wt`
  - `just`
  - `moon`
  - `moon-dst`
  - `jq`
- skill の初期化は明示的に行う
  - `just skills-init`
- 参照する skill marketplace
  - <https://github.com/moonbitlang/skills>
  - <https://github.com/moonbitlang/moonbit-agent-guide>
- 手動インストールする場合（codex 用）
  - `gh skill install moonbitlang/moonbit-agent-guide moonbit-agent-guide --agent codex --scope user`
  - `gh skill install moonbitlang/moonbit-agent-guide moonbit-refactoring --agent codex --scope user`
- 任意 helper
  - `ral`（agent 間の短い連絡用。必要な場合だけ `cargo` 付きの環境で `just rally-install` する）

## しないこと

- monorepo 化しない

## moonrepo 本体の作業

- `/Users/fu2hito/src/moonrepo` 自体の変更は、この checkout で直接行う。
- 作業前に `docs/DEVELOPMENT_GUIDE.md` を読み、`docs/YYYY-MM-DD.md` に日本語で当日の計画と、変更対象ファイル・変更内容の実装計画を書く。
- 既存の dirty worktree は利用者または別作業の変更として扱い、今回の作業に不要なら触らない。必要な場合も内容を確認してから共存させる。
- moonrepo 本体の変更には、target repo 用の `just codex-start <repo> <task-slug>`、`just docs-review <repo> <task-slug>`、`target-repos/<repo>.git/.wt/codex/` worktree を使わない。
- 検証は変更範囲に合わせる。ドキュメントだけなら差分確認を基本にし、コードや recipe を触った場合は `just check` / `just test` / `just build` など該当する確認を行う。

## Release Rule

- `target-repos/aci-rs.git/.wt/main` のバージョンは CalVer `YYYY.M.Patch` を使う（例: `2026.3.0`）。
- `target-repos/aci-rs.git/.wt/main` の release tag は `v<version>` 形式（例: `v2026.3.0`）。

## 標準ワークフロー

1. `just init <owner> --topics moonbit rust` で `repository.ini` を初期生成
2. `--topics` 未指定時は `moonbit rust` が使われる
3. `repository.ini` の `[repositories]` に、今回 clone / 一括運用する `<owner>/<repo>` を1行ずつ記載（空行と `#` / `;` 行は無視）
   - section なしの既存 `<owner>/<repo>` 行も後方互換として active repo 扱いにする
   - `[rally.teams]` は関連 repo group 用で、clone / pull / deps 系 recipe の対象にはしない
4. `just clone` で `./target-repos/<repo>.git` に bare clone し、`./target-repos/<repo>.git/.wt/main` を作る
   - `.wt/main` は default branch の baseline checkout として固定する
   - `.wt/main` で branch を切ったり tracked file を変更したりしない
   - 作業ごとの変更は `just codex-start <repo> <task-slug>` または `just target-task-start <repo> <task-slug>` で `.wt/` 配下の専用 worktree を作って行う
5. `just doctor` で前提コマンド・`repository.ini`・clone 状態を確認
6. `just pull` で既存 active repo を更新
   - 全 clone を対象にしたい場合だけ `just --set REPO_SCOPE cloned pull`
7. 余剰 target repo の整理が必要なら `just target-repos-prune` / `just target-repos-prune --apply`
8. topic migration
   - `just topics-migrate-moonbit`
   - `just topics-migrate-moonbit --apply`
9. `repository.ini` 対象への topic 追加
   - `just topics-add-from-ini <topic>`
   - `just topics-add-from-ini <topic> --apply`
10. 依存の確認と適用
   - `just deps-scan-all`
   - `just deps-apply-all`
   - 個別: `just deps-scan <repo>` / `just deps-apply <repo> <task-slug>`
11. `moon-dst just` 相当
   - `just deps-just-all`
   - `just deps-just <repo> <task-slug>`
12. moonbit toolchain 本体の一括更新（`repository.ini` 非依存。`f4ah6o` + `moonbit` topic の全 repo が対象）
   - `just moonbit-bump-scan`
   - `just moonbit-bump <version>`
   - `just moonbit-bump <version> --apply`
   - `.tool-versions` と `.github/workflows/*.yml` の `cli.moonbitlang.com/install/unix.sh` 行だけを更新する
   - `moonbitlang/*` deps は対象外（`just deps-apply-all` を別途実行）
   - 未 clone の repo は warn のみでスキップ（自動 clone はしない）
13. GitHub Issues のローカル移行（`issues-migrate` skill 経由）
   - `just issues-migrate <repo> <task-slug>` で専用 worktree を作り、GitHub Issues を `issues/` に移行
   - `just issues-migrate-all` で全 active repo を一括移行
   - `--force` で既存ファイル上書き、`--dry-run` で確認のみ
   - 移行後 GitHub 側の issue にコメント付与 → close
   - AGENTS.md/CLAUDE.md に issues ワークフローセクションが追記される
   - README.md に shiguredo/http3-rs への参考元リンクが追記される
14. MoonBit repo の refactoring（`moonbit-refactoring` skill 経由）
   - 前提: `just skills-init` 済みで対象 repo が clean
   - `just refactor <repo>` で環境検証と次手順の出力
   - 出力に従って `refactor/<date>` ブランチを切り、codex/claude で skill を起動
   - skill が指示する順序（architecture -> API 棚卸し -> 最小差分 -> tests/docs -> `moon check`/`moon test`）で進める
15. MoonBit repo の opencode review loop
   - MoonBit target repo の実装・レビューで `opencode-review-loop` を使う場合は、必ず `moonbit-agent-guide` を併用する
   - MoonBit API、package 構造、refactor、公開面の整理を含む場合は `moonbit-refactoring` も併用する
   - opencode の implement / review prompt には「MoonBit 関連 skill を使うこと」と、対象 worktree の unrelated changes を戻さないことを明記する
   - review は `opencode-review-loop` の guard script を使い、actionable findings への対応と検証を繰り返し、exact `LGTM` まで回す
   - 検証は変更範囲に応じて `moon check`、`moon test`、必要なら `moon info` / `moon test --target all` を使う
16. Document の監査・改善（`docs-humanizer` skill 経由）
   - `just docs-audit <repo>` で tracked documents を機械監査する
   - `just docs-audit-all` で全 active repo を一括監査する
   - `just docs-review <repo> <task-slug>` で codex worktree を作り、`docs-humanizer` skill を使う worker 向け手順を出力する
   - 対象は `README*`, `AGENTS.md`, `CLAUDE.md`, `docs/**/*.md`, `issues/**/*.md` を含む tracked `.md` / `.mdx` / `.txt` / `.rst` / `.adoc`
   - audit は機械検査で拾える AI っぽい文体だけを報告する。最終判断は skill のチェックリストに沿って行う
17. `cgz` を開発補助に使う（`cgz-workflow` skill 経由）
   - `cgz` はインストール済み CLI として扱う。moonrepo は `codegraph` repo を clone 対象として管理しない
   - read-only helper: `just cgz-status <path>` / `just cgz-context <path> <task>` / `just cgz-affected <path> <files...>`
   - helper は `.codegraph/` を初期化・更新しない。必要な場合だけ対象 repo で明示的に `cgz init -i <path>` / `cgz index <path>` を実行する
   - `cgz` の変更希望は `../codegraph/issues/` にローカル issue として作成する
18. `dwiki` で低トークンな repo 概要調査を行う（`dwiki-workflow` skill 経由）
   - `dwiki` は任意のインストール済み CLI として扱う。`just doctor` の必須前提には含めない
   - 使う前に `command -v dwiki` と `dwiki check <owner>/<repo> --output json` で利用可否を確認する
   - `dwiki read/ask/search ... --output json | jq -r .result` で必要部分だけ読む
   - `dwiki` の出力は調査の入口として扱い、実装や結論の前に local file で確認する
19. `ral` で agent 間の短い連絡を行う
   - `ral` は任意 helper として扱う。`just doctor` の必須前提には含めない
   - `just rally-install` は `ral skills` を含む `github.com/f4ah6o/rally-rs` の確認済み revision を install する
   - `ral install` は `~/.agents/skills/ral/` と `~/.codex/config.toml` を更新する
   - `just rally-status` / `just rally-skills` / `just rally-join <team> <agent>` で利用状態と skill 文面を確認する
   - `just rally-inbox <team> <agent>` / `just rally-send <team> <from> <to> "<message>"` で連絡する
   - 関連 repo group は `repository.ini` の `[rally.teams]` に `papyr = papyr.mbt, papyr-docs.mbt, blog.mbt` の形で定義する
   - group team 名は `repo-group-<group>`、agent 名は repo basename、親 thread は `moonrepo`
   - `just rally-groups` / `just rally-group <group>` / `just rally-group-join <group>` / `just rally-group-inbox <group> <agent>` / `just rally-group-send <group> <from> <to|all> "<message>"` を使う
   - 上流追従や downstream 共有の changelog は `just rally-changelog <group> <source-repo> <slug> "<summary>"` で `docs/rally/<group>/` に残し、`ral` が使える場合だけ通知する
   - `ral` は task state の正ではない。task state は `.codex/tasks/*.json`、git、GitHub を正とする

## Codex sub agent 運用

- `target-repos/<repo>.git/.wt/main` は default branch の baseline として固定し、実装変更の作業場にしない
- `target-repos/<repo>.git/.wt/main` 配下の実装変更が必要な場合は `just codex-start <repo> <task-slug>` または `just target-task-start <repo> <task-slug>` を入口にする
- `just codex-start` は `.wt/main` の clean 状態と upstream を確認し、`target-repos/<repo>.git/.wt/codex/<task-slug>/` と `codex/<task-slug>` branch、`.codex/tasks/<repo>-<task-slug>.json` manifest を作る
- 親 thread は moonrepo 側に残り、対象 repo の実装は作成済み worktree を所有する Codex worker sub agent に任せる
- 親 thread の責務は orchestration、最終 review、verification、push、draft PR 作成に限定する
- 状態確認は `just codex-status <repo> <task-slug>`、draft PR 作成は `just codex-pr <repo> <task-slug>` を使う
- 並列 worktree を増やす前や PR 整理前は `just codex-health` で stale manifest、missing worktree、branch / PR 状態ずれ、active task 同士の changed path 重複を確認する
- `AGENTS.md` や skill だけで sub agent 利用を絶対証明することはできない。実効強制は moonrepo の入口 command を通した運用で担保する
- `just refactor <repo>` は MoonBit refactoring 専用の軽量入口として残すが、通常の repo 実装作業は `codex-start` を優先する
- MoonBit repo の worker は `moonbit-agent-guide` を読む。API 整理・package 分割・refactor では `moonbit-refactoring` も読む。`opencode-review-loop` を併用する場合も opencode prompt に同じ skill 指示を含める
- document 改善は `docs-review` を入口にし、worker は moonrepo workspace 上の `docs-humanizer` skill を使って対象 worktree を編集する
- 複数 agent を併用する場合、`ral` は短い依頼・完了通知・ブロッカー共有にだけ使う。実装指示、レビュー結果、PR 状態は manifest と GitHub に残す
- 関連 repo group の changelog は追従メモであり、実装完了や review 判断の正にはしない

## 一括実行コマンド

- turbo 風一括
  - `just moon-fmt-all`
  - `just moon-check-all`
  - `just moon-build-all`
  - `just moon-clean-all`
  - `just moon-test-all`
  - 既定対象は `repository.ini` の active repo
  - 全 clone を対象にしたい場合は `just --set REPO_SCOPE cloned <recipe>`
- 個別 repo
  - `just moon-fmt <repo> <task-slug>`
  - `just moon-check <repo>`
  - `just moon-build <repo>`
  - `just moon-clean <repo>`
  - `just moon-test <repo>`
- 運用補助
  - `just status-all`
  - `just push-all`
  - `just gh-runs-last-all`
  - `just gh-runs-rerun-failed-all`
  - `just rally-groups`
  - `just rally-group <group>`
  - `just rally-group-validate`
  - `just rally-group-join <group>`
  - `just rally-group-inbox <group> <agent>`
  - `just rally-group-send <group> <from> <to|all> "<message>"`
  - `just rally-changelog <group> <source-repo> <slug> "<summary>"`
  - failed workflow の rerun は dry-run 既定
  - `target-repos/` 全削除は `just --set FORCE 1 clean` / `just --set FORCE 1 cclone`
