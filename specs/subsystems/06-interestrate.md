# Subsystem Spec — 06-interestrate

## Summary

利率マスタをロードし、利息計算・記帳向けに利率を参照するマスタ/ライブラリ。

- 区分: master
- 信頼度: inferred
- モダナイズ先: `init_job`

## Business Role

利率の正となるマスタ。利息計算（13）が適用利率を取得する。

## Entrypoint

- `irate-load`: 利率データをロード
- `irate-lookup`: 条件に応じた利率を参照

## Inputs

- `subsystems/06-interestrate/data/interestrates-mvp.dat`（シード）
- `interest_rates`（テーブル, manifest 記載）

## Outputs

- 利率情報

## Database Access

manifest 上は `interest_rates` テーブルを参照（ソース上は file 形式の名称も存在）。

## ISAM Files

- `IRATE-FILE`, `IR-SEED-FILE`

## Messaging

なし。

## Business Rules

- 条件（商品・期間等）に応じた利率の検索。

## Dependencies

- manifest 依存: 05

## Tests / Evidence

- `subsystems/06-interestrate/tests/unit/irate-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。
- 参照基盤が file か DB かを移行時に統一する。

## Risks

- 適用日重複/競合の解決ロジックがホットスポットになりうる。

## Open Questions

- 利率の格納先（ISAM か `interest_rates` テーブルか）の正準。

