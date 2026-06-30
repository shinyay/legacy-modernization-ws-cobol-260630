# Subsystem Spec — 12-txnpost

## Summary

記帳エンジン（借貸適用・取消・残高更新・監査 outbox 出力）。システムの中核バッチ。

- 区分: batch
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

整列済み取引を PostgreSQL へ複式記帳し、残高を更新し、監査 outbox を出力する。

## Entrypoint

- `txpost-run-batch`: 記帳バッチ本体（SQB）
- `txpost-reverse`: 取消処理（SQB）
- `txpost-report-summary`: サマリ出力

## Inputs

- `txn-sorted.dat`

## Outputs

- `postings`, `balances`（テーブル）
- `txn-error.dat`、サマリレポート

## Database Access

SQL 多用（`EXEC SQL` 検出多数）。テーブル: `accounts`, `postings`, `balances`, `audit_outbox`。

## ISAM Files

- `account.idx`、ファイルチャネル: `TXN-READY-FILE`, `TXN-ERROR-FILE`, `DORMANCY-REPAIR-FILE`, `TXN-RECON-DEFER-FILE`

## Messaging

直接の MQ 出力はなし。`audit_outbox` 経由で 20-integrationout が公開。

## Business Rules

- 複式簿記（借方/貸方の一致）。
- 取消の冪等性。
- 残高不変条件チェック（ws-invariant-check）。
- 休眠修復・recon defer の復旧処理。

## Dependencies

- 観測 CALL: `ACCT-EXISTS`, `ACCT-LOOKUP`, `ACCT-UPDATE-DORMANCY-DATE`, `AUD-WRITE`, `SHARED-LOG`
- manifest 依存: 01, 08, shared/aud-write

## Tests / Evidence

- `subsystems/12-txnpost/tests/unit/txpost-test.cob`
- `subsystems/12-txnpost/tests/unit/check-balance.sh`
- `subsystems/12-txnpost/tests/unit/check-postings-sum.sh`

## Modernization Notes

- バッチのため `container_apps_job`。OCESQL を rehost コンテナで実行。

## Risks

- exactly-once 性・retry 振る舞い・取消冪等性が高リスクな移行点。

## Open Questions

- SQL retry 時のトランザクション境界と重複防止キー。

