# ADR-0027: Practice Bank は Java rewrite せず rehost コンテナで Azure 移行する

- **Status**: Proposed
- **Date**: 2026-06-29
- **Deciders**: @hagishun

## Context
README の課題は「ドメイン分析と Azure モダナイズ」で、逐語変換は不要。22 サブシステム全 Java 化は MVP 時間内に非現実的。OCESQL/COMP-3/ISAM/double-entry など高リスク資産が中核。

## Decision
本案件は **Java rewrite を MVP から除外**し、COBOL を**コンテナのまま rehost** して Azure(ACA Jobs) へ移行する。価値は **Code→Doc のドメイン分析**と**Azure 化**に置く。等価性は Golden Master で担保。長期 Refactor は hotspot(12,13,22) に限定検討。

## Consequences
- **良い点**: MVP が現実的、業務リスク最小、golden 一致が容易。
- **悪い点 / トレードオフ**: 旧資産依存が残り保守性は限定的。
- **中立**: ADR-0004/0008（rewrite優先）は cobol-examples 向け方針として併存、本案件はサブシステム軸で上書き。

## Alternatives considered
- 全 22 本 Java rewrite: 時間・リスク過大。
- AKS/関数化: MVP に過剰。

## References
- docs/azure-migration-strategy.md / ADR-0004 / ADR-0007 / ADR-0013
