# ADR-0009: 移行方式 = Code→Doc→Code（spec-driven, 直訳を避ける）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
COBOL→Java を直訳すると "JOBOL"（COBOL そっくりの Java）になり、**業務が分からないまま＝保守不能**で、
モダン化したのにまた塩漬けになる（comprehension / intent debt が残る）。

## Decision
直訳しない。**Code→Doc**: COBOL から業務仕様（入出力・業務ルール・エッジケース・データ定義）を `specs/<prog>.md`
に抽出 → **Doc→Code**: その Doc から idiomatic な Java を生成。Doc は **living documentation** として残す。
**振る舞いは golden、intent は Doc（verifier ＋ 人レビュー）**で二重に担保する。

## Consequences
- **良い点**: 保守可能な Java が出る。業務理解が成果物として残る（未文書化 COBOL を抱える現場に刺さる）。発表の山場。
- **悪い点 / トレードオフ**: 工程が増える → 全本フルは回らない（hero 数本にフル、他は fallback/簡略）。spec が intent を
  取りこぼす恐れ（golden で振る舞いは担保）。
- **中立**: ループ運用中は verifier/`verify.md` が周回ごとに移行判断の ADR を追記する。

## References
- docs/plan.md §3.1 / specs/
