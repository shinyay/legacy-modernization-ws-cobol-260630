# ADR-0023: ループに supervisor / planner / executor / checker の役割分担を明示する

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, Maintainer

> 関連: [ADR-0016](0016-layer2-agent-design.md)（maker/checker 分離・最小権限）と [ADR-0022](0022-low-cost-models-as-bounded-workers.md)（安価モデルを bounded worker として扱う）を、**オーケストレーション層**として接続する。

## Context
ADR-0016 で maker / checker を分離し最小権限で配ること、ADR-0022 で安価モデルを「停止・再試行ポリシーを明示した bounded worker」として扱うことを決めた。

しかし、bounded worker が成立するための前提役が**暗黙**だった:

- **誰が** work を worker サイズの bounded task に**分割する**のか。
- **誰が** executor と checker を**監督し**、各ステップ後に retry / escalate / stop を**判断する**のか。

現状はこれを人間 ＋ gh-aw safe-outputs ＋ オーケストレーションするチャット agent が**混在**で担っている。
ADR-0022 の実験（postmortem 0002）では、**監督役が不在**だったために安価モデルが無断リトライ・無断キャンセルで暴走した。
＝**分割役と監督役を明示しない限り、bounded worker は機能しない**。

## Decision
ループのオーケストレーション層を **4役**で明示する。既存エージェントへ素直にマップし、欠けている2役を新設する。

| 役 | 担当 | 区分 | モデル tier（ADR-0021/0022） |
|---|---|---|---|
| **Supervisor（監督）** | **新設** `supervisor.agent.md` | 制御 | standard/frontier（判断役） |
| **Planner（作業分割）** | **新設** `planner.agent.md` | 計画 | standard/frontier（判断役） |
| **Executor（実行）** | 既存 maker（`cobol-analyzer` / `spec-extractor` / `migrator`） | 実行 | worker 可（Skill 制約された反復） |
| **Checker（結果確認）** | 既存 `verifier` | 検証 | standard/frontier（判断役） |

役割の定義:

- **Supervisor**: 制御ループの所有者。planner→executor→checker を調整し、各ステップ後に
  **「continue / retry-with-change / escalate / stop」** を判断する。**長時間処理の人間確認ゲート（ADR-0022）と escalation を所有**する。
  **自分では作業しない**（read + 調整のみ）。**auto-retry しない**（それ自体が ADR-0022 違反）。
- **Planner**: triage が選んだ 1 program（bounded unit, ADR-0011）を、executor が1つずつ実行できる
  **順序付き bounded タスク**に分解し、各タスクに **done 基準 / stop 条件** を付ける。
- **Executor**: bounded task を1つずつ実行する maker。Skill で制約されていれば安価モデル（worker）でよい。
- **Checker**: candidate == golden ＋ intent を確認する verifier。

役割分担の原則:

- triage は **macro planner**（どの program か）、planner は **micro planner**（その program をどう分割するか）。
- Supervisor は**権限を持たない**（`read / search / todo` のみ）。書き込み副作用は executor / checker と gh-aw safe-outputs に委ねる（最小権限・ADR-0016）。
- **どの役も accountable owner ではない**。最終責任は人間（Architect / Owner・COBOL Reviewer・Maintainer）。Supervisor は decision point を整理して提示するだけ。
- 小さなジョブには supervisor / planner は**過剰**。その場合は `triage → maker → verifier` の最小経路でよい（適用は段階的）。

## Operational usage
このトポロジは、全てのジョブに常時適用するものではない。ジョブの大きさ・不確実性・外部副作用の有無に応じて、最小経路と4役経路を使い分ける。

### 1. 最小経路でよいケース
以下の条件を満たす場合は、従来通り `triage → maker → verifier` でよい。

- 対象が1ファイルまたは小さな差分に閉じている
- 入力・出力・done基準が明確
- 長時間コマンドを含まない
- 外部API / rate limit / DB / GitHub Actions などの不確実性が低い
- 失敗しても部分成果の破棄・再実行が容易

例:
- `manifest.yaml` の1項目修正
- ADRの文言修正
- READMEへの短い追記
- `INTEREST` の scorecard 草案作成

### 2. 4役経路を使うケース
以下のいずれかを満たす場合は、`supervisor → planner → executor → checker` を使う。

- `spec → golden → rewrite → scorecard` のように複数段階に分かれる
- 安価モデル worker に渡すにはジョブ境界が曖昧
- 長時間コマンド、CI、GitHub Actions、DB、外部API、rate limit を含む
- 失敗時に retry / escalate / stop の判断が必要
- 複数ファイルの整合が必要
- 成果物が「それっぽい」だけでは危険で、明示的な検収が必要

