# Subsystem Spec — 15-autodebit

## Summary

予定された口座振替（自動引落）を実行し、失敗/再試行候補を記録するバッチ。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

`autodebit_schedules` に基づき自動引落を実行し、記帳と失敗・再試行レコードを生成する。

## Entrypoint

- `ad-run-daily`: 日次自動引落（SQB）
- `ad-report-summary`: サマリ出力（SQB）

## Inputs

- `autodebit_schedules`

## Outputs

- 記帳（`postings`）
- `AD-FAILED-FILE`, `AD-FAIL-FILE`, `AD-RPT-FILE`

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。スケジュール/口座データのパス。

## ISAM Files

- `account.idx`（manifest 記載）

## Messaging

なし。

## Business Rules

- 引落予定日の解釈と実行。
- 失敗時の再試行候補記録と重複排除（dedup）。

## Dependencies

- 観測 CALL: `ACCT-EXISTS`, `AUD-WRITE`, `SHARED-LOG`
- manifest 依存: 08

## Tests / Evidence

- `subsystems/15-autodebit/tests/unit/ad-test.cob`
- `subsystems/15-autodebit/tests/unit/ad-retry-test.sh`, `ad-dup-seed.sh`, `ad-dup-redue.sh`

## Modernization Notes

- バッチのため `container_apps_job`。systemd の autodebit-retry timer に対応。

## Risks

- 再試行の重複排除と引落日解釈は厳密なテスト可能ルールが必要。

## Open Questions

- 再試行上限/バックオフポリシー。

