# Subsystem Spec — 20-integrationout

## Summary

outbox/失敗キューをドレインし、MQ へイベントを公開するバッチ。

- 区分: batch
- 信頼度: confirmed
- モダナイズ先: `container_apps_job`

## Business Role

`audit_outbox`（transactional outbox）や失敗ファイルをドレインし、`pb.events` へ公開する。

## Entrypoint

- `into-drain-queue`: キュードレイン
- `into-publish-event`: イベント公開

## Inputs

- `audit_outbox`、失敗キューファイル、UUID シードファイル

## Outputs

- MQ イベント（`pb.events`）
- テストモード用 mock 出力ファイル

## Database Access

本サブシステムソースに SQL は未検出（上流の outbox 生成を介して DB に関与）。

## ISAM Files

- ファイルチャネル: `FAILED-FILE`, `MOCK-OUT-FILE`, `UUID-FILE`

## Messaging

- トピック: `pb.events`。`rmq_pub` を介して RabbitMQ へ公開。`INTO_MOCK_BROKER` 環境変数で mock 切替。

## Business Rules

- at-least-once 公開と重複抑止。
- 公開失敗時の再試行・記録。

## Dependencies

- 観測 CALL: `INTO-PUBLISH-EVENT`, `AUD-WRITE`
- manifest 依存: 21, shared/mq-publish

## Tests / Evidence

- `subsystems/20-integrationout/tests/unit/into-driver.cob`
- `subsystems/20-integrationout/tests/unit/into-test.sh`

## Modernization Notes

- バッチのため `container_apps_job`。当面 RabbitMQ コンテナ、stretch で Service Bus。

## Risks

- at-least-once セマンティクスと重複抑止戦略を明示化すべき。

## Open Questions

- 消費側の冪等性保証（event_key）の取り決め。

