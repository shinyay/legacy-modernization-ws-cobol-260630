# ADR-0003: ループは GitHub ネイティブ（Copilot）で組む

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
多くの解説は Claude Code / Codex 前提。一方、今回は 30 日間 GitHub Copilot を使える環境がある。
GitHub には Loop Engineering の 5+1 に対応する機能が揃っており（Agentic Workflows /
Copilot automations / cloud agent / code review / MCP / Skills / Memory）、
「プラットフォーム自体をループにする」思想（Issue→PR を Actions 上で回す）が取れる。

## Decision
ループは **GitHub ネイティブ**で組む。骨格は
「プログラム1本 = 1 Issue → `@copilot`(cloud agent) が PR → 特性化テストを CI で判定 →
branch protection で green まで merge 不可」。心拍は Copilot automations / Agentic Workflows。
検査役は Copilot code review（maker / checker 分離）。state は Issues / Projects。

## Consequences
- **良い点**: 検証・セキュリティ・レビューゲートが platform 側で強制され、無人でも暴走しにくい。
  追加ツールの自前管理が少ない。Issue→PR がそのまま記録に残る。
- **悪い点 / トレードオフ**: automations / cloud agent は**有料プラン必須**・**private/internal リポジトリ限定**。
  cloud agent は 1セッション最大 59 分・1タスク=1PR → 移行は小さく分割が必要。
- **中立**: プランが限定的な間は、VS Code（agent mode＋custom agents＋skills＋MCP）＋
  Actions 手動実行で代替し、後から automations に拡張する。

## Alternatives considered
- **Claude Code / Codex でローカルにループを組む**: 情報は多いが、今回の 30 日 Copilot 環境を活かせず、
  検証・セキュリティゲートを自前で用意する必要がある。今回は不採用。

## References
- ../loop-engineering.md（セクション6〜7）
- https://github.github.com/gh-aw/