例:
- `INTEREST` を COBOL から spec / golden / rewrite / scorecard まで再実行する
- `SQL-EXAMPLE` から DB interaction spec / fixture requirement / readiness scorecard を作る
- 安価モデルで複数ジョブを並列または連続実行する
- gh-aw / CI / long-running command を含む workflow を実行する

### 3. 実行フロー
4役経路では、次の順で進める。

1. **Human / Architect** が目的・対象program・成功条件を決める
2. **Supervisor** が今回4役経路を使うべきか判定する
3. **Planner** が bounded task に分割する
   - 各taskに input / output / done / stop 条件を付ける
   - model tier を割り当てる（**Supervisor が承認**）
4. **Executor** が1taskずつ実行する
   - scopeを広げない
   - stop条件に当たったら停止する
   - 429 / auth / policy / long-running uncertainty では自動再試行しない
5. **Checker** が成果物を検収する
   - golden / spec / ADR / manifest / scorecard との整合を見る
   - 不足・不一致・review item を返す
6. **Supervisor** が次の判断を行う
   - continue
   - retry-with-change
   - escalate
   - stop
7. **Human / Owner** が最終判断する

### 4. Supervisor の判断テーブル
| 状況 | Supervisor の判断 |
|---|---|
| task が done 条件を満たした | continue |
| task は done だが Human Review Required 項目が残る（例: ゼロ入力・NUMVAL 未確定） | continue ＋ review escalate（非ブロッキング・人間/COBOL Reviewer へ review item として渡す） |
| task が失敗したが原因と修正方針が明確 | retry-with-change |
| 429 / rate limit / quota | stop or escalate。自動retryしない |
| 10分級の long-running command | 人間確認。勝手にcancel/retryしない |
| auth / permission / policy error | stop and escalate |
| 出力が部分的だが有用 | partial output を保存し、人間に判断を戻す |
| worker がscopeを広げ始めた | stop |
| checker が意味論不一致を検出 | escalate or retry-with-change |

### 5. 最小単位の目安
bounded task は、安価モデル worker が1回で処理でき、失敗しても安全に止まれる単位にする。

悪い例:
- `INTEREST を全部modernizeして`
- `SQL付きCOBOLをJavaに変換して`
- `CIが通るまで直して`


良い例:
- `INTEREST の COBOL から business spec だけ抽出する`
- `INTEREST の golden test candidate だけ作る`
- `既存 Java rewrite と spec の差分だけ確認する`
- `SQL-EXAMPLE の EXEC SQL inventory だけ作る`
- `DB fixture requirement だけ抽出する`

### 6. gh-aw での実装境界
gh-aw / Copilot coding agent では、Supervisor には **論理役割**と **プロセス制御役割**の2層がある。

- **Logical Supervisor**: 1回の gh-aw invocation 内で、作業分割・状況要約・continue / retry-with-change / escalate / stop の提案を行う。これは in-prompt の役割であり、実際の process-level retry / cancel / timeout を強制できるとは限らない。
- **Process Supervisor**: GitHub Actions / harness / frontmatter knobs により、retry / `--continue` / timeout / rate limit / auth / policy error / partial execution を分類し、実際に stop / escalate / dispatch を制御する。

したがって、1回の gh-aw invocation 内では Supervisor は論理役割に留まる。厳密な監督を行うには、planner / executor / checker / supervisor を別 workflow または別 invocation に分け、safe output / artifact / GitHub object を handoff として扱う（具体的には `workflow_call.outputs` / `dispatch-workflow` / `call-workflow` / `upload-artifact`）。

実装上の対応:
- 小さなジョブでは、Logical Supervisor をプロンプト内に置くだけでよい
- 長時間処理・rate limit・CI・DB・複数ジョブ連携では、Process Supervisor を workflow / harness 側で表現する
- worker executor は `max-continuations`（Copilot engine。Claude は `max-turns`）を低くし、`max-ai-credits` / `timeout-minutes` を小さくして bounded にする
- 429 / quota / auth / policy / incomplete は自動retryせず、failure category として stop / escalate する
- partial output が有用な場合は safe output / artifact として保存し、人間または上位 supervisor に判断を戻す
- invocation 内で独自の retry / cancel 制御が必要な場合のみ、`engine.harness`（Copilot engine 限定）などの custom harness を検討する

このADRでは、まず Logical Supervisor と運用ルールを定義する。gh-aw への完全配線は段階的に行い、必要になった時点で workflow / harness 側の Process Supervisor を追加する。

