## 概要

moonbit / rust リポジトリ群の依存更新・一括運用を行う管理リポジトリ。  
monorepo ではありません。

## Development Guide (MUST READ)

- 作業前に必ず `docs/DEVELOPMENT_GUIDE.md` を読むこと。

## 事前準備

- 必須コマンド
  - `gh`（`gh skill` 拡張を含む。skill 管理に使う）
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

## しないこと

- monorepo 化しない

## Release Rule

- `repos/aci-rs` のバージョンは CalVer `YYYY.M.Patch` を使う（例: `2026.3.0`）。
- `repos/aci-rs` の release tag は `v<version>` 形式（例: `v2026.3.0`）。

## 標準ワークフロー

1. `just init <owner> --topics moonbit rust` で `repository.ini` を初期生成
2. `--topics` 未指定時は `moonbit rust` が使われる
3. `repository.ini` の有効行に `<owner>/<repo>` を1行ずつ記載（空行と `#` / `;` 行は無視）
4. `just clone` で `./repos` に clone
5. `just doctor` で前提コマンド・`repository.ini`・clone 状態を確認
6. `just pull` で既存 active repo を更新
   - 全 clone を対象にしたい場合だけ `just --set REPO_SCOPE cloned pull`
7. 余剰 clone の整理が必要なら `just repos-prune` / `just repos-prune --apply`
8. topic migration
   - `just topics-migrate-moonbit`
   - `just topics-migrate-moonbit --apply`
9. `repository.ini` 対象への topic 追加
   - `just topics-add-from-ini <topic>`
   - `just topics-add-from-ini <topic> --apply`
10. 依存の確認と適用
   - `just deps-scan-all`
   - `just deps-apply-all`
   - 個別: `just deps-scan <repo>` / `just deps-apply <repo>`
11. `moon-dst just` 相当
   - `just deps-just-all`
   - `just deps-just <repo>`
12. moonbit toolchain 本体の一括更新（`repository.ini` 非依存。`f4ah6o` + `moonbit` topic の全 repo が対象）
   - `just moonbit-bump-scan`
   - `just moonbit-bump <version>`
   - `just moonbit-bump <version> --apply`
   - `.tool-versions` と `.github/workflows/*.yml` の `cli.moonbitlang.com/install/unix.sh` 行だけを更新する
   - `moonbitlang/*` deps は対象外（`just deps-apply-all` を別途実行）
   - 未 clone の repo は warn のみでスキップ（自動 clone はしない）
13. MoonBit repo の refactoring（`moonbit-refactoring` skill 経由）
   - 前提: `just skills-init` 済みで対象 repo が clean
   - `just refactor <repo>` で環境検証と次手順の出力
   - 出力に従って `refactor/<date>` ブランチを切り、codex/claude で skill を起動
   - skill が指示する順序（architecture -> API 棚卸し -> 最小差分 -> tests/docs -> `moon check`/`moon test`）で進める

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
  - `just moon-fmt <repo>`
  - `just moon-check <repo>`
  - `just moon-build <repo>`
  - `just moon-clean <repo>`
  - `just moon-test <repo>`
- 運用補助
  - `just status-all`
  - `just push-all`
  - `just gh-runs-last-all`
  - `just gh-runs-rerun-failed-all`
  - failed workflow の rerun は dry-run 既定
  - `repos/` 全削除は `just --set FORCE 1 clean` / `just --set FORCE 1 cclone`
