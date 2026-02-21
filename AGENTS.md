## 概要

moonbit / rust リポジトリ群の依存更新・一括運用を行う管理リポジトリ。  
monorepo ではありません。

## Development Guide (MUST READ)

- 作業前に必ず `docs/DEVELOPMENT_GUIDE.md` を読むこと。

## 事前準備

- 必須コマンド
  - `gh`
  - `just`
  - `moon`
  - `moon-dst`
  - `skop`（skill 管理に使う）
- skill の初期化（`justfile` の定義に合わせる）
  - `just skills-init`
- 手動インストールする場合
  - `skop add moonbit-agent-guide@f4ah6o/skills-bonsai --target codex`
  - `skop add moonbit-refactoring@f4ah6o/skills-bonsai --target codex`

## しないこと

- monorepo 化しない

## 標準ワークフロー

1. `just init <owner> --topics moonbit rust` で `repository.ini` を初期生成
2. `--topics` 未指定時は `moonbit rust` が使われる
3. `repository.ini` の有効行に `<owner>/<repo>` を1行ずつ記載（空行と `#` / `;` 行は無視）
4. `just clone` で `./repos` に clone
5. `just pull` で既存 `repos/*` を更新
6. topic migration
   - `just topics-migrate-moonbit`
   - `just topics-migrate-moonbit --apply`
7. `repository.ini` 対象への topic 追加
   - `just topics-add-from-ini <topic>`
   - `just topics-add-from-ini <topic> --apply`
8. 依存の確認と適用
   - `just deps-scan-all`
   - `just deps-apply-all`
   - 個別: `just deps-scan <repo>` / `just deps-apply <repo>`
9. `moon-dst just` 相当
   - `just deps-just-all`
   - `just deps-just <repo>`

## 一括実行コマンド

- turbo 風一括
  - `just moon-fmt-all`
  - `just moon-check-all`
  - `just moon-build-all`
  - `just moon-clean-all`
  - `just moon-test-all`
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

## tornado 開発導線（repos 配下）

`repos/<repo>` で tornado を使う導線を追加する場合は、ローカル skill のスクリプトを使う。

- skill: `.agents/skills/tornado-repo-bootstrap`
- 実行:
  - `bash .agents/skills/tornado-repo-bootstrap/scripts/enable_tornado_repo.sh <repo_name>`
- 追加される内容:
  - `repos/<repo_name>/tornado.json`
  - `repos/<repo_name>/justfile` に `tornado` / `tornado-validate` recipe
