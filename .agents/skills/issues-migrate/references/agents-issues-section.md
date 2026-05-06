
## issues について

- 番号が小さい issues から順に対応すること
- `{YYYY-MM-DDThhmmss}-{category}-{short-description}.md` という命名規則を守ること
  - 日付時刻は issue 作成時の ISO 8601 形式（ファイルシステム安全のためコロンなし）
  - 例: `2026-05-05T150150-spec-stabilize-mx-attribute-contract.md`
  - 例: `2026-05-06T091500-bug-fix-parse-error.md`
- 仕様的に対応が難しい場合は issues/pending/ へ移動すること
- issue を作成したらコミットすること
- 1 issue 完了ごとに 1 コミットすること
- Issue の作成日はファイルのタイトルの後に `Created: YYYY-MM-DD` として記載すること
- Issue の完了日はファイルのタイトルの後に `Completed: YYYY-MM-DD` として記載すること
- Issue を作成した LLM の Model と Version をファイルのタイトルの後に `Model: <model-name> <version>` として記載すること
- Issue はなぜこの対応が必要なのかの根拠を明確にすること

### issue が実は解決してなかった場合

- reopen の理由を issue に書いて issues/closed から issues/ に移動すること (git mv を使うこと)
- reopen の理由は、何がどう解決していなかったのかを明確にすること

### バグが見つかった場合

- issues/ 以下にバグを markdown 形式で登録すること
- バグは再現手順を明確にすること
- できる限りの情報を

### バグを修正した場合

- issues/ 以下のバグを修正した場合は、修正内容を markdown 形式で記載すること
- issues/closed に移動すること (git mv を使うこと)
- issues/closed に移動するときは issue ファイルに「## 解決方法」セクションを追記し、何をどう修正したかを明記すること

### 設計判断が必要な issue の場合

- 外部依存の追加や設計判断が必要で保留中の issue は `issues/pending/` に置くこと
- issues/pending に移動するときは issue ファイルに pending にした理由を明記すること
- pending の issue は修正せずそのまま残す（close しない）

### issue workflow の参考

この issue 管理方式は [shiguredo/http3-rs](https://github.com/shiguredo/http3-rs/blob/develop/AGENTS.md) の AGENTS.md を参考にしている。
ただし本プロジェクトでは連番 (`issues/SEQUENCE`) の代わりに日付時刻をファイル名に使用する。
