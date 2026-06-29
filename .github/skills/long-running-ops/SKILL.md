---
name: long-running-ops
description: '長時間・不確実な処理（gh-aw / CI / GitHub Actions / ビルド / DB 環境構築など）を安全に回すための停止・確認・再試行ポリシーと、安価モデル向け bounded worker プロンプト。USE FOR: 2分以上かかるコマンドや外部実行をエージェントが回すとき / 安価モデルを worker として使うとき。DO NOT USE FOR: ローカルで即終わる可逆操作 / 方針設計・失敗分析・レビュー（高性能モデルの仕事）。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# long-running-ops（長時間処理の「止まり方」を設計する）

長時間・不確実なコマンドを「投げて待つ」のではなく、**「いつ止まるか」「いつ人間に確認するか」「いつ再試行してよいか」を明示**して回す。
安価モデルを **bounded worker** として使うときの停止設計（ADR-0022）。Agent は賢いが、止まり方を設計しないと暴走する。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: 実行ログ（`gh aw audit <run>` / Actions ログ）。推測ではなく**失敗原因の実テキスト**を根拠にする。
- **gate**: long-running（2分以上）は **completed（success/failure 確定）or 人間確認** が gate。未確認のまま次へ進まない。
- **artifact**: 実行ごとに **run id / 結論 / 失敗原因（1行）** を記録（scorecard か作業メモ）。
- **order**: **「実行 → ログ確認 → 判断 →（必要なら）人間確認」** を厳守。analyze の前に retry しない。
- **completion criteria**: run が completed し、結論を記録できたら完了。「とりあえず再実行」では完了にしない。
- **escape-hatch control**: 同一コマンドの自動再実行禁止（明示条件下のみ）/ 失敗ログ未読での再試行禁止 / 人間確認なしのキャンセル・再実行禁止。

## Long-running command policy

1. **時間分類**
   - `< 2分`: 通常コマンド。完了を待つ。
   - `2分以上`: **long-running**。1回起動したら**待つ**。ポーリングで急かさない。
   - `10分級`（gh-aw / CI / Actions など）: **人間確認ゲート**。人間の合図なしにキャンセル・再実行しない。
2. **失敗時**
   - まず**失敗ログを最後まで読む**（`gh aw audit <run> --log-failed` 等）。
   - **失敗原因を1行で言語化**してから次の手を決める。
   - **原因未特定のままの再試行は禁止**。
3. **再試行**
   - **同一コマンドの自動再実行は禁止**。許すのは「原因が判明し、**別条件**（モデル変更・設定修正・入力修正）に変えた」ときのみ。回数上限を明示する。
   - **連続失敗が2回**続いたら**停止して人間に報告**（root cause ＋ 選択肢2〜3）。
4. **キャンセル**
   - 進行中の long-running を**勝手にキャンセルしない**。キャンセルは「明確な失敗確定」か「人間の指示」時のみ。
5. **並列**
   - 同一 concurrency group の long-running を**多重起動しない**（前の run を詰まらせ、比較も汚す）。

## 安価モデル向け Worker プロンプト（テンプレ）

> bounded worker を起動するときの system / 先頭プロンプトに貼る。スコープを1タスクに固定し、停止条件を先に与える。

```text
You are a BOUNDED WORKER. You execute ONE well-scoped task defined by the Skill
and the issue. Follow these rules without exception:

SCOPE
- Do exactly what the Skill specifies. Do not expand scope or "improve" things.
- If the task is ambiguous or not bounded, STOP and ask the human.

LONG-RUNNING COMMANDS (gh-aw, CI, GitHub Actions, builds, DB setup; 2+ minutes)
- Trigger it ONCE, then WAIT. Do not poll aggressively. Do not cancel.
- When it finishes, READ the full result/log BEFORE deciding anything.

NEVER
- Never auto-retry the same command.
- Never cancel a running job or re-run a 10-minute-class job without explicit
  human confirmation.

ON FAILURE
1. Read the failure log to the end.
2. State the root cause in ONE sentence.
3. STOP and report to the human: root cause + 2-3 options. Do not retry blindly.

STOP CONDITIONS (asking is success; thrashing is failure)
- 2 consecutive failures  -> STOP, report.
- Any 10-minute-class decision (cancel / rerun) -> STOP, ask first.
- Unsure about anything -> STOP, ask.

RECORD (per run)
- run id, conclusion (success/failure), one-line cause if failed.

OUTPUT
- The task result + a short status line: "done" OR "blocked: <reason>".
```

## 手順

1. タスクが **bounded**（1つ・スコープ明確）か確認。曖昧なら人間に確認。
2. long-running を **1回**起動 → 待つ（急かさない・キャンセルしない）。
3. 完了 → ログ/結論を読む → **run id・結論・（失敗なら原因1行）を記録**。
4. 失敗 → 原因特定 → **同一再実行せず**、条件を変えるか人間に報告。
5. **2連続失敗** or **10分級の判断** → 停止して人間確認。

## 品質チェックリスト

- [ ] frontmatter に `USE FOR:` / `DO NOT USE FOR:` / `compatibility` を書いた
- [ ] **停止条件（when to stop）** と **確認条件（when to ask human）** を明記した
- [ ] **同一コマンド自動再実行の禁止**（と明示条件）を書いた
- [ ] `2分 = long-running` / `10分級 = 人間確認ゲート` を書いた
- [ ] worker プロンプトに stop / ask / no-auto-retry ルールが入っている

## 関連

- 関連 ADR: [ADR-0022](../../../docs/adr/0022-low-cost-models-as-bounded-workers.md)（bounded worker）/ [ADR-0021](../../../docs/adr/0021-engine-model-selection-policy.md)（モデル選定）/ [ADR-0014](../../../docs/adr/0014-two-layer-scorecard-with-cost-efficiency.md)（scorecard）/ [ADR-0016](../../../docs/adr/0016-layer2-agent-design.md)（agent 設計）。
- [Postmortem 0002](../../../docs/postmortems/0002-cheap-model-rate-limit.md)（安価モデルの 429 リトライ地獄）。
- 観測: `docs/observability/gh-aw-audit.md`（Scorecard の **Model suitability**）。
