# Subsystem Spec — 22-operations

## Summary

バッチ制御プレーンのオーケストレーター。日次/月次パイプラインの開始・ステップ実行・ファイナライズを管理する。

- 区分: orchestrator
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

`batch_run` の状態遷移を伴い、各サブシステムを順番に実行して日次/月次バッチを統制する。

## Entrypoint

- `ops-batch-daily`: 日次バッチ（SQB）
- `ops-batch-monthly`: 月次バッチ（SQB）
- `ops-drain-queues`: キュードレイン
- `ops-partition-rollover`: パーティションロールオーバー
- `ops-finalize`: ファイナライズ（SQB）

## Inputs

- `batch_run`、ステップ実行スクリプト、マスタ/口座シード資産

## Outputs

- 更新された `batch_run`
- 遅延 recon ファイル（`recon-defer.dat`）、オーケストレーションログ/監査

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。`batch_run`, `transactions`。

## ISAM Files

- `ACCOUNT-FILE`（シード/ロード系）

## Messaging

- `ops-drain-queues` 経由で 20-integrationout を起動しキューをドレイン。

## Business Rules

- 日次: 19→13→15→16→17→20(drain)→recon。
- 月次: 14→21(partition rollover)。
- ステップ実行は `CALL "SYSTEM"` で shell ステップ（`ops-step-*.sh`）を起動。
- 部分失敗時の復旧と finalize の冪等性遷移。

## Dependencies

- 観測 CALL: `INTO-DRAIN-QUEUE`, `OPS-PARTITION-ROLLOVER`, `AUDIT-PARTITION-ROLLOVER`, `AUD-WRITE`, `SYSTEM`
- manifest 依存: 19, 13, 15, 16, 17, 20, 14, 21

## Tests / Evidence

- `subsystems/22-operations/tests/unit/ops-driver.cob`
- `subsystems/22-operations/tests/unit/ops-test.sh`
- `systemd/` の timer/service（batch-daily/monthly, partition-rollover ほか）

## Modernization Notes

- オーケストレーションバッチのため `container_apps_job`。systemd timer を ACA Jobs スケジュールへ写像。

## Risks

- ステップ再試行セマンティクス・部分失敗復旧・冪等 finalize が本番統制の要。

## Open Questions

- ステップ間依存の確証（EXEC-STEP 連鎖の正確な順序）。

