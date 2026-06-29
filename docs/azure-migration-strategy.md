# Azure 移行方針 — Practice Bank（COBOL + PostgreSQL + RabbitMQ + ISAM）

> 対象: [legacy/legacy-modernization-ws-cobol-260630](../legacy/legacy-modernization-ws-cobol-260630)。全体像: [specs/system-overview.md](../specs/system-overview.md)。
> 前提: **Java rewrite は MVP 除外** / 縦切り=**取引記帳パイプライン(19→10→11→12)** / 正しさ=**Golden Master** / まず **Container Apps Jobs** 中心。

## 移行案の比較（短期 / 中期 / 長期）

| 案 | 方針 | ランタイム | データ | メッセージング | ISAM |
|---|---|---|---|---|---|
| **短期（Rehost / lift）** | COBOL をコンテナのまま ACA Jobs へ | GnuCOBOL+OCESQL コンテナ | PostgreSQL Flexible | RabbitMQ コンテナ | Azure Files マウント |
| **中期（Replatform）** | バッチを ACA Jobs cron 化、運用を Azure 化 | 共有 runtime image, Jobs | PG Flexible + 監視/HA | RabbitMQ or Service Bus 検証 | Files、一部 Blob/PG 化 |
| **長期（Refactor）** | ホットスポットのみ段階再設計 | サービス分解（必要なら言語移行） | PG 正規化/イベント化 | Service Bus + outbox | ISAM 廃止→PG/Blob |

## 評価軸スコア（◎ 良 / ○ / △ / ✕）

| 評価軸 | 短期 Rehost | 中期 Replatform | 長期 Refactor |
|---|---|---|---|
| 実装難易度 | ◎ 低 | ○ 中 | ✕ 高 |
| 業務リスク | ◎ 低（挙動不変） | ○ 中 | △ 高（再設計） |
| 検証容易性 | ◎ golden 一致が容易 | ○ | △ |
| 運用性 | △ COBOL 運用残 | ◎ cron/監視整備 | ◎ クラウドネイティブ |
| Azure 適合度 | △ コンテナ載せのみ | ○ ACA/PG/Files 適合 | ◎ Service Bus/分解 |
| 将来保守性 | ✕ 旧資産依存 | ○ | ◎ |

## 推奨ロードマップ
1. **MVP=短期 Rehost**: 取引記帳パイプを ACA Jobs で疎通、PG Flexible + Files + RabbitMQ コンテナ。golden 照合。
2. **中期**: 日次/月次/時次を Jobs cron 化、監視・HA、Service Bus PoC。
3. **長期**: 12-txnpost / 13-interestaccrual を段階再設計、MQ→Service Bus、ISAM 廃止。

## Azure マッピング（MVP）
- batch=ACA Jobs(cron) / online(04,18)=ACA常駐 / master+Flyway=init Job
- PostgreSQL→Azure DB for PostgreSQL Flexible / RabbitMQ→当面コンテナ→Service Bus / ISAM→Azure Files
- IaC=Bicep+azd、認証=Entra OIDC（ADR-0007）。**provisioning=azd、確認運用=Azure MCP**。

## 留意
- 等価性は Golden Master（COBOL 実出力）が権威。データ系(PG/ISAM)差分が最大リスク。
- 縦切り後に hotspot(12,13,22) を長期 Refactor 候補へ。
