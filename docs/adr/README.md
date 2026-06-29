# Architecture Decision Records (ADR)

このディレクトリは、プロジェクトの重要な判断を記録する **ADR（Architecture Decision Record）** を置く場所です。

## なぜ ADR か
- **判断の「なぜ」を残す**。コードは「何を」やったかを示すが、「なぜそう決めたか」は消えやすい。
- **Loop Engineering の "memory" そのもの**。agent も人間も、毎回ゼロから判断を再導出しないで済む。
  決定をディスクに書いておけば、`AGENTS.md` / `SKILL.md` と並ぶ「明文化した意図」になる。
- 後から「この設計、なんでこうした？」に答えられる。撤回・置換の履歴も追える。

## フォーマット
Michael Nygard 形式（軽量）。1判断 = 1ファイル。
- **Status**: Proposed / Accepted / Deprecated / Superseded by ADR-XXXX
- **Context**: 背景・制約・力学（なぜ判断が必要か）
- **Decision**: 何を決めたか（能動態で言い切る）
- **Consequences**: 結果（良い点 / 悪い点 / 中立）

## 新しい ADR の足し方
> 執筆は SKILL `.github/skills/adr-authoring/` に従う（人間も agent/`verify.md` も同じ手順）。
1. `template.md` をコピー。
2. 連番を振る（次は `0026-...`）。ファイル名は `NNNN-英語のkebab-slug.md`。
3. Status を `Proposed` で書き、合意できたら `Accepted` に。
4. 既存判断を覆す場合は、古い ADR の Status を `Superseded by ADR-XXXX` にし、新 ADR に経緯を書く。
5. 下の索引に1行追加。

> 番号は付けたら**再利用しない**。撤回しても欠番のまま残す（履歴の一貫性のため）。

## 索引
| # | タイトル | Status | 日付 |
|---|----------|--------|------|
| [0001](0001-record-architecture-decisions.md) | 判断を ADR に記録する | Accepted | 2026-06-26 |
| [0002](0002-adopt-loop-engineering-for-cobol-migration.md) | COBOL 移行に Loop Engineering を採用する | Accepted | 2026-06-26 |
| [0003](0003-use-github-native-loop.md) | ループは GitHub ネイティブ（Copilot）で組む | Accepted | 2026-06-26 |
| [0004](0004-migration-strategy-rewrite-first-rehost-fallback.md) | 移行戦略 = rewrite 優先 → rehost フォールバック | Accepted | 2026-06-26 |
| [0005](0005-golden-master-from-cobol-output.md) | golden master = COBOL 実行出力の固定 | Accepted | 2026-06-26 |
| [0006](0006-five-layer-framework-as-self-driving-loop.md) | 5層 × MCP を自走ループとして駆動 | Accepted | 2026-06-26 |
| [0007](0007-deploy-to-azure-container-apps.md) | デプロイ先 = Azure Container Apps（OIDC） | Accepted | 2026-06-26 |
| [0008](0008-rewrite-java-fallback-processbuilder.md) | rewrite=Java / fallback=ProcessBuilder（JNI不要） | Accepted | 2026-06-26 |
| [0009](0009-code-to-doc-to-code-migration.md) | 移行方式 = Code→Doc→Code（直訳回避） | Accepted | 2026-06-26 |
| [0010](0010-gh-aw-loop-must-have-manual-dispatch.md) | gh-aw を必達のループ定義に（完全自動化は stretch） | Accepted | 2026-06-26 |
| [0011](0011-repository-structure.md) | リポジトリ構成（横割り・legacy不変・manifest） | Accepted | 2026-06-26 |
| [0012](0012-use-curated-focused-skills.md) | focused な Skill をキュレーションし index で運用する | Accepted | 2026-06-26 |
| [0013](0013-java-only-production-runtime.md) | 本番ランタイムは Java のみ（GnuCOBOL は CI/ビルドと fallback 限定） | Accepted | 2026-06-26 |
| [0014](0014-two-layer-scorecard-with-cost-efficiency.md) | ループを 2層 Scorecard（Agent Output ＋ Skill Quality）＋コスト効率で評価 | Accepted | 2026-06-27 |
| [0015](0015-require-code-to-doc-spec-gate.md) | Code→Doc 仕様（specs/&lt;prog&gt;.md）を必須化し CI で強制 | Accepted | 2026-06-27 |
| [0016](0016-layer2-agent-design.md) | 層2 エージェント設計（maker/checker 分離・最小権限・source-of-truth 不可侵） | Accepted | 2026-06-27 |
| [0017](0017-interest-migration-rewrite.md) | interest プログラムの移行判断 — Java rewrite を採用 | Accepted | 2026-06-27 |
| [0018](0018-ai-does-not-touch-ci-program-independent-gate.md) | AI は CI・ビルド・保護ファイルを変更しない — 等価ゲートを program 非依存に | Accepted | 2026-06-27 |
| [0019](0019-vendor-tree-sitter-cobol-for-spec-extract.md) | tree-sitter で COBOL 構造を抽出（spec-extract）— grammar を凍結 vendoring | Accepted | 2026-06-27 |
| [0020](0020-hotspot-driven-triage-for-sample-set.md) | サンプル群の triage を hotspot-driven（v0）へ切り替える | Accepted | 2026-06-28 |
| [0021](0021-engine-model-selection-policy.md) | gh-aw の engine.model 選定方針（utility tier 回避・1工程ずつ検証） | Accepted | 2026-06-28 |
| [0022](0022-low-cost-models-as-bounded-workers.md) | 安価モデルを bounded worker（停止・再試行ポリシー明示）として扱う | Accepted | 2026-06-28 |
| [0023](0023-supervisor-planner-executor-checker-topology.md) | ループに supervisor/planner/executor/checker の役割分担を明示 | Accepted | 2026-06-28 |
| [0024](0024-trim-migration-rewrite.md) | TRIM-FUNCTION-TEST 移行判断 — Java rewrite 採用 | Accepted | 2026-06-28 |
| [0025](0025-numval-test-migration-rewrite.md) | NUMVAL-TEST 移行判断 — Java rewrite 採用 | Accepted | 2026-06-28 |
| [0026](0026-container-granularity-subsystem-job.md) | コンテナ粒度 = サブシステム/ジョブ単位 | Proposed | 2026-06-29 |
| [0027](0027-practice-bank-rehost-no-java-rewrite.md) | Practice Bank は Java rewrite せず rehost コンテナ移行 | Proposed | 2026-06-29 |
| [0028](0028-subsystem-spec-and-manifest-block.md) | サブシステム単位 spec ＋ manifest subsystems ブロック導入 | Proposed | 2026-06-29 |
