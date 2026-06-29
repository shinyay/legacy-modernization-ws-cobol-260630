# ADR-0026: コンテナ粒度 = サブシステム/ジョブ単位（プログラム単位にしない）

- **Status**: Proposed
- **Date**: 2026-06-29
- **Deciders**: @hagishun

## Context
実案件 Practice Bank は 22 サブシステム × 計 64 プログラム。各プログラムを 1 コンテナにすると 60+ コンテナとなり、ACA 運用・依存制御が破綻する。日次/月次フローは 22-operations が統制し、ステップ＝プログラム起動で連鎖する。

## Decision
コンテナの**デプロイ単位はジョブ/サブシステム**とする。COBOL バイナリは**共有 runtime image 1 枚**に同梱し、各プログラムは起動 `command` で切替。バッチは日次/月次/時次/取引パイプの**ジョブ単位**で ACA Jobs に集約、オンライン(04,18)のみ常駐サービス。

## Consequences
- **良い点**: コンテナ数が激減、22-operations の既存フローと一致、ビルド一元化。
- **悪い点 / トレードオフ**: image が肥大化、ステップ別スケールはしにくい。
- **中立**: 負荷分離が要れば master/txn/online で 2-3 image に分割可。

## Alternatives considered
- プログラム別コンテナ: 細粒度すぎ運用破綻。
- 単一モノリス: 取引パイプの段階制御が困難。

## References
- specs/system-overview.md / docs/azure-migration-strategy.md
