# Subsystem Spec — 13-interestaccrual

## Summary

日次の利息経過計算。口座/商品/利率のコンテキストで経過利息を積み上げる。

- 区分: batch
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

日次で口座残高に対し適用利率を乗じて経過利息を計算・累積し、月次記帳（14）へ渡す。

## Entrypoint

- `iacr-run-daily`: 日次経過計算（SQB）
- `iacr-report-summary`: サマリ出力（SQB）

## Inputs

- `accounts`, `interest_rates`、マスタ参照

## Outputs

- `interest_accruals`（テーブル）
- `IACR-REPORT-FILE`, `IACR-SUMMARY-FILE`

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。テーブル: `accounts`, `interest_accruals`。

## ISAM Files

- `calendar.idx`, `product.idx`（manifest 記載）

## Messaging

なし。

## Business Rules

- 適用利率×残高×経過日数による利息計算。
- 丸め・桁の厳密な取扱（COMP-3 精度）。
- 営業日・経過日数規約。

## Dependencies

- 観測 CALL: `IRATE-LOOKUP`, `PROD-LOOKUP`, `ACCT-EXISTS`, `AUD-WRITE`
- manifest 依存: 01, 05, 06, 08, shared/aud-write

## Tests / Evidence

- `subsystems/13-interestaccrual/tests/unit/iacr-test.cob`
- `subsystems/13-interestaccrual/tests/unit/iacr-count.sh`

## Modernization Notes

- バッチのため `container_apps_job`。数値精度は BigDecimal 相当で厳密に。

## Risks

- 数値精度/丸めと経過日規約は golden master で固定必須。

## Open Questions

- 経過日数カウント規約（端点を含む/含まない）。

