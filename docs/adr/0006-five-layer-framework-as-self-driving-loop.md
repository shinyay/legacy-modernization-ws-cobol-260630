# ADR-0006: 5 層フレームワーク × MCP を自走ループとして駆動する

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
前回ハッカソンの 5 層フレームワーク（Instructions / Agent / Skill / Agentic Workflow / ADR）× 各エージェント MCP
は有効だった。今回はそれを土台に、新規性を **Loop Engineering**（自分が agent をプロンプトするのをやめ、
agent をプロンプトし続ける仕組み）に置く。

## Decision
5 層を維持しつつ、**maker/checker 分離・心拍（Agentic Workflow）・記憶（Issues/Projects/ADR）**で自走ループ化する。
Connector は MCP（GitHub MCP 既定 ＋ Azure MCP）。詳細な役割は agents 層（analyzer / spec-extractor / migrator /
verifier / triage）に割り付ける。

## Consequences
- **良い点**: 役割分担が明確で、前回資産を再利用できる。検証付きなので半自動〜無人運用に耐える。
- **悪い点 / トレードオフ**: レイヤが多く初期セットアップコストがかかる。人間のレビュー帯域が並列度の天井。
- **中立**: ADR-0002/0003（Loop Engineering 採用・GitHub ネイティブ）を具体化する位置づけ。

## References
- docs/loop-engineering.md / docs/plan.md §5
