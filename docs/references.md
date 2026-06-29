# 外部根拠・参考文献

設計判断（特に評価フレーム ADR-0014・golden master ADR-0005・skills ADR-0012）の外部根拠をまとめる。
※ 一部は出典の詳細（著者・年・URL）が未確認。確定したら追記する（**要確認**と明記）。

## Closed-loop でコードを収束させる
- **COMPILOT 論文** — LLM に最終成果物を一発生成させるのではなく、**compiler / 実行環境の feedback** を受けながら
  候補を改善する closed-loop 設計。本プロジェクトの `Golden Master → CI → ADR → Next Issue` ループと同じ思想。
  （出典詳細＝**要確認**）

## エージェント評価（品質 × 効率）
- **GitHub Copilot agentic harness 評価** — 単純なモデル性能だけでなく、**task resolution（解決率）と token efficiency
  （トークン効率 / cost per task）** の両方を見る考え方。Agent Scorecard の Efficiency 軸・UBB / AI Credits 接続の根拠。
  （出典詳細＝**要確認**）

## Skill の品質チェックリスト
- **Skill 設計チェックリスト**（実務ヒューリスティック / Qiita 等）— Skill を次の観点で評価:
  ground truth 参照 / 実行ゲート / 成果物強制 / 順序制約 / 完了条件 / 逃げ道封じ。
  → ADR-0014 の Skill Quality Scorecard（6条件）の整理に使用。一次根拠ではなく**ヒューリスティック**として扱う。

## Skill 系の研究知見（ADR-0012 参照）
- **SkillsBench / SkillLearnBench / SkillRet / SkillVetBench** — curated / focused skills の有効性、retrieval cost、
  self-generated / comprehensive skills のリスク、multi-agent の安全性。（ベンチ名のみ、URL ＝ **要確認**）

## tree-sitter による構造抽出（ADR-0019）
- **Codebase-Memory**（Vogel et al., *Tree-Sitter-Based Knowledge Graphs for LLM Code Exploration via MCP*, arXiv:2603.27277, 2026） —
  tree-sitter で 66 言語をパースしコード構造をナレッジグラフ化、MCP で LLM に公開。**トークン 1/10・ツール 2.1 分の1 で品質 90%**（0.83 vs 0.92）。
  spec-extract（COBOL 構造抽出）と grammar 凍結 vendoring の着想元。要約ノート → [papers/codebase-memory-tree-sitter-mcp.md](papers/codebase-memory-tree-sitter-mcp.md)。
- **tree-sitter**（Max Brunsfeld, 2018, Strange Loop） — 高速・エラー耐性・インクリメンタルなパーサ生成系。エディタ統合コード解析のデファクト。

## 関連 ADR
- 0005（golden master = ground truth）/ 0009（Code→Doc→Code = order）/ 0012（curated skills）/
  0013（コスト計測の限界）/ 0014（2層 Scorecard＋効率）/ 0019（tree-sitter 構造抽出・vendoring）。
