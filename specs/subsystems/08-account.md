# Subsystem Spec — 08-account

## Summary

口座マスタを管理する中核マスタ。参照・存在確認・顧客別参照・休眠日更新を提供する。

- 区分: master
- 信頼度: confirmed
- モダナイズ先: `init_job`

## Business Role

口座情報の正。検証（10）・記帳（12）・照会（18）・ライフサイクル（09）など多数が参照する基盤。

## Entrypoint

- `acct-load`: 口座索引をロード
- `acct-lookup`: 口座番号で参照
- `acct-exists`: 口座の存在確認
- `acct-lookup-by-customer`: 顧客別の口座参照
- `acct-update-dormancy-date`: 休眠判定日の更新

## Inputs

- `subsystems/08-account/data/accounts-mvp.dat`（シード）
- `accounts.idx`（ISAM 索引）

## Outputs

- 口座情報 / 存在可否
- 休眠日更新

## Database Access

manifest 上は `accounts` テーブルを参照（ソースは ISAM 中心）。

## ISAM Files

- `ACCOUNT-FILE`（`accounts.idx`）
- `ACCT-SEED-FILE`（シードロード用）

## Messaging

なし。

## Business Rules

- 口座番号 / 顧客IDによる検索、存在確認。
- 休眠判定日の更新（冪等性が必要）。

## Dependencies

- 観測 CALL: `SHARED-LOG`
- manifest 依存: なし

## Tests / Evidence

- `subsystems/08-account/tests/unit/acct-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。

## Risks

- 休眠日更新の競合制御と冪等性。

## Open Questions

- ISAM と `accounts` テーブルの整合（どちらが正か）。

