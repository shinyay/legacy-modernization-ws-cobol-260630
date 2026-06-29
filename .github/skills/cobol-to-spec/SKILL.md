---
name: cobol-to-spec
description: 'COBOL から業務仕様を復元し specs/<prog>.md に構造化抽出する（Code→Doc）。入出力契約・業務ルール・数値/桁/丸め・エッジケース・データ定義を、直訳せず意図として残す。USE FOR: COBOL を読んで仕様化する / 移行前に振る舞いを文書化する / Analyze→Code-to-Doc 工程。DO NOT USE FOR: Java 生成（spec-to-java を使う）/ golden 作成（golden-master-testing）/ COBOL を直接 Java へ直訳すること。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# cobol-to-spec（Code→Doc：COBOL から仕様を復元）

直訳を避けるため、COBOL の振る舞いを一度 **spec** に起こす（ADR-0009）。出力は `specs/<prog>.md`。

## Skill Quality（この skill が満たす6条件 / ADR-0014）

- **ground truth**: 元 COBOL ソース ＋（あれば）Golden Master 出力。推測でなくソースを根拠にする。
- **gate**: spec は後段（golden 作成・Java 生成）の入力。golden と矛盾する spec は不可。
- **artifact**: 必ず `specs/<prog>.md` を出力する。出さずに完了としない。
- **order**: Analyze → 本 skill（Code→Doc）→ Golden Master → spec-to-java。順序を飛ばさない。
- **completion criteria**: 入出力契約・業務ルール・数値規則・エッジケース・データ定義が埋まり、未確定は「未確定(TODO)」と明記。
- **escape-hatch control**: 「たぶん」で埋めない。COBOL に無い仕様を創作しない。直訳（COBOL→Java）へ飛ばない。

## spec の構成（specs/<prog>.md）

- 概要 / 入力契約（形式・桁・固定長）/ 出力契約（編集表示・改行）
- 業務ルール（計算式・分岐）
- 数値規則（`PIC`・暗黙小数 `V`・`COMP-3`・`ROUNDED`＝丸めモード）
- エッジケース（ゼロ・最大桁・空入力・非数値）/ 非決定性（日付・乱数・時刻）
- データ定義（レコード・項目）/ 未確定事項（TODO）

## 手順

1. `PROCEDURE` / `DATA DIVISION` を読み、入出力と計算を洗い出す。
2. 数値の桁・丸め・編集表示を**明示**（後段の BigDecimal 化の根拠になる）。
3. エッジケース・非決定性を列挙（golden のマスク対象になる）。
4. `specs/<prog>.md` に書き出し、未確定は TODO で残す。

## 関連

- 題材: `samples/interest/`（利息計算）。
- ADR-0009（Code→Doc→Code）/ ADR-0014（Skill Quality）。
- 次工程: `golden-master-testing` → `spec-to-java`。
