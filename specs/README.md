# specs/ — Code→Doc の業務仕様（living documentation）

`specs/<program>.md`。`spec-extractor` が COBOL から **業務ルール・入出力・エッジケース・データ定義**を
人間可読の形で抽出する。これが `migrator`（Doc→Code）の入力になり、**移行後も残る保守用ドキュメント**。

> 目的: 直訳（JOBOL）を避け、業務理解を Doc として残すことで「モダン化したのに保守不能」を防ぐ。

## レイアウト
- `specs/<program>.md` — プログラム単位の業務仕様（`spec-extractor` 抽出）。
- `specs/system-overview.md` — システム全体像（`system-analyzer` 抽出）。
- `specs/subsystems/<id>-<name>.md` — サブシステム単位 spec（12 見出しテンプレ）。代表は 12-txnpost / 13-interestaccrual / 22-operations。

