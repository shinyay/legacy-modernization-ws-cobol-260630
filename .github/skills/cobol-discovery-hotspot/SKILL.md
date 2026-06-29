---
name: cobol-discovery-hotspot
description: 'COBOL 資産の依存/ホットスポットを抽出し、manifest.yaml の構造化フィールド（calls/copybooks/sql/files/hotspots/migratable）と可視化グラフを更新する。USE FOR: discovery フェーズ / triage 前の台帳整備 / hotspot-driven v0 の候補整列。DO NOT USE FOR: Java 実装生成（spec-to-java）/ golden 更新（golden-master-testing）/ CI や workflow の変更。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# cobol-discovery-hotspot（discovery：依存/意味論ホットスポットの台帳化）

`tools/deps/analyze.sh` を使って COBOL 資産を静的スキャンし、`manifest.yaml` を triage 可能な形に整える。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: COBOL ソース（`legacy/` / `samples/`）と `tools/deps/analyze.sh` の抽出結果。
- **gate**: `manifest.yaml` に `calls/copybooks/sql/files/hotspots/migratable` が埋まり、`tools/deps/render-manifest-graph.sh` で可視化できる。
- **artifact**: `manifest.yaml` と `tools/deps/out/*.txt|*.mmd`（依存レポート/グラフ）。
- **order**: discovery → triage → Code→Doc → Golden → Rewrite。移行実装より前に実施する。
- **completion criteria**: v0 の候補群が `status/migratable/hotspots` で選別でき、review/later が分離されている。
- **escape-hatch control**: `legacy/` と `tests/<prog>/golden/` を変更しない。`hotspots` と `migratable` を混同しない。CI/workflow を変更しない。

## 手順

1. `tools/deps/analyze.sh --all` を実行し、CALL/COPY/EXEC SQL/ASSIGN と hotspot を抽出する。
2. `manifest.yaml` を更新する。
   - `hotspots`: 意味論リスク（例: `redefines`, `comp`, `numval`, `unstring`, `search`）
   - `migratable`: 優先度（`yes` / `review` / `later`）
   - `calls/copybooks/sql/files`: 依存情報（可能な範囲で構造化）
3. `tools/deps/render-manifest-graph.sh` と `tools/deps/render-all-graph.sh` で色分けグラフを再生成する。
4. triage 方針（`triage.md`）と矛盾しないことを確認する。

## 関連

- 関連 ADR: ADR-0011, ADR-0014, ADR-0016, ADR-0018, ADR-0019, ADR-0020
- 隣接 skill: `cobol-to-spec`, `golden-master-testing`