### 7. ドライラン所見（INTEREST tabletop, 2026-06-28）
移行済みの `INTEREST`（manifest `status: rewritten`・正解既知）を題材に、4役フロー（§3）をテーブルトップで1周し、§3–§6 の現実妥当性を確認した（実 gh-aw は未実行＝コスト/レート制限回避）。

**実証できたこと**:
- §3 実行フロー / §6 実装境界は史実チェーン（Issue#1 → Draft PR#3 → verify）と整合。handoff（spec ファイル / PR＋golden）は摩擦なし。
- task-decomposition の **model tier 割当が機能**: 一見機械的な rewrite でも丸め tie（`570.00/1.25/1 → 7.125→7.13`）は utility が HALF_EVEN で外す箇所＝standard 必須。ADR-0021/0022 を実証。

**改善余地（playbook 切り出し時に §1/§4 へ畳み込む候補・Proposed）**:
1. **経路判定の tie-breaker（§1/§2）**: 「小さい＝最小」と「繊細 hotspot＝4役」が衝突した。*単一純関数 ＋ 繊細 hotspot ≤1 は最小経路（その hotspot を checker 重点）*、4役は multi-spec / DB / multi-file に限定する。
2. **planner の起動条件（§3）**: 既定パイプライン（analyze→spec→tests→rewrite→verify）どおりなら planner の価値は薄い。*分解が既定から逸脱する時だけ planner を起動*し、それ以外は skip。
3. **§4 に非ブロッカー行を追加（適用済み・2026-06-28）**: 「done だが Human Review Required 項目あり（例: ゼロ入力・NUMVAL 未確定）」は done でも失敗でもない。*「→ continue ＋ review escalate（非ブロッキング）」* 行を §4 に追加した。

次の検証は、未移行の leaf/batch（`trim` 等）で**実 gh-aw を1周**し、program 非依存ゲート（ADR-0018）の自動 PR 予測を実測する。

## Consequences
- **良い点**:
  - stop / retry / escalation の**所有者が決まり**、安価モデルの暴走を構造的に防ぐ（ADR-0022 の実効化）。
  - 各役が最小権限・単一責務（ADR-0016 の延長）。
  - bounded worker が機能する前提（**分割役 planner ＋ 監督役 supervisor**）が揃う。
  - Scorecard の `modelSuitability.jobClass` が役と対応づく（policy-design / bounded-repetition / long-running-ops…）。
- **悪い点 / トレードオフ**:
  - 役が増え、調整オーバーヘッドが出る。
  - 過剰適用のリスク（小ジョブには最小経路を選ぶ運用判断が要る）。
- **中立**:
  - gh-aw への完全配線は段階的。まず `.agent.md` 定義を置き、必要に応じて workflow 化する（ADR-0016 と同じ進め方）。

## Confirmation
- `.github/agents/README.md` に4役のトポロジ・最小権限・**人間責任境界**が記載されているかレビュー。
- `supervisor.agent.md` に「**auto-retry しない / 10分級は人間確認 / escalation 経路**」が明記され、ADR-0022 と整合しているか。
- `planner.agent.md` の出力タスクが全て **bounded（done / stop 条件付き）** か。

## Alternatives considered
1. **既存 triage / maker / verifier だけで回す（supervisor 無し）** — 却下。監督役の不在が ADR-0022 の暴走の原因。
2. **Supervisor に強い権限と auto-retry を与える** — 却下。ADR-0022 違反であり、人間の責任境界を侵す。
3. **単一の万能 agent に全部やらせる** — 却下。最小権限・maker/checker 分離（ADR-0016）に反する。
4. **executor / checker も新規に作る** — 却下。既存の maker / verifier と重複（ADR-0012 のキュレーション方針）。マップで足りる。

## References
- [ADR-0016](0016-layer2-agent-design.md)（maker/checker 分離・最小権限）
- [ADR-0022](0022-low-cost-models-as-bounded-workers.md)（bounded worker・停止/再試行ポリシー）
- [ADR-0021](0021-engine-model-selection-policy.md)（モデル tier 選定）
- [ADR-0014](0014-two-layer-scorecard-with-cost-efficiency.md)（Scorecard・Model suitability）
- [ADR-0011](0011-repository-structure.md)（1周 = COBOL 1本 ＝ bounded unit）
- [Postmortem 0002](../postmortems/0002-cheap-model-rate-limit.md)（監督役不在による暴走）
- `.github/skills/long-running-ops/SKILL.md`（Supervisor が従う停止ポリシー）
