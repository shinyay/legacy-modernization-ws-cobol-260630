# .github/skills/ — 層3: Agent Skills（skill index）

`<skill-name>/SKILL.md` 形式。これは **skill index（カタログ）**で、agent / 人間が「どの skill をいつ使うか」を選ぶための一覧（運用方針は [ADR-0012](../../docs/adr/0012-use-curated-focused-skills.md)）。**新しい skill を追加したら必ずこの表に 1 行足す。** 雛形は [`_TEMPLATE.md`](./_TEMPLATE.md)（コピーして埋める）。

> **frontmatter 規約**: 各 SKILL.md は `description` に **`USE FOR:`（使う合図）/ `DO NOT USE FOR:`（使わない合図）** を含め、`compatibility` を明記する（発見性・誤起動防止。microsoft/skills の品質ルーブリック準拠）。

> **Skill Quality（ADR-0014）**: 各 SKILL.md 本文に **ground truth / gate / artifact / order / completion / escape-hatch** の6条件を明記する。

| Skill | 目的 | 使うタイミング（Loop 工程） | 状態 |
|---|---|---|---|
| `adr-authoring/` | ADR を `docs/adr/` に採番・書式・索引規約どおり作成 | 決定を記録するとき（人間 / `verify.md`） | 実在 |
| `cobol-gnucobol-dialect/` | PIC / COMP-3 / 固定長 / ファイル・標準 I/O / `cobc -x` ビルド / golden 生成（**参照知識**寄り） | COBOL を読む / ビルドするとき | 実在 |
| `cobol-to-spec/` | **Code→Doc**: 業務ルール・入出力・エッジケース・データ定義を構造化 Doc に抽出 | Analyze → Code-to-Doc | 実在 |
| `cobol-discovery-hotspot/` | 依存/ホットスポットを抽出し `manifest.yaml` を更新、色分けグラフを生成 | discovery / triage 前 | 実在 |
| `golden-master-testing/` | COBOL 実行を golden に固定し、candidate と一致確認 | Golden Master → Verify | 実在 |
| `long-running-ops/` | 長時間処理（gh-aw / CI / Actions）の停止・確認・再試行ポリシー＋安価モデル worker プロンプト | 長時間コマンド実行時 / worker 運用 | 実在 |
| `task-decomposition/` | 1 program を done/stop 条件付き bounded task 列に分解（model tier 割当・planner 用） | 4役経路の作業分割（planner） | 実在 |

> 「状態」= 実在（フォルダ + SKILL.md あり） / 予定（plan のみ）。

> **curated セットの境界（ADR-0012）**: この index に載っているものが loop の正式スキル。ツリー上に存在しても **index 本掲載のスキル（実験的・spin-off 含む）は loop の curated セット外**として扱う（routing 対象にしない）。
