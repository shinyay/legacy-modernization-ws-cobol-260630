# ADR-0004: 移行戦略 = rewrite 優先 → rehost フォールバック（1パス・golden gate）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
ハッカソン当日は実質 ~5h、移行元 COBOL は当日支給。全プログラムを別言語へ rewrite するのは時間・バグの
リスクが大きい。一方で「そのまま包む（rehost）」だけでは “移行” の技術的見せ場が弱い。両者の良いとこ取りが要る。

## Decision
各 COBOL 1 本につき、**rewrite(Java) を優先**し、試行 budget（短め）内に golden を通らなければ
**rehost（COBOL をそのまま包む）にフォールバック**する。すべての候補は **golden master でゲート**する。
解析〜判定を **1 パスに統合**（分析は 1 回だけ）。

## Consequences
- **良い点**: 速く、かつ必ず「動くデプロイ」が出る。移行成功例と安全フォールバック例の両方を発表で見せられる。
- **悪い点 / トレードオフ**: maker に試行 budget 管理が必要。rewrite が落ちる本はやり直しコスト。
- **中立**: rewrite/fallback の比率は当日の支給ソース次第。

## Alternatives considered
- rehost 一本（確実だが “移行” 感が薄い）／ rewrite 一本（高リスク、5h で全通しない恐れ）。→ ハイブリッドを採用。

## References
- docs/plan.md §3, §4
