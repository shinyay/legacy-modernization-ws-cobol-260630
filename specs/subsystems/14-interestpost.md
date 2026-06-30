# Subsystem Spec — 14-interestpost

## Summary

月次決算で経過利息を記帳へ変換するバッチ（月末）。

- 区分: batch（月次）
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

経過利息（`interest_accruals`）を月末に記帳化し、`postings` へ反映する。

## Entrypoint

- `ipst-run-monthend`: 月末記帳（SQB）
- `ipst-report-summary`: サマリ出力（SQB）

## Inputs

- `interest_accruals`

## Outputs

- 利息記帳（`postings`）
- `IPST-REPORT-FILE`

## Database Access

SQL 多用（`EXEC SQL` 検出多数）。口座/経過利息の参照と記帳書き込み。

## ISAM Files

なし。

## Messaging

なし。

## Business Rules

- 月境界処理と重複記帳防止。
- 経過利息の集計と記帳化。

## Dependencies

- 観測 CALL: `AUD-WRITE`, `SHARED-LOG`
- manifest 依存: 13

## Tests / Evidence

- `subsystems/14-interestpost/tests/unit/ipst-test.cob`
- `subsystems/14-interestpost/tests/unit/ipst-setup-pg.sh`, `ipst-reset-pg.sh`

## Modernization Notes

- 月次バッチのため `container_apps_job`。systemd の batch-monthly に対応。

## Risks

- 月境界の扱いと重複記帳防止が主要統制。

## Open Questions

- 再実行時の冪等性保証キー。

