---
name: task-decomposition
description: 'Planner 用：triage が選んだ 1 program（bounded unit）を、executor が1つずつ実行できる順序付き bounded task に分解し、各 task に input / output / done 基準 / stop 条件 / model tier を付ける。USE FOR: 4役経路の作業分割（planner・ADR-0023）。DO NOT USE FOR: program 選定（triage の macro 役）/ 実行（executor）/ 検証（checker）/ コード・spec・golden の編集。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# task-decomposition（作業分割：bounded unit → worker タスク列）

triage が選んだ **1 program**（bounded unit, ADR-0011）を、executor が1つずつ実行できる **順序付き bounded task** に分解する。
各 task に **input / output / done 基準 / stop 条件 / model tier** を付け、supervisor が実行を開始できる状態にする。
これは [ADR-0023](../../../docs/adr/0023-supervisor-planner-executor-checker-topology.md) の **Planner** の手順。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: 各 task の **done 基準は golden / spec に紐づける**（ADR-0005）。曖昧な「それっぽい完了」を作らない。
- **gate**: 全 task が **done / stop 条件付き・順序明確**で、supervisor がそのまま実行開始できること。
- **artifact**: 順序付き task リスト（Issue 本文 または `plan` artifact）。各 task に input / output / done / stop / model-tier。
- **order**: triage（macro 選定）→ **planner（micro 分割）** → executor → checker。粒度の既定は `analyze → Code→Doc(spec) → tests(inputs/cmd) → rewrite → verify`。
- **completion criteria**: 各 task が bounded（worker が1回で処理でき、失敗しても安全に止まれる）で、supervisor が承認して実行に移せる。
- **escape-hatch control**: 無限・曖昧 task を作らない（ADR-0023 §5 の悪い例「全部modernizeして」「CIが通るまで直して」）。曖昧・大きすぎるなら分割し直すか、supervisor / 人間へ確認。

## 手順

1. **入力を読む**: triage の Issue（対象 program・hotspots・I/O 仮説・受け入れ条件）。
2. **パイプライン粒度に分解**: 既定は `analyze → spec(Code→Doc) → tests(inputs/cmd) → rewrite → verify`。
   複雑なら更に分割（例: 複数 spec、DB fixture 抽出、EXEC SQL inventory、edge ケース別 golden）。
3. **各 task に条件を付ける**:
   - **input / output**（何を読み、何を出すか・パス明記）
   - **done 基準**（golden / spec に紐づく完了条件）
   - **stop 条件**（ADR-0022: 429 / auth / policy / 10分級 / 2連続失敗 → 停止して escalate）
   - **model tier**（判断系 = standard/frontier、bounded 反復 = worker。ADR-0021。**割当は supervisor が承認**）
4. **bounded か検査**: worker が1回で完了でき、失敗時に安全停止できる単位か。ADR-0023 §5 の良い例/悪い例で照合する。
5. **supervisor へ渡す**: 分割案を提示し、**承認後に実行**に移す（自分では実行しない）。

## 良い分割 / 悪い分割（ADR-0023 §5 準拠）

- ✅ `INTEREST の COBOL から business spec だけ抽出する` / `golden test candidate だけ作る` / `既存 Java rewrite と spec の差分だけ確認する`
- ❌ `INTEREST を全部 modernize して` / `SQL付き COBOL を Java に変換して` / `CI が通るまで直して`

## 品質チェックリスト

- [ ] frontmatter に `USE FOR:` / `DO NOT USE FOR:` / `compatibility`
- [ ] 全 task に **input / output / done / stop / model-tier** が付いている
- [ ] done 基準が **golden / spec に紐づく**（曖昧完了なし）
- [ ] stop 条件が ADR-0022（429/auth/policy/10分級/2連続失敗）に沿う
- [ ] 無限・曖昧 task が無い（§5 悪い例に該当しない）
- [ ] 実行は supervisor 承認後（planner は分割のみ）

## 関連

- 関連 ADR: [ADR-0023](../../../docs/adr/0023-supervisor-planner-executor-checker-topology.md)（4役・§3 実行フロー・§4 判断テーブル・§5 最小単位・§6 実装境界）/ [ADR-0022](../../../docs/adr/0022-low-cost-models-as-bounded-workers.md)（stop/retry）/ [ADR-0021](../../../docs/adr/0021-engine-model-selection-policy.md)（model tier）/ [ADR-0011](../../../docs/adr/0011-repository-structure.md)（1周 = 1本）。
- 関連 skill: `cobol-discovery-hotspot`（分割の優先・境界）/ `cobol-to-spec`・`golden-master-testing`（done 基準の根拠）/ `long-running-ops`（stop 条件の実装）。
