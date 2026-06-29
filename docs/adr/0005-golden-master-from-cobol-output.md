# ADR-0005: golden master = COBOL 実行出力の固定（characterization baseline）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
COBOL 移行の正しさは「元と同じ振る舞いをするか」に尽きる。元の仕様書が無くても、COBOL を実行すれば
実挙動（=仕様の真実）が得られる。これを基準化すれば、rewrite も rehost も同じ土俵で検証できる。

## Decision
COBOL を `cobc -x` で実行した出力を `tests/<prog>/golden/` に**固定**し「正」とする（characterization test）。
候補（rewrite 版 / wrapper 版）は同じ入力で実行し、**golden と一致必須**。一致判定は CI（`ci.yml`）の
**required check** として強制し、不一致は merge をブロックする（= ループの停止条件）。
一度だけ「直接実行 == API 経由」の透過性も確認する。

## Consequences
- **良い点**: 仕様の真実が自動で得られる。rewrite の等価性と将来の回帰を同じ基準で担保。
- **悪い点 / トレードオフ**: 非決定性（日付/乱数/時刻）は正規化・マスクが必要。入力カバレッジが品質を左右。
- **中立**: golden は不変の基準。入力ケースを増やすほど検証が強くなる。

## References
- docs/plan.md §3.5 / tools/golden/ / tests/
