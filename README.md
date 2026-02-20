# moonrepo

MoonBit / Rust の dependency を複数リポジトリに対して一括で更新・運用するための管理リポジトリです。
モノレポではありません。

## 目的

- 複数の非 monorepo なリポジトリをまとめて clone / update
- `moon-dst` を使って依存更新を一括で実行
- `moon fmt/check/build/clean/test` を turbo 風に一括実行

## 前提

- `gh`（GitHub CLI）
- `just`
- `moon` / `moon-dst`
  - [moon-dst](https://github.com/f4ah6o/moon-dst-rs)
  - `cargo install moon-dst`

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

4. pull（既存リポジトリの更新）

```sh
just pull
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

## よく使うコマンド

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
- justfile 追加
  - `just deps-just-all`
- moon 一括
  - `just moon-fmt-all`
  - `just moon-check-all`
  - `just moon-build-all`
  - `just moon-clean-all`
  - `just moon-test-all`

## 詳細

運用フローは `AGENTS.md` を参照してください。
