# Subsystem Spec — 03-customer

## Summary

顧客マスタを管理し、参照・一覧・カナ/電話番号検索・状態変更を提供するマスタ/ライブラリ。

- 区分: master
- 信頼度: confirmed
- モダナイズ先: `init_job`

## Business Role

顧客情報の正となるマスタ。照会（18）・顧客検索（04）が参照し、状態変更は監査へ記録する。

## Entrypoint

- `cust-load`: シードから顧客索引をロード
- `cust-lookup`: 顧客IDで単一参照
- `cust-list-all`: 全顧客一覧
- `cust-search-by-kana`: カナ検索
- `cust-search-by-phone`: 電話番号検索
- `cust-status-change`: 顧客状態の変更

## Inputs

- `subsystems/03-customer/data/customers-mvp.dat`（シード）
- `customer.idx`（ISAM 索引）

## Outputs

- 顧客情報、絞り込み済み顧客一覧
- 状態変更の監査イベント

## Database Access

なし（`EXEC SQL` 検出 0 件）。

## ISAM Files

- `CUSTOMER-FILE`（`customer.idx`）
- `CUST-SEED-FILE`（シードロード用）

## Messaging

なし。

## Business Rules

- 顧客IDによる単一検索、全件一覧。
- カナ / 電話番号による検索（正規化・完全/部分一致の仕様を明確化要）。
- 状態変更時に監査ログを書き込む。

## Dependencies

- 観測 CALL: `AUD-WRITE`, `SHARED-LOG`
- manifest 依存: なし

## Tests / Evidence

- `subsystems/03-customer/tests/unit/cust-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。

## Risks

- カナ/電話番号のマッチング規則（正規化・一致種別）を決定的仕様として固定する必要。

## Open Questions

- 状態遷移の許容パターン（どの状態からどの状態へ遷移可能か）。

