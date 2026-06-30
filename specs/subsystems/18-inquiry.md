# Subsystem Spec — 18-inquiry

## Summary

口座/顧客/店舗/検索を集約して返す対話照会エンドポイント。

- 区分: online
- 信頼度: inferred
- モダナイズ先: `container_apps_service`

## Business Role

口座キーや検索条件から、口座/顧客/店舗情報を集約して照会結果を返す。

## Entrypoint

- `inq-main`: 照会本体（SQB）

## Inputs

- 口座キー、検索パラメータ

## Outputs

- 口座/顧客照会結果

## Database Access

SQL 使用（`EXEC SQL` 検出あり）。`accounts`, `balances`, `transactions` を参照。

## ISAM Files

主要な直接ファイルチャネルはなし。

## Messaging

なし。

## Business Rules

- 複数サブシステムの集約参照。
- バッチ更新との整合性（参照タイミング）。

## Dependencies

- 観測 CALL: `ACCT-LOOKUP`, `CUST-LOOKUP`, `BR-LOOKUP`, `CSRCH-BY-ADDRESS`, `AUD-WRITE`
- manifest 依存: 08

## Tests / Evidence

- `subsystems/18-inquiry/tests/unit/inq-test.sh`
- `subsystems/18-inquiry/tests/unit/inq-setup-pg.sh`

## Modernization Notes

- 対話系のため `container_apps_service`。

## Risks

- 応答時間 SLO と、バッチ更新との検索整合性を定義すべき。

## Open Questions

- 参照一貫性の要件（read-after-write の許容度）。

