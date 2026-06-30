# Subsystem Spec — 02-branch

## Summary

店舗（支店）マスタを管理し、参照・一覧・地域別一覧の API を提供するマスタ/ライブラリ。

- 区分: master
- 信頼度: confirmed
- モダナイズ先: `init_job`

## Business Role

取引検証や照会フローが店舗コードの妥当性確認・店舗情報の取得に利用する。

## Entrypoint

- `br-load`: シードから店舗索引をロード
- `br-lookup`: 店舗コードで単一参照
- `br-list-all`: 全店舗一覧
- `br-list-by-region`: 地域別一覧

## Inputs

- `subsystems/02-branch/data/branches-mvp.dat`（シード）
- `branch.idx`（ISAM 索引）

## Outputs

- 店舗情報レコード（単一 / 一覧）

## Database Access

なし（`EXEC SQL` 検出 0 件）。

## ISAM Files

- `BRANCH-FILE`（`branch.idx`）
- `BR-SEED-FILE`（シードロード用）

## Messaging

なし。

## Business Rules

- 店舗コードによる単一検索。
- 地域コードによる絞り込みと一覧化。

## Dependencies

- 観測 CALL: `SHARED-LOG`
- manifest 依存: なし

## Tests / Evidence

- `subsystems/02-branch/tests/unit/br-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。

## Risks

- 地域コードの正規化・一覧の並び順は互換性チェックが必要。

## Open Questions

- 地域コード体系の正準定義。

