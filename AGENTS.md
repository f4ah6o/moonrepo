## 

moonbitのdependencyを一括しておこなうrepository

## 事前準備

* skillのインストール
  * `skop add moonbit-agent-guide@f4ah6o/skills-bonsai --target all`
  * `skop add monnbit-refactoring@f4ah6o/skills-bonsai --target all`

## しないこと

* monorepo

##

## Workflow

* `just init <owner> --topics moonbit rust` で `repository.ini` を初期生成（topic 条件 OR、コメントアウトで出力）
* `--topics` 未指定時は `moonbit rust` を使用
* repository.ini に `<owner>/<repo>` を1行ずつ書く（空行と `#` 行は無視）
* `just clone` で `./repos` に clone
* `just pull` で既存 repos を更新
* migration: `just topics-migrate-moonbit`（dry-run） / `just topics-migrate-moonbit --apply`
* 任意topic追加: `just topics-add-from-ini <topic>`（dry-run） / `just topics-add-from-ini <topic> --apply`
* moonrepo 管理対象 repo には `moonbit` / `rust` topic を設定する運用にする
* `just deps-scan-all` で依存一覧を確認
* `just deps-apply-all` で依存更新（例: `--dry-run`, `--no-justfile`）
* 個別実行は `just deps-scan <repo>` / `just deps-apply <repo>`
* `moon-dst just` 相当は `just deps-just-all` / `just deps-just <repo>`
* turbo 風の一括実行は `just moon-fmt-all` / `just moon-check-all` / `just moon-build-all` / `just moon-clean-all`
* `moon test` は `just moon-test-all`（一括）/ `just moon-test <repo>`（個別）
* 個別実行は `just moon-fmt <repo>` / `just moon-check <repo>` / `just moon-build <repo>` / `just moon-clean <repo>`

## 

## Development Guide(MUST READ)

- `docs/DEVELOPMENT_GUIDE.md` を必ず読んでから作業すること。
