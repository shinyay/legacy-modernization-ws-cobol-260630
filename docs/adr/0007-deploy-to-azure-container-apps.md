# ADR-0007: デプロイ先 = Azure Container Apps（Bicep + azd, Entra OIDC）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
当日は Azure にデプロイする。支給 COBOL が batch かサービスかは不明。チームの Azure 権限が
「いつも特定の人しか作れない」ボトルネックになりがち。

## Decision
**Azure Container Apps** を採用（service = API 公開 / batch = Job の両対応）。IaC は **Bicep**、デプロイは
**azd / `deploy.yml`**、認証は **Entra ID OIDC フェデレーション（secretless）**。
**Azure デプロイは MCP 非依存**（確実な経路は `deploy.yml`）。Azure MCP は手元補助・診断に使う。

## Consequences
- **良い点**: batch/service 両対応。**OIDC で他メンバーは Azure 権限不要**（PR merge → Actions が deploy）。`azd up` で再現可能。
- **悪い点 / トレードオフ**: 事前にサブスク/RBAC/OIDC フェデレーションの設定が必要。Azure 課金（停止/削除を runbook に）。
- **中立**: Azure MCP の自律ループ内利用は stretch（ADR-0010）。

## Alternatives considered
- App Service（Java はシンプルだが batch 柔軟性低）／ Functions（イベント駆動限定）／ AKS（5h には過剰）。

## References
- docs/plan.md §6 (Phase 3.5) / infra/ / azure.yaml
