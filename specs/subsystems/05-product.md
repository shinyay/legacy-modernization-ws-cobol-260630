# Subsystem Spec — 05-product

## Summary

商品マスタを管理し、参照を提供するマスタ/ライブラリ。利息計算・記帳が参照する商品属性を保持する。

- 区分: master
- 信頼度: confirmed
- モダナイズ先: `init_job`

## Business Role

商品条件・区分フラグの正となるマスタ。利息計算（13）等が商品属性を参照する。

## Entrypoint

- `prod-load`: シードから商品索引をロード
- `prod-lookup`: 商品コードで参照

## Inputs

- `subsystems/05-product/data/products-mvp.dat`（シード）
- `product.idx`（ISAM 索引）

## Outputs

- 商品情報

## Database Access

なし（`EXEC SQL` 検出 0 件）。

## ISAM Files

- `PRODUCT-FILE`（`product.idx`）
- `PRD-SEED-FILE`（シードロード用）

## Messaging

なし。

## Business Rules

- 商品コードによる単一検索。

## Dependencies

- 観測 CALL: `SHARED-LOG`
- manifest 依存: なし

## Tests / Evidence

- `subsystems/05-product/tests/unit/prd-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。

## Risks

- 商品の版管理 / 適用日ルールが未確定。

## Open Questions

- 適用日（effective date）の扱い。

