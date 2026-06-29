# gh-aw audit と Agent Scorecard

> Agentic Workflow は、動いて終わりではない。
> 実行結果を観測し、品質・リスク・コスト・手戻りを記録し、次の改善に使う。

関連 ADR: [0014](../adr/0014-two-layer-scorecard-with-cost-efficiency.md)（2層 Scorecard ＋ コスト効率）/ [0013](../adr/0013-java-only-production-runtime.md)（ライブデモなし＝CIログ・スクショで提示）/ [0016](../adr/0016-layer2-agent-design.md)（read-only agent ＋ safe-outputs）。

---

## 1. Purpose

`gh aw audit` を、Agentic Modernization Loop における **観測データの取得手段** として位置づける。

- AI Agent の実行結果は **チャットの中に消えるのではなく**、GitHub Actions の **run artifact** として残る。
- `gh aw audit <run>` は、その artifact と Actions run metadata を取得し、実行結果を分析する。
- その結果は **Agent Scorecard の入力** として利用できる。
- Scorecard は単なる報告ではなく、**model / skill / workflow optimization の材料** になる。

つまり「動いた／動かない」だけでなく、**どれだけのコスト・ターン・リスクで・どんな成果物を出したか** を毎回観測し、次の周回の改善に回す。これが「統制された自走ループ」を成立させる。

---

## 2. Data Sources

gh-aw の run に添付される主要 artifact:

| Artifact | Meaning | Used for |
|---|---|---|
| `usage` | per-run token usage | AIC calculation, token analysis |
| `aic-usage-cache` | daily AIC usage cache | daily budget guard |
| `agent` | full agent session log | turns, reasoning trace, interaction analysis |
| `safe-outputs-items` | safe-output items produced by the agent | issue / PR / other controlled outputs |
| `detection` | threat detection log | safety / policy review |
| `activation` | setup and activation log | environment / startup debugging |

`usage` artifact の実際の中身（run `28281403114` で確認）:

- `usage/agent/token_usage.jsonl` — **推論1回ごとに1行**。`model` / `input_tokens` / `output_tokens` / `cache_read_tokens` / `cache_write_tokens` / `duration_ms` ＋ `ai_credits_this_response`（そのコール分）＋ `ai_credits_total`（累積）。
- `usage/activity/summary.json` — firewall サマリ（allowed / blocked リクエスト数）。
- `usage/github_rate_limits.jsonl` — GitHub API レート制限の消費ログ。
- `aic-usage-cache/agentic-workflow-usage-cache.jsonl` — 日次 AIC 累計（上限ガード `GH_AW_MAX_DAILY_AI_CREDITS` 用）。

決め手の1行（`token_usage.jsonl` の先頭・整形）:

```json
{ "model": "claude-sonnet-4.6", "provider": "copilot",
  "input_tokens": 2724, "output_tokens": 499,
  "cache_read_tokens": 0, "cache_write_tokens": 20687,
  "duration_ms": 10129,
  "ai_credits_this_response": 9.323325, "ai_credits_total": 9.323325 }
```

`ai_credits_total` が行ごとに積み上がり、最後の値が run の AIC になる。行数が turns に対応する。

---

## 3. What gh-aw audit measures

`gh aw audit <run>` から取得できるメトリクス:

- workflow result（成功 / 失敗）
- job success / failure（ジョブ単位）
- total duration
- agent duration
- AI Credits（AIC）
- token usage（in / out / cache）
- turns（推論回数）
- safe-output result
- detection log
- heuristic recommendations（改善推奨）

注意（AIC の出どころ）:

- **AIC は外部の課金 API を直接叩いて取得するものではない。**
- Copilot API が返す **token usage** と、gh-aw の **model pricing table / AI Credits specification** に基づいて **算出** される（artifact 内の `ai_credits_*` がその算出値）。
- **Actions run metadata**（duration / job 結果 / 各ジョブのタイミング）は `gh run view` 相当の **GitHub Actions API** から取得される。
- したがって `gh aw audit` は「**run artifact と Actions metadata をローカルに集約・解析するツール**」と理解する。魔法の課金 API ではなく、**実行ログの実測＋換算**である。

> 請求の確定値は org の Copilot billing 側。AIC はトークン実測ベースの算出値で、同じ AIC 単位なのでほぼ一致する。

---

## 4. Example: triage run

```
Run: 28281403114
Workflow: triage
Result: success
Jobs: 5/5
Duration: 9.9 min
Agent duration: 7.3 min
AI Credits: 102.26 AIC
Tokens / turns: 954k / 33
Safe-output: Issue #1 created
Issue: #1 [migrate] interest
Labels: migration, loop
```

この run で確認できたこと（事実）:

- `triage` workflow が repository を **read-only** で解析した。
- `interest`（`samples/interest/interest.cob`）が migration candidate として検出された。
- `create-issue` safe-output により、prefix `[migrate]` と labels `migration, loop` 付きで Issue が作成された。
- agent 本体には write 権限を与えず、**safe-output handler 経由で制御された書き込み**ができた（read-only agent ＋ safe-outputs・ADR-0016）。
- audit により、時間・AIC・tokens・turns・safe-output が観測できた。
- 付随観測: 使用モデルは `claude-sonnet-4.6`、firewall は 273 リクエスト中 205 を blocked（egress サンドボックスが稼働）。

