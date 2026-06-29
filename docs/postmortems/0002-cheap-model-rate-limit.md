# Postmortem 0002: 安価モデル最適化が retired/utility rate limit で失敗した

- **Date**: 2026-06-28
- **Status**: Mitigated（方針を ADR-0021 に明文化。再検証は `gpt-5-mini` で継続）
- **Severity**: Low（無人ループの最適化実験の失敗。本番移行物・golden は不変。損失は AIC 消費のみ）
- **Author**: @hagishun（agent 実装 ＋ 人間レビュー）

## 要約
コスト最適化として gh-aw の `engine.model` を安価モデルへ切り替える検証を行ったが、
**2つのモデルが続けて実行ブロック**になり、Interest 1周の before/after 比較が取れなかった。

- `gpt-4.1-mini` … Copilot CLI で **retired/unsupported**（即 `exitCode=1`）。
- `gpt-4o-mini` … **utility models の専用レート制限（429）** に該当し、`--continue` リトライを繰り返すが回復せず partial execution。

## タイムライン
1. `docs/observability/gh-aw-audit.md` §5/§8 の改善仮説（read-only triage に frontier は重い。`gpt-4.1-mini` / `claude-haiku-4-5` で十分かも）を受けて着手。
2. `triage` / `migrate` / `verify` の frontmatter に `engine.model: gpt-4.1-mini` を**一括設定** → `gh aw compile` → push → 3本実行。
3. migrate/verify が即失敗。agent ログに `Error: model 'gpt-4.1-mini' is retired or unsupported. Did you mean 'gpt-4o-mini'?`。
4. `gpt-4o-mini` に変更 → compile → push → 再実行。
5. triage が partial_execution。ログに `CAPIError: 429 ... you've exceeded your rate limit for utility models`。`copilot-harness` が `--continue` で最大4回リトライするが回復せず（1.9M tokens 消費・大半 cache）。
6. レート制限と判断し全 run をキャンセル。実験中断。

## 影響
- Interest 1周の安価モデル before/after 比較が未取得。
- 本番移行物（`app/`）・`specs/` ・golden は**一切変更なし**（read-only ＋ safe-outputs ＋ 等価ゲート不変）。
- 失敗 run の AIC 消費（cache 中心で軽微）。

## 根本原因
1. **モデル名の有効性を未検証で投入**: `gpt-4.1-mini` は Copilot CLI のサポート外。observability doc が古い例示を載せ、それをそのまま採用した。
2. **モデルの tier を無視**: `gpt-4o-mini` は **utility models** tier で、専用の厳しいレート制限がある。多ターン・多トークン（migrate ≈ 1.9M tokens）の agentic loop では即上限に達する。
3. **一括変更**: 3 workflow を同時に未検証モデルへ変え、全実行を同時起動。切り分けが難しく損失が広がった。
4. **「安い＝小型 utility」の短絡**: コスト軸だけ見て、サポート状況・レート制限 tier・ワークロードの重さを見落とした。

## 検知
agent ログの実エラー（`retired or unsupported` → `429 utility models`）。＝モデル選定の番人は実行ログ（audit）。

## 対応（実施 / 予定）
- **ADR-0021**（Proposed）でモデル選定方針を明文化（utility tier 禁止・サポート名確認・1工程ずつ audit 検証・既定は standard 維持）。
- `docs/observability/gh-aw-audit.md` §5/§8 の古いモデル例を**実証結果で更新**（仮説は歴史として残しつつ注記）。
- workflow は **standard-tier の小型モデル `gpt-5-mini`** で、まず1工程（triage）から audit before/after を取り直す。

## 再発防止
- **モデル選定の3条件**（サポート・レート tier・ワークロード重量）を ADR-0021／observability に固定。
- **1工程ずつ検証**: 全 workflow 一括変更を禁止し、`gh aw audit <base> <current>` で回帰確認してから横展開。
- observability doc は「動くと確認したモデル名」だけを推奨に残す（retired 名を例示しない）。

## 教訓（一般化）
> **「安いモデル」は「使えるモデル」とは限らない。**
> モデル最適化は (1) サポート状況 / (2) レート制限 tier / (3) ワークロードの重さ を満たして初めて成立する。
> 最適化は1工程ずつ audit で検証し、一括適用しない。

## 関連
- ADR-0021（モデル選定方針）/ ADR-0014（2層 Scorecard ＋ コスト効率軸）。
- `docs/observability/gh-aw-audit.md`（§5 観測仮説 / §8 next steps）。
- 失敗 run: triage `28311815175` ほか（`gpt-4o-mini` で 429）。
