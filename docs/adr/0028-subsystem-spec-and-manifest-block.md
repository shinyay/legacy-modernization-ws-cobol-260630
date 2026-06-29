# ADR-0028: サブシステム単位 spec と manifest subsystems ブロックを導入する

- **Status**: Proposed
- **Date**: 2026-06-29
- **Deciders**: @hagishun

## Context
実案件は粒度がサブシステム。既存 `specs/<prog>.md` と `manifest.yaml programs:` はプログラム単位で、全体像と縦切り選定に不向き。CI 等価ゲートは programs: 基準（ADR-0018）で非破壊が必要。

## Decision
`specs/system-overview.md` と `specs/subsystems/<id>-<name>.md`（12 見出しテンプレ）を導入し、`manifest.yaml` に **`subsystems:` ブロック**を追加する（programs: は温存）。全体分析は新エージェント `system-analyzer` が担う。

## Consequences
- **良い点**: 全体像と縦切り候補が台帳化、CI 非破壊、ドメイン分析が成果物として残る。
- **悪い点 / トレードオフ**: programs/subsystems 2 軸の保守。
- **中立**: 確証度は status(confirmed/inferred/unknown) で区別。

## Confirmation
manifest.yaml が YAML として parse 可能（programs 温存）、22 spec が 12 見出しを満たす。

## References
- specs/system-overview.md / specs/subsystems/ / ADR-0015 / ADR-0018
