# ADR-0002: COBOL 移行に Loop Engineering を採用する

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
OpenCOBOL を移行するハッカソンに向けて進め方を決めたい。
Addy Osmani の "Loop Engineering"（自分が agent をプロンプトするのをやめ、
agent をプロンプトし続ける仕組み＝ループを設計する）を試したい。
COBOL 移行は本数が多く反復的で、振る舞い等価性の検証が要——という性質がループと相性が良い。

## Decision
移行の進め方として Loop Engineering を採用する。ループの構成は 5+1:
Automations（心拍）/ Worktrees（隔離）/ Skills / Connectors(MCP) / Sub-agents（maker・checker）
＋ Memory（state）。検証（特性化テスト = golden master）を `/goal` 的な停止条件の中心に据える。
進め方は「自動化を作り込む前に、まず1本のプログラムで手動1サイクルを通す」を原則とする。

## Consequences
- **良い点**: 反復作業を仕組みに載せられる。検証を中心化でき、品質ゲートが明確になる。
- **悪い点 / トレードオフ**: ループ設計コスト。トークン / Actions 消費。検証が甘いと無人で誤りも量産。
- **中立**: レビュー帯域（人間）が並列度の天井。理解の腐敗（comprehension debt）に常に注意。

## References
- ../loop-engineering.md
- https://addyosmani.com/blog/loop-engineering/
