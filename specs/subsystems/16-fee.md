# Subsystem Spec — 16-fee

## Summary

階層手数料スケジュールに基づき期間手数料を賦課するバッチ。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

`fee_schedules` の階層に応じて口座へ手数料を賦課し、記帳とサマリを生成する。

## Entrypoint

- `fee-charge`: 手数料賦課（SQB）
- `fee-report-summary`: サマリ出力（SQB）

## Inputs

- `fee_schedules`

## Outputs

- 手数料記帳（`postings`）
- `FEE-RPT-FILE`

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。口座と手数料スケジュールの参照/書き込み。

## ISAM Files

なし。

## Messaging

なし。

## Business Rules

- 階層（tier）境界に基づく手数料決定。
- 再試行時の副作用防止。

## Dependencies

- 観測 CALL: `FEE-LOOKUP-BY-TIER`, `ACCT-EXISTS`, `AUD-WRITE`
- manifest 依存: 07, 08

## Tests / Evidence

- `subsystems/16-fee/tests/unit/fee-test.cob`
- `subsystems/16-fee/tests/unit/fee-retry-test.sh`

## Modernization Notes

- バッチのため `container_apps_job`。

## Risks

- 階層境界と再試行の副作用が主要な正確性リスク。

## Open Questions

- 手数料賦課サイクル（月次/期間）の正規定義。

