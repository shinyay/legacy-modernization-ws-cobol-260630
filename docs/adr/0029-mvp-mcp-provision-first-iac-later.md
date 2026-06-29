# ADR-0029: MVP は Azure MCP で構築先行、IaC(Bicep/azd) は後追い

- **Status**: Accepted
- **Date**: 2026-06-29
- **Deciders**: @hagishun

## Context
当日は時間制限が厳しい（実質 ~5h）。ADR-0007 は provisioning=Bicep/azd、MCP=診断補助としたが、Bicep を先に固めると着手が遅い。Azure MCP は本人がログイン済み（tenant 指定で稼働確認済み）で、リソース作成・確認を対話で素早く回せる。

## Decision
**MVP は Azure MCP で構築を先行**する。Container Apps env / PostgreSQL Flexible / Files / RabbitMQ の作成・疎通を MCP で即興構築し、取引記帳パイプを1本通す。**IaC(Bicep/azd) は後追い**で、動いた構成を `infra/` に写経して再現可能化する。

## Consequences
- **良い点**: 着手が速い、当日のデモ到達が現実的、MCP の実運用を見せられる。
- **悪い点 / トレードオフ**: 初期は手動＝再現性が低い。整うまで構成ドリフトの恐れ。後追いで Bicep 化が必須。
- **中立**: ADR-0007 を MVP 局面で一部見直し（provisioning=MCP先行）。安定後は Bicep/azd に回帰。

## Confirmation
取引記帳パイプが Azure 上で1本通り、golden 一致。後日 `infra/` Bicep で同等構成を再現できること。

## References
- ADR-0007 / docs/azure-migration-strategy.md / infra/main.bicep
