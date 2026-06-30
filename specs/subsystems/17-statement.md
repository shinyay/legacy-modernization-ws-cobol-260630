# Subsystem Spec — 17-statement

## Summary

口座・記帳データから顧客明細表（statement）を生成するバッチ。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

`accounts` / `postings` を集計して明細表ファイルを生成する。

## Entrypoint

- `stmt-generate-batch`: 明細表生成（SQB）

## Inputs

- `accounts`, `postings`

## Outputs

- 明細表ファイル（`REPORT-FILE`）とサマリ（`SUMMARY-FILE`）

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。

## ISAM Files

なし。

## Messaging

なし。

## Business Rules

- 明細順・繰越残高・書式互換性。

## Dependencies

- 観測 CALL: `AUD-WRITE`
- manifest 依存: 12

## Tests / Evidence

- `subsystems/17-statement/tests/unit/stmt-test.cob`
- `subsystems/17-statement/tests/unit/check-audit.sh`

## Modernization Notes

- バッチのため `container_apps_job`。

## Risks

- 明細順序・繰越残高・書式の互換性を固定すべき。

## Open Questions

- 明細表の出力形式（帳票/PDF/テキスト）の最終仕様。

