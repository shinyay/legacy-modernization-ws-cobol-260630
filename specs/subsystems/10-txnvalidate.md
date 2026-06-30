# Subsystem Spec — 10-txnvalidate

## Summary

デコード済み取引を検証し、受理/却下に振り分けるバッチ。チェックポイント復旧にも対応する。

- 区分: batch
- 信頼度: inferred
- モダナイズ先: `container_apps_job`

## Business Role

取引パイプライン（19→10→11→12）の入口検証。マスタ照合により受理/却下を決定する。

## Entrypoint

- `txval-validate-batch`: 検証本体
- `txval-checkpoint-recover`: チェックポイント復旧
- `txval-report-summary`: サマリ出力

## Inputs

- `txn-decoded.dat`

## Outputs

- `txn-ready.dat`（受理）
- `txn-reject.dat`（却下）
- サマリレポート

## Database Access

なし（ファイル I/O 中心）。

## ISAM Files

- ファイルチャネル: `TXN-DECODED-FILE`, `TXN-VALID-FILE`, `TXN-ERROR-FILE`, `TXN-CHECKPOINT-FILE`, レポートファイル

## Messaging

なし。

## Business Rules

- 店舗（02）・カレンダー（01）・商品（05）の照合による妥当性検証。
- 却下理由コードの付与。
- チェックポイントによる再開。

## Dependencies

- 観測 CALL: `BR-LOOKUP`, `CAL-LOOKUP`, `PROD-LOOKUP`, `SHARED-LOG`
- manifest 依存: 19, 08

## Tests / Evidence

- `subsystems/10-txnvalidate/tests/unit/txval-test.cob`

## Modernization Notes

- バッチのため `container_apps_job`。

## Risks

- 却下理由コード体系は下流分析向けの契約として固定すべき。

## Open Questions

- チェックポイント粒度と再実行時の重複防止。

