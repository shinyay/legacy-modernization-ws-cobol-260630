# ADR-0021: gh-aw ループの engine.model 選定方針（utility tier を避け、1工程ずつ検証する）

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, Maintainer

## Context
`docs/observability/gh-aw-audit.md`（§5/§8）で、read-only な triage に frontier model（観測値 `claude-sonnet-4.6`）は重く、
安価な軽量モデルで十分かもしれない、という**改善仮説**を立てていた（ADR-0014 のコスト効率軸の具体化）。

これを検証するため `engine.model` を安価モデルへ切り替えたところ、2つのモデルが続けて実行ブロックになった
（詳細は postmortem 0002）。

- `gpt-4.1-mini` … Copilot CLI で **retired/unsupported**（即 `exitCode=1`）。
- `gpt-4o-mini` … **utility models の専用レート制限（429）** に該当。`migrate`（≈1.9M tokens）のような多ターン・多トークンの
  agentic loop では `--continue` リトライでも回復せず partial execution に陥った。

判明した力学:

- gh-aw の `engine.model` は任意名を受け付けず、**Copilot CLI がサポートする現行モデル名**である必要がある。
- Copilot のモデルには **tier** があり、**utility models** は専用の厳しいレート制限を持つ。
  無人ループ（特に migrate）は重く、utility tier では即上限に達する。
- 「安い＝小型 utility」という選び方は、サポート状況・レート制限・ワークロード重量を見落とす。

## Decision
gh-aw ループの `engine.model` 選定を次の方針に従う。

1. **utility-tier の mini モデルを無人ループに使わない**（例: `gpt-4o-mini`）。utility 専用レート制限で
   多ターン・多トークンのループが 429 / partial execution を繰り返すため。
2. **モデル名は Copilot CLI がサポートする現行名のみ**を使う（`gpt-4.1-mini` のような retired 名は即失敗）。
   サポート可否は実行ログ（audit）と gh-aw の models マップで確認する。
3. **軽量化は standard-tier の小型モデル**（当面 `gpt-5-mini`）を候補にし、**1工程ずつ**（triage → 必要なら migrate/verify）
   `gh aw audit <base> <current>` で before/after を検証してから横展開する。**全 workflow 一括変更はしない**。
4. **既定は standard/frontier（`claude-sonnet` 系）を維持**し、安価化は audit で回帰なしを確認できた工程だけに適用する。

この決定は observability §5/§8 の「軽量モデルで十分」仮説を**棄却ではなく条件付きで修正**する
（utility tier は不可。standard small tier を要検証で許可）。

## Consequences
- **良い点**:
  - 「安い＝使える」ではないことを明文化し、同種の失敗を防ぐ。
  - 1工程ずつ audit 検証する規律で、損失と切り分け困難を最小化する。
  - コスト最適化を ADR-0014 のコスト効率軸に正しく接続できる。
- **悪い点 / トレードオフ**:
  - 「全部まとめて安くする」即効性は捨てる（工程ごとの段階適用になる）。
  - standard small tier も工程によっては品質不足の可能性があり、その都度 audit が要る。
- **中立**:
  - 既定モデルは当面 standard/frontier 維持。安価化は検証済み工程に限定して進める。

## Confirmation
- `gh aw audit <base> <current>` で、対象工程に **429 / partial execution が無い**こと、かつ
  成果物（Issue / Draft PR / spec / 等価ゲート）の品質が劣化しないことを確認してから採用する。
- 採用は工程単位（まず triage）。migrate/verify への展開は個別に同じ検証を通す。

## Alternatives considered
1. **utility mini をリトライ前提で使い続ける** — 却下。429 が構造的で、無人ループの停止性・コストを悪化させる。
2. **既定を frontier 固定にして最適化しない** — 却下。ADR-0014 のコスト効率軸を放棄することになる。
3. **全 workflow を一括で standard small に切替** — 却下。検証なしの一括変更が今回の失敗の一因。1工程ずつにする。

## References
- [ADR-0014](0014-two-layer-scorecard-with-cost-efficiency.md)（2層 Scorecard ＋ コスト効率軸）
- [Postmortem 0002](../postmortems/0002-cheap-model-rate-limit.md)（安価モデル最適化の失敗）
- `docs/observability/gh-aw-audit.md`（§5 観測仮説 / §8 next steps）
