# Subsystem Spec — 11-txnsortmerge

## Summary

記帳前の決定的なソート/マージ段。前回の recon/defer 成果物も取り込む。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

受理済み取引を記帳順に整列し、再現性のある順序で記帳（12）へ引き渡す。

## Entrypoint

- `txsm-sort-batch`: ソート
- `txsm-merge-batch`: マージ
- `txsm-report-summary`: サマリ出力

## Inputs

- `txn-ready.dat`

## Outputs

- `txn-sorted.dat`
- サマリレポート

## Database Access

なし（ファイル I/O 中心）。

## ISAM Files

- ファイルチャネル: `TXN-READY-FILE`, `TXN-SORTED-FILE`, `SORT-WORK-FILE`, recon/temp ファイル群

## Messaging

なし。

## Business Rules

- 安定ソートキーによる整列。
- 前回未処理（recon/defer）の取り込みとマージ。

## Dependencies

- 観測 CALL: `SYSTEM`, `SHARED-LOG`
- manifest 依存: 10

## Tests / Evidence

- `subsystems/11-txnsortmerge/tests/unit/txsm-test.cob`

## Modernization Notes

- バッチのため `container_apps_job`。

## Risks

- 安定ソートキーと同値レコードの順序が再現性に直結。

## Open Questions

- ソートキーの完全定義と同値時のタイブレーク。

