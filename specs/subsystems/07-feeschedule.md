# Subsystem Spec — 07-feeschedule

## Summary

手数料スケジュールを管理し、階層（tier）別の手数料参照を提供するマスタ/ライブラリ。

- 区分: master
- 信頼度: inferred
- モダナイズ先: `init_job`

## Business Role

手数料の正となるマスタ。手数料賦課（16）が階層別の手数料を取得する。

## Entrypoint

- `fee-load`: 手数料スケジュールをロード
- `fee-lookup-by-tier`: 階層別に手数料を参照

## Inputs

- `subsystems/07-feeschedule/data/feeschedules-mvp.dat`（シード）
- `fee_schedules`（テーブル, manifest 記載）

## Outputs

- 手数料情報

## Database Access

manifest 上は `fee_schedules` テーブルを参照（ソース上は file 形式の名称も存在）。

## ISAM Files

- `FS-FILE`, `FS-SEED-FILE`

## Messaging

なし。

## Business Rules

- 階層（tier）境界に基づく手数料の決定。

## Dependencies

- manifest 依存: なし

## Tests / Evidence

- `subsystems/07-feeschedule/tests/unit/fee-test.cob`

## Modernization Notes

- 初期ロード系のため `init_job`。

## Risks

- 階層境界の包含/排他（以上/未満）の仕様を明示テスト化する必要。

## Open Questions

- 階層境界の正確な定義。

