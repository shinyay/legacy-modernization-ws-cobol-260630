# Subsystem Spec — 19-integrationin

## Summary

外部取引ファイル（EBCDIC/ホスト形式）を内部正規化レコードへデコードするバッチ。

- 区分: batch
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

取引パイプラインの入口。外部ホストファイルをデコードして `txn-decoded.dat` を生成する。

## Entrypoint

- `inti-decode-batch`: デコードバッチ

## Inputs

- 外部ホストファイル（`EBCDIC-FILE`）

## Outputs

- `txn-decoded.dat`（`DECODED-FILE`）
- リジェクトファイル（`REJECT-FILE`）

## Database Access

なし（ファイル I/O 中心）。

## ISAM Files

- ファイルチャネル: `EBCDIC-FILE`, `DECODED-FILE`, `REJECT-FILE`

## Messaging

なし。

## Business Rules

- EBCDIC→ASCII デコード。
- 不正レコードのリジェクト。

## Dependencies

- 観測 CALL: `SYSTEM`, `AUD-WRITE`
- manifest 依存: shared/ebc-to-ascii

## Tests / Evidence

- `subsystems/19-integrationin/tests/unit/inti-driver.cob`
- `subsystems/19-integrationin/tests/unit/inti-test.sh`

## Modernization Notes

- バッチのため `container_apps_job`。

## Risks

- 文字エンコードと不正入力の扱いが移行クリティカル。

## Open Questions

- ホストファイルの正確なレコードレイアウト定義。

