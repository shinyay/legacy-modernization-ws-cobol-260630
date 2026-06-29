# ADR-0022: 安価モデルを「停止・再試行ポリシーを明示した bounded worker」として扱う

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, Maintainer

> 関連: [ADR-0021](0021-engine-model-selection-policy.md) が **どのモデルを選ぶか**（utility tier 回避・サポート名・1工程ずつ検証）を決めるのに対し、本 ADR は **安価モデルをどう運用境界づけるか**（止め方・再試行・人間確認）を決める。両者は補完関係。

## Context
昨日は高性能モデル（Opus）を多めに使い、`interest` の modernization loop と manifest / ADR / triage の整備を進めた。
今日は同種の作業を **安価モデル + Skill** で再現できるかを試した。

観察（**できた**）— Skill で十分に制約された定型作業は安価モデルでも実用になる:
- `manifest.yaml` の構造化
- hotspot / migratable の整理
- spec / golden / rewrite / scorecard の **草案**作成
- 既存成果物との差分確認

観察（**危険**）— `gh-aw` のような 10 分級の長時間処理で、安価モデルは次の挙動をした:
- 状況を落ち着いて待たない
- 勝手にキャンセルする
- 失敗原因を十分に読まずにやり直す
- 同じ操作を延々と繰り返す
- 人間に確認せず、自律的に再試行を続ける

これは postmortem 0002（`gpt-4o-mini` の 429 リトライ地獄）と同じ構造で、本質は「**どのモデルか**」だけでなく「**どう止めるか**」にある。
Agent は賢いが、**止まり方を設計しないと危ない**。

## Decision
安価モデルを **「停止・再試行ポリシーを明示した bounded worker」** として扱う。

1. **役割分担**:
   - **高性能モデル** = 方針設計・失敗分析・レビュー（不確実性が高く、判断が要る作業）。
   - **安価モデル** = Skill で十分に制約された反復作業（bounded・決定的・検証可能）。
2. **長時間・不確実な作業**（長時間コマンド / CI / GitHub Actions / DB 環境構築など）は、**安価モデルに自律リトライさせない**。
3. **Skill には「何をするか」だけでなく「いつ止まるか」「いつ人間に確認するか」を書く**。
4. **同一コマンドの自動再実行は禁止**、または明示条件付き（原因特定済み＋別条件に変更時のみ・最大回数明記）。
5. **2分以上の処理は long-running** とみなす。**10分級は人間確認なしにキャンセル・再実行しない**。
6. **観測**: Scorecard に **Model suitability**（job class × model tier × 停止挙動）を記録し、外側ループの改善材料にする。

実装の正は skill [`long-running-ops`](../../.github/skills/long-running-ops/SKILL.md)（Long-running command policy ＋ worker プロンプト）。

## Consequences
- **良い点**:
  - コスパ最大化: 重い判断は frontier、反復は worker に割り当てられる（ADR-0014 のコスト効率軸を実装）。
  - 暴走（thrash・無断リトライ・コスト浪費・無断キャンセル）を**構造的に**防げる。
  - 失敗時に**人間の判断点が必ず残る**（10分級は人間ゲート）。
- **悪い点 / トレードオフ**:
  - worker に渡す前に、Skill で停止・確認条件を書く設計コストが要る。
  - 完全自律の即効性は捨てる（長時間処理は人間確認を挟む）。
- **中立**:
  - 既定は「長時間処理は人間確認」。worker は短い bounded job に限定する。

## Confirmation
- 長時間処理を扱う各 Skill に **Long-running command policy**（停止・確認・再試行条件）が書かれているかレビュー。
- Scorecard の `modelSuitability` で、job class とモデル tier の整合・**無断リトライ 0**・人間確認の遵守を確認。
- `gh-aw` / CI のような long-running は「**実行 → ログ確認 → 人間確認 → 次**」の形で記録（postmortem 0002 の再発防止）。

## Alternatives considered
1. **安価モデルにも自律リトライを許す（上限だけ付ける）** — 却下。10分級では上限到達まで thrash し、時間・コストを浪費する。
2. **全部 frontier に寄せる** — 却下。ADR-0014 のコスト効率軸を放棄することになる。
3. **ポリシーを暗黙知のままにする** — 却下。**強制されない軸は最初に消える**（postmortem 0001 の教訓）。

## References
- [ADR-0021](0021-engine-model-selection-policy.md)（engine.model 選定方針）
- [ADR-0014](0014-two-layer-scorecard-with-cost-efficiency.md)（2層 Scorecard ＋ コスト効率）
- [ADR-0016](0016-layer2-agent-design.md)（層2 エージェント設計・最小権限）
- [ADR-0011](0011-repository-structure.md)（1周 = COBOL 1本 ＝ bounded unit）
- [Postmortem 0002](../postmortems/0002-cheap-model-rate-limit.md)（安価モデルの 429 リトライ地獄）
- `.github/skills/long-running-ops/SKILL.md`（Long-running command policy ＋ worker プロンプト）
