# ADR-0001: 判断を ADR に記録する

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
ハッカソン（OpenCOBOL 移行）に向けて、これから設計・ツール・進め方の判断が増える。
判断の「なぜ」は会話やチャットに埋もれて消えやすく、後から / 別の人 / agent が
同じ検討を繰り返す（intent debt）。Loop Engineering でも「記憶はディスクに置く」のが原則。

## Decision
重要な判断は **ADR（Architecture Decision Record）** として `docs/adr/` に1判断1ファイルで残す。
形式は Michael Nygard 形式（Status / Context / Decision / Consequences）。連番で管理する。

## Consequences
- **良い点**: 判断の経緯が追える。agent / 人間が再導出しないで済む。レビューの土台になる。
- **悪い点 / トレードオフ**: 書く手間。形骸化のリスク（重要判断だけに絞ることで緩和）。
- **中立**: ADR は不変の履歴。覆すときは新 ADR で supersede し、古いものは欠番にせず残す。
