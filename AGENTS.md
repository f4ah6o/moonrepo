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

* `just repos-init <owner>` で `repository.ini` を初期生成（`.mbt` を含む repo 名だけ対象、コメントアウトで出力）
* repository.ini に `<owner>/<repo>` を1行ずつ書く（空行と `#` 行は無視）
* `just repos-clone` で `./repos` に clone
* `just repos-pull` で既存 repos を更新
* `just repos-sync` で clone と pull をまとめて実行
* `just deps-scan-all` で依存一覧を確認
* `just deps-apply-all` で依存更新（例: `--dry-run`, `--no-justfile`）
* 個別実行は `just deps-scan <repo>` / `just deps-apply <repo>`
* `moon-dst just` 相当は `just deps-just-all` / `just deps-just <repo>`
* turbo 風の一括実行は `just moon-fmt-all` / `just moon-check-all` / `just moon-build-all` / `just moon-clean-all`
* `moon test` は `just moon-test-all`（一括）/ `just moon-test <repo>`（個別）
* 個別実行は `just moon-fmt <repo>` / `just moon-check <repo>` / `just moon-build <repo>` / `just moon-clean <repo>`

## 

## Development Guide

see also @docs/DEVELOPMENT_GUIDE.md 
