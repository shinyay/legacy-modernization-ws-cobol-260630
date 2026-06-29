# ADR-0020: サンプル群の triage を hotspot-driven（v0）へ切り替える

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, COBOL Reviewer, Maintainer

## Context
当初は dependency-driven triage（CALL/COPY/copybook/job flow 依存から leaf 順を決める）を前提に `tools/deps` を導入した。

しかし現時点のサンプル群では次の制約がある。

- CALL 依存は薄く、実質的な既知エッジは `MAIN-APP -> SUB-APP` 程度
- COPY/copybook 依存もほぼ無い
- 一方で COBOL 意味論のホットスポットは複数ある
  - `redefines`, `comp`, `numval`, `unstring`, `search`
  - `json-generate`, `xml-generate`, `sort-merge`, `report-writer`, `exec-sql`

このため、v0 で dependency-driven を主軸にすると、サンプルの実態と triage 基準が乖離する。

## Decision
v0 の triage 主軸を dependency-driven から hotspot-driven に切り替える。

- `manifest.yaml` の `hotspots` を「次に検証する COBOL 意味論」の主軸に使う
- `migratable` は「移行優先度（yes/review/later）」として独立管理する
- 依存情報（`calls/copybooks/sql/files`）は補助指標として保持し、完全には捨てない
- triage の v0 既定は `status=todo` + `migratable=yes` + `kind=batch` を母集団にし、
  `trim/unstring/search/numval/comp/redefines` を先行、
  `exec-sql/report-writer/sort-merge/json-generate/xml-generate` を review 後段に置く
- `MAIN-APP` は `SUB-APP` 後に扱う

将来 v1 では、実案件資産（CALL/COPYBOOK/JCL 依存が深い）に対して dependency-driven triage を追加有効化する。

## Consequences
- **良い点**:
  - サンプル制約に正直な triage が可能になる
  - v0 で示す価値が「意味論の抽出→検証→rewrite→scorecard」に集中する
  - `manifest.yaml` が hotspot と priority の二軸で運用しやすくなる
- **悪い点 / トレードオフ**:
  - dependency-driven の本丸価値（大規模依存最適化）は v0 では十分に示せない
  - サンプルから実案件へ移る際に triage ルールの再調整が必要
- **中立**:
  - `tools/deps` と可視化スクリプトは、v0 では依存順序決定ではなく、依存の薄さ・例外・将来拡張ポイントを可視化する補助ツールとして継続利用する。v1 では CALL/COPYBOOK/JCL 依存が深い実案件資産に対して dependency-driven triage の主軸として再利用する

## Validation
このADRの妥当性は、以下の変更が最小差分で反映され、v0 の triage が hotspot-driven として説明・再現できることで確認する。

- `manifest.yaml` に hotspot 構造化フィールドを反映
- `triage.md` の選定基準を hotspot-driven v0 に更新
- `README.md` に v0 方針（hotspot-driven）を追記
- `tools/deps/render-manifest-graph.sh` / `render-all-graph.sh` で色分け可視化できる

## Alternatives considered
1. dependency-driven を v0 でも主軸のまま維持
- 却下理由: サンプル群では依存が薄く、評価軸として弱い

2. hotspot だけで運用し依存情報を捨てる
- 却下理由: v1 への橋渡し（実案件適用）を失う

## References
- [ADR-0011](0011-repository-structure.md)
- [ADR-0014](0014-two-layer-scorecard-with-cost-efficiency.md)
- [ADR-0016](0016-layer2-agent-design.md)
- [ADR-0018](0018-ai-does-not-touch-ci-program-independent-gate.md)
- [ADR-0019](0019-vendor-tree-sitter-cobol-for-spec-extract.md)