---

## 5. Observations

今回の audit から得られた観測（＝改善仮説。断定しない）:

> This suggests that read-only triage may not require a frontier model.
> Some data collection work may be moved to deterministic preprocessing steps.

- read-only な triage に frontier model（観測値: `claude-sonnet-4.6`）は重い可能性がある。`gpt-4.1-mini` / `claude-haiku-4-5` などの軽量モデルで十分な可能性がある。
  - **⚠️ 2026-06-28 検証で条件付き修正**: `gpt-4.1-mini` は Copilot CLI で **retired**、`gpt-4o-mini` は **utility models の 429 レート制限**に該当し無人ループ不可だった。モデル選定方針は **[ADR-0021](../adr/0021-engine-model-selection-policy.md)**、失敗の詳細は **[postmortem 0002](../postmortems/0002-cheap-model-rate-limit.md)**。軽量化は **standard-tier の `gpt-5-mini`** を1工程ずつ audit 検証する。
- turns（33）の多くがデータ収集に使われている場合、その一部は deterministic step（frontmatter の pre / post step）に寄せられる可能性がある。
- これらは **改善仮説** であり、before / after の audit 比較（`gh aw audit <base> <current>`）で検証する。

---

## 6. Relation to Agent Scorecard

| Scorecard field | Source |
|---|---|
| result | Actions run metadata |
| job status | Actions run metadata |
| duration | Actions run metadata |
| agent duration | agent job metadata |
| AI Credits | usage artifact |
| tokens | usage artifact |
| turns | agent artifact |
| safe-output result | safe-outputs-items artifact |
| detection result | detection artifact |
| recommendations | gh-aw audit analysis |
| model suitability | gh-aw audit (model) ＋ run ログ分析（ADR-0022） |

> Scorecard は手作業の感想ではなく、GitHub Actions run artifact と audit result に基づく観測データとして作る。

これは ADR-0014 の 2層 Scorecard における **コスト効率軸**（および Agent Output 軸の一部）の具体的なデータ源にあたる。

### Model suitability（ADR-0022）

Scorecard に **Model suitability** を加える。「そのモデル tier は、その job class に適切だったか」を観測する軸。

| Field | 例 | 意味 |
|---|---|---|
| `jobClass` | policy-design / failure-analysis / review / bounded-repetition / long-running-ops | この run がやった作業の種類 |
| `modelTier` | frontier / standard / utility | 使ったモデルの tier |
| `suitable` | true / false | tier が job class に合っていたか |
| `longRunningHandling` | ok / premature-cancel / blind-retry / thrash | 長時間処理の扱い方 |
| `unsanctionedRetries` | 0, 1, 2… | 原因未特定・人間確認なしの同一コマンド再実行回数 |
| `humanCheckpointsHonored` | true / false | 要確認点で人間に止まったか |

> 安価モデルは **bounded-repetition** には向くが、**long-running-ops** を任せると `thrash` / `blind-retry` が出る（postmortem 0002）。Scorecard でこれを可視化し、次の周回で job class とモデル tier を再割り当てる。

---

## 7. Relation to Skill / Workflow Optimization

- Agent Scorecard は、**1回の loop の結果** を測るもの。
- Skill / Workflow Optimization は、その Scorecard を使って `.github/agents/*.agent.md` / `.github/skills/*/SKILL.md` / `.github/workflows/*.md` を改善する **外側ループ**。
- これは **SkillOpt 的な考え方** に近い。
- ただし現段階では SkillOpt を直接組み込むのではなく、まず **Scorecard と audit data を使って改善可能な構造にする**。

```
gh-aw audit
→ Agent Scorecard
→ Failure / Cost / Risk Analysis
→ Agent / Skill / Workflow update
→ Next modernization loop
```

---

## 8. Recommended next steps

- `gh aw audit` の結果を保存する場所を決める。
  - 例: `docs/audit/<run-id>.md`
  - 例: `.agent/scorecards/<run-id>.json`
- triage workflow のモデルを軽量化するか検討する。**ただし utility-tier（`gpt-4o-mini` 等）は 429 で不可・`gpt-4.1-mini` は retired（2026-06-28 実証）**。standard-tier の `gpt-5-mini` を1工程ずつ `gh aw audit` で検証する（**[ADR-0021](../adr/0021-engine-model-selection-policy.md)** / [postmortem 0002](../postmortems/0002-cheap-model-rate-limit.md)）。
- deterministic preprocessing step を追加できるか検討する（データ収集の一部を frontmatter の step へ寄せる）。
- Scorecard schema を定義する。
- migrate workflow でも同じ audit / scorecard を取得する。
- audit 結果を **ADR-0014 / Scorecard の根拠** として参照する。

---

### 参考コマンド

- `gh aw audit <run-id>` — 単一 run の詳細レポート（Markdown）。
- `gh aw audit <run-id> --json` — 機械可読（Scorecard 自動生成の入力）。
- `gh aw audit <base> <current>` — 2 run の差分（最適化の before / after 検証）。
- `gh aw logs <workflow> --format markdown --count 10` — 複数 run の傾向・コストトレンド。
- `gh run download <run-id> -n usage` — 生の `token_usage.jsonl` 等を直接取得。
