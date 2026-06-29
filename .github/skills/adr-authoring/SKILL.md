---
name: adr-authoring
description: 'Architecture Decision Record (ADR) を docs/adr/ に作成・更新する手順と規約（採番・ファイル名・Nygard 書式・索引更新・不変/supersede）。USE FOR: 重要な技術判断を記録する / 新しい ADR を追加する / 既存 ADR を supersede する / verify.md が周回ごとに移行判断を ADR 化する。DO NOT USE FOR: 些細・可逆・単一開発者で完結する決定や、既に標準・ポリシーで覆われた事項（ADR 不要）、ADR 以外の一般ドキュメント作成。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# ADR Authoring（ADR を正しく書く）

`docs/adr/` に Architecture Decision Record を作成・更新するための**唯一の手順**。
人間も、ループの `verify.md`（周回ごとに移行判断を ADR 化する）も、この SKILL に従うこと。

## いつ使うか
- 重要な技術判断を記録するとき（**1 ADR = 1 決定**）。
- ループが各 COBOL を rewrite / fallback した理由を残すとき。
- 既存の決定を覆すとき（supersede）。

## いつ使わないか
- 些末・可逆・単一開発者で完結する決定、または既に標準/方針で覆われている事項（ADR 不要）。

## 形式（Nygard ＋ 最小拡張。MADR の Confirmation を任意採用）
雛形は `docs/adr/template.md`。項目:
- タイトル: `# ADR-NNNN: <決めたことを一言で>`（現在形の動詞句で）
- **Status**: `Proposed` | `Accepted` | `Deprecated` | `Superseded by ADR-NNNN`
- **Date**: `YYYY-MM-DD`（今日）
- **Deciders**: `@who`
- **Context**: なぜ必要か（背景・制約・力学。事実ベース。価値判断は Decision へ）
- **Decision**: 何を決めたか（能動態で言い切る）
- **Consequences**: 良い点 / 悪い点・トレードオフ / 中立
- **Confirmation**（任意）: その決定をどう検証/担保するか（例: `ci.yml` の golden required check、テスト、レビュー）
- **Alternatives considered**（任意）/ **References**（任意）

## 手順
1. **採番**: `docs/adr/` の既存 `NNNN-*.md` の最大番号 + 1。**番号は再利用しない**（撤回しても欠番のまま）。
2. **ファイル名**: `NNNN-title-with-dashes.md`（4 桁ゼロ詰め・小文字・ダッシュ・`.md`）。
   例: `0042-use-bigdecimal-for-comp3.md`
3. **本文**: `docs/adr/template.md` をコピーして埋める。**1 ADR = 1 決定**（複数を混ぜない）。
4. **Status**: 提案段階は `Proposed`、合意できたら `Accepted`。
   - **agent / 自動化（`verify.md` 等）は `Proposed` で作成し、自分で `Accepted` にしない**。
     `Accepted` への昇格は**人間レビューを経た人間の操作**で行う（ADR-0012 の方針・Confirmation）。
5. **不変性**: 既存 ADR の Decision 本文は書き換えない。覆すときは
   - 新しい ADR を作り、Context に経緯を書く。
   - 古い ADR の Status だけを `Superseded by ADR-NNNN` に変更する。
6. **索引更新**: `docs/adr/README.md` の索引テーブルに 1 行追加し、「次は NNNN」の番号を進める。
7. （ループ運用時）ADR は PR に含め、`verify.md` のステップで作成する。

## 採番の確認（コマンド例）
```bash
# 最大番号を表示 → +1 が次の番号
ls docs/adr/ | grep -Eo '^[0-9]{4}' | sort -n | tail -1
```

## 品質チェックリスト
- [ ] 1 ファイル = 1 決定
- [ ] タイトルは決定を一言で表す動詞句
- [ ] Context は事実、Decision は能動態の言い切り
- [ ] Consequences に悪い点 / トレードオフも書いた
- [ ] （あれば）Confirmation に検証方法を書いた
- [ ] 採番が連番・欠番なし・重複なし、ファイル名規約に合致
- [ ] `docs/adr/README.md` の索引を更新した
- [ ] agent / 自動生成時は Status=`Proposed`（`Accepted` は人間が付ける）

## 参考（標準）
- Michael Nygard, "Documenting Architecture Decisions" (2011)
- MADR / adr.github.io（Confirmation・Considered Options 等の構造化）
- npryce/adr-tools（`NNNN-title-with-dashes.md`、`0001` = record-architecture-decisions）

## 関連 ADR
- [ADR-0001](../../../docs/adr/0001-record-architecture-decisions.md) — ADR を採用・運用する
- [ADR-0012](../../../docs/adr/0012-use-curated-focused-skills.md) — skill 方針（focused・index・**agent は単独で Accepted にしない**）
