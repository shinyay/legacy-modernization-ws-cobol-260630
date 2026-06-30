# Subsystem Spec — 21-audit

## Summary

監査ログのパーティション管理、フォレンジック抽出、監査集計レポートを担うバッチ。

- 区分: batch（月次保守を含む）
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

`audit_log`（月次 RANGE partition）のロールオーバーと保存期限管理、フォレンジック照会、集計レポートを提供する。

## Entrypoint

- `audit-partition-rollover`: パーティション生成/detach（SQB）
- `audit-query-forensic`: フォレンジック照会（SQB）
- `audit-summary-report`: 集計レポート（SQB）

## Inputs

- `audit_outbox`、UUID フィルタファイル（任意）

## Outputs

- `audit_log` メンテナンスの副作用
- フォレンジック/集計出力ファイル（`OUT-FILE`）

## Database Access

SQL 多用（`EXEC SQL` 検出多数）。`audit_log`, `audit_outbox`、パーティション関数（`create_audit_partition`, `detach_expired_audit_partitions`）。

## ISAM Files

- ファイルチャネル: `OUT-FILE`, `UUID-FILE`

## Messaging

なし。

## Business Rules

- 月次 RANGE partition の生成/detach。
- 保存期限ホライゾンによる期限切れパーティションの切り離し。
- フォレンジック照会（カーソル）。

## Dependencies

- 観測 CALL: `AUD-WRITE`
- manifest 依存: shared/aud-write

## Tests / Evidence

- `subsystems/21-audit/tests/unit/audit-driver.cob`
- `subsystems/21-audit/tests/unit/audit-test.sh`

## Modernization Notes

- バッチのため `container_apps_job`。`detach-helper.sh` を伴う。

## Risks

- パーティション detach/保存ポリシーとフォレンジック照会性能が運用上重要。

## Open Questions

- 保存期間（horizon）のポリシー値。

