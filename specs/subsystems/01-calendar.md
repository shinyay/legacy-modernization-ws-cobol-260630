# Subsystem Spec — 01-calendar

## Summary

営業日カレンダーを管理するマスタ/ライブラリ。日種別（営業日・休日）の判定と、前後営業日の参照を他サブシステムへ提供する。

- 区分: master
- 信頼度: confirmed
- モダナイズ先: `init_job`

## Business Role

取引検証（10）・利息計算（13）・記帳（12）・口座ライフサイクル（09）など、営業日基準で動くバッチ全般の日付基盤。

## Entrypoint

- `cal-load`: シードからカレンダー索引をロード
- `cal-lookup`: 指定日の日種別を参照
- `cal-next-bd`: 翌営業日を算出
- `cal-prev-bd`: 前営業日を算出

## Inputs

- `subsystems/01-calendar/data/calendar-seed.dat`（シード）
- `calendar.idx`（ISAM 索引）

## Outputs

- 日種別（営業日 / 休日）
- 翌営業日 / 前営業日

## Database Access

なし（`EXEC SQL` 検出 0 件）。

## ISAM Files

- `CALENDAR-FILE`（`calendar.idx`）
- `CAL-SEED-FILE`（シードロード用）

## Messaging

なし。

## Business Rules

- 日付の営業日 / 休日判定。
- 前後営業日の探索（休日をスキップして直近営業日を返す）。

## Dependencies

- 観測 CALL: `CAL-LOOKUP`, `SHARED-LOG`
- manifest 依存: なし

## Tests / Evidence

- `subsystems/01-calendar/tests/unit/cal-test.cob`

## Modernization Notes

- 初期ロード系のため Container Apps の `init_job` として実行。
- ISAM はローカル索引、Azure Files マウントを想定。

## Risks

- 年度境界・連続休日などのエッジケースは golden で固定すべき。

## Open Questions

- 祝日ポリシーの定義元（外部マスタか内蔵テーブルか）。

