# ADR-0014: ループを2層 Scorecard（Agent Output ＋ Skill Quality）＋コスト効率軸で評価する

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun

## Context
本プロジェクトの発展論点は「高性能モデルに一発で任せる」ことではなく、**Model × Skill × Loop × Cost** の組み合わせで
**品質あたりのコスト（コスパ）を設計・評価する**ことにある。AI Agent 活用の評価軸は「どのモデルが賢いか」だけでは
不十分で、「**どのタスクを / どのモデルで / どの Skill・Instruction・Harness に載せ / どの検証 loop で / どの品質を /
いくらのコストで**」出したかを見る必要がある。

加えて、成果物だけでなく **Skill 自体の品質**も評価対象になる（ground truth 参照・実行ゲート・成果物強制・順序制約・
完了条件・逃げ道封じ）。COBOL モダナイゼーションでは ground truth = 元 COBOL の実行結果 = **Golden Master**（ADR-0005）。

外部根拠（詳細は `docs/references.md`）: GitHub Copilot の agentic harness 評価（task resolution ＋ token efficiency）、
COMPILOT 論文（compiler/実行環境の feedback で候補を改善する closed-loop 設計）、Skill 設計チェックリスト。

## Decision
評価フレームを次の **2層 Scorecard** とする。

- **Agent Output Scorecard**（成果物の品質＋効率）
  - 品質: spec coverage / golden master match / CI result / human review required / risk hotspots
  - **Efficiency（コスト）**: agent runs / token・AI credits / cost per task / fix loops / run-to-run variance
- **Skill Quality Scorecard**（Skill 自体の質）= 各 Skill が次の **6条件**を満たすこと:
  1. **ground truth** を参照しているか（COBOL は Golden Master）
  2. **gate**（実行ゲート）があるか（CI required check）
  3. **artifact** を強制しているか（spec / Java / golden を必ず出す）
  4. **order**（順序制約）があるか（Code→Doc→Code, ADR-0009）
  5. **completion criteria** が明確か（golden 一致 green）
  6. **escape-hatch control**（逃げ道封じ）があるか（golden 手書き禁止 / ADR は Proposed / 直訳禁止）

運用上の決定:
- 各 `SKILL.md` には上記 6 条件を**明記**して設計する。
- 全体の設計・評価観点を **Model × Skill × Loop × Cost** とする（loop 段階ごとに適切なモデルを選ぶ余地＝gh-aw の `engine`/`model`）。
- Scorecard の surfacing は段階的: **CI アーティファクト → PR コメント → （将来）VS Code 拡張**（コスパ可視化構想と接続）。

## Consequences
- **良い点**:
  - Skill 自体が評価可能になり、移行品質が安定する。
  - 品質だけでなくコストで統制でき、UBB / AI Credits 時代の運用設計に接続する。
  - 研究（agentic harness / COMPILOT）と接続でき、発表・ブログの説得力が上がる。
- **悪い点 / トレードオフ**:
  - 指標収集の手間（特に Efficiency）。
  - コスト計測は近似（対話 Copilot の token は非露出、ADR-0013 系の限界）。run 変動はレンジ/中央値で見る。
  - Scorecard の維持が陳腐化しないよう運用が要る。

## Confirmation
- **Review-verifiable**: 各 `SKILL.md` に Skill Quality の 6 条件が記載されているかレビュー。
- **Test-verifiable**: `verify` が Agent Output Scorecard を出力し、CI が golden を gate する（Phase 2+）。
- **Process-verifiable**: Efficiency 指標は gh-aw run / GitHub Actions から収集し、PR/アーティファクトに残す。

## Alternatives considered
1. **モデル性能だけで評価** — 不十分。コストと Skill 品質を見落とす。
2. **品質のみ（コスト無視）** — UBB 時代に運用設計できない。
3. **一発生成（closed-loop なし）** — COMPILOT 的知見と逆行し、誤りを収束させられない。

## References
> ※出典の詳細は `docs/references.md`（要確認のものを含む）。
- GitHub Copilot **agentic harness** 評価 — task resolution ＋ token efficiency / cost per task の観点。
- **COMPILOT 論文** — compiler/実行環境の feedback による closed-loop 候補改善（＝Golden Master / CI / ADR / Next Issue と同型）。
- **Skill 設計チェックリスト** — ground truth / gate / artifact / order / completion / escape-hatch（実務ヒューリスティック）。
- 関連 ADR: [0005](0005-golden-master-from-cobol-output.md)（golden＝ground truth）/ [0009](0009-code-to-doc-to-code-migration.md)（order）/ [0012](0012-use-curated-focused-skills.md)（curated skills）/ [0013](0013-java-only-production-runtime.md)（コスト計測の限界）。
