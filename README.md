# moonrepo

MoonBit の dependency を複数リポジトリに対して一括で更新・運用するための管理リポジトリです。
モノレポではありません。

## 目的

- 複数の非 monorepo な MoonBit リポジトリをまとめて clone / update
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

リポジトリ名`*.mbt`をリストアップします。初期状態は全てコメントアウトしています。
```sh
just init <owner>
```

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

## よく使うコマンド

- 依存の一覧
  - `just deps-scan-all`
- 依存更新（dry-run）
  - `just deps-apply-all --dry-run`
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
