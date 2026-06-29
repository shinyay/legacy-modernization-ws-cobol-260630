# Modernization Scorecard — Practice Bank

> 発表用スコアカード。Score は TBD（着手前初期値）。Evidence は実ファイル/コマンドにリンクし、Risk を明記。
> 全体像: [specs/system-overview.md](../specs/system-overview.md) ／ 方針: [docs/azure-migration-strategy.md](azure-migration-strategy.md)。

| Area | Score | Evidence | Risk |
|---|---:|---|---|
| Domain understanding | TBD | specs/*.md, specs/subsystems/*.md (22) | Unknown business rules |
| Test coverage | TBD | make test-all / e2e smoke | Missing edge cases |
| Data migration risk | TBD | db/migration (V2/V3/V7) | SQL / ISAM mismatch |
| Messaging risk | TBD | RabbitMQ (20-integrationout) | Service Bus replacement later |
| Azure readiness | TBD | ACA Jobs / PostgreSQL Flex / Files | Runtime validation needed |
| Golden Master readiness | TBD | golden/current | Output diff not complete |

## スコア凡例
- 0=未着手 / 1=部分 / 2=代表縦切り完了 / 3=横展開完了。

## 更新方針
- 縦切り(19→10→11→12)疎通ごとに Score を更新し、Evidence を golden 差分・ACA 実行ログで裏付ける。
