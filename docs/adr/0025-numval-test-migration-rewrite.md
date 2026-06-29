# ADR-0025: NUMVAL-TEST 移行判断 — Java rewrite 採用

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, COBOL Reviewer, Maintainer

## Context
`legacy/cobol-examples/numval_test/numval_test.cbl`（GnuCOBOL の `FUNCTION NUMVAL` デモ・**fixed-format**・依存なし leaf/batch）を
Code→Doc→Code（ADR-0009）で移行した。**discovery（triage）を安価モデル `gpt-5-mini` で回した初の1本**であり（run `28315044876`：**12.99 AIC**・前回 triage の約 1/8・429 なし＝ADR-0021 の検証）、
そこから `/migrate`（run `28315234160`）→ CI golden 等価 → `/verify`（run `28315696814`）まで通した。

対話 stdin から2値を読み、`PIC X(10)` を `NUMVAL` で数値化し、`PIC 9(10)` を加算した合計を **COMP-2（IEEE 754 binary64）** で表示する。
interest で Human Review に挙がっていた **NUMVAL の符号** を、本プログラムの代表ケースで等価実証できる題材である。

## Decision
**Java rewrite**（`app/src/main/java/numval/NumvalTest.java`）を採用する。**wrapper（ProcessBuilder）フォールバックは不要**。

## Rationale
- **`FUNCTION NUMVAL` ≈ `Double.parseDouble(s.trim())`**（空白除去・符号・小数点の解釈）→ Java で再現可能。
- **COMP-2（FLOAT-LONG）= Java `double`** に直接マッピング可能。
- **`PIC X(10)` の左詰め・空白パディング / `PIC 9(10)` の符号なし整数** → Java で直接表現。
- **COMP-2 の DISPLAY 表示**（GnuCOBOL の `%.16G` 相当＝末尾ゼロ・不要な小数点を除去）→ `formatComp2()` helper で手動再現。
- **fixed-format** → ハーネスの per-program `format: fixed`（`COBC_FLAGS=-fixed`）で freeze（ADR-0024 で確立したパターン）。
- **CI golden 等価 PASS**（run `28315656938`：4 ケースを freeze → candidate == golden）。

## Consequences
- **良い点**:
  - **NUMVAL の意味論（符号・小数・先頭空白・境界 0）を4ケースで等価実証**。interest で未カバーだった符号（`-5`）を含む。
  - **3 本目の Code→Doc→Code 完全例**（interest・trim に次ぐ）。
  - **discovery を `gpt-5-mini` で回した初の1本**。read-only な triage は安価モデルで十分（ADR-0021 / ADR-0022）。
- **悪い点 / トレードオフ**:
  - **COMP-2 の DISPLAY 表示は GnuCOBOL の `%.16G` 実装に依存**（HR#1）。`formatComp2()` の正確性は golden で固定するが、広い値域では追加ケースが望ましい。
  - **NUMVAL に非数値文字列（例 `"abc"`）を渡した場合の挙動**（HR#2）・**`PIC 9(10)` に非数値を渡した場合の挙動**（HR#3）は未テスト＝future work。
- **中立**:
  - サンプル集ゆえ業務価値は低く、移行優先度の根拠は「COBOL 意味論の検証知見を積む」**学習目的**と読むのが正確。

## Confirmation
- **CI required check `golden-master equivalence`** が PASS（run `28315656938`：interest 2 ＋ trim 1 ＋ **numval 4** ケースを実検証）。
  - `freeze: froze 4 case(s) for 'numval-test'` → `verify: all 4 case(s) PASS for 'numval-test' (candidate == golden)` → `equivalence gate complete`。
  - **4 件を実検証＝0 件 vacuous pass ではない**（postmortem 0003 の判定原則に適合。case02 小数＋先頭空白・case03 負号も PASS）。
- golden（`tests/numval-test/golden/case01..04.txt`）を**不変基準として commit**し、drift-guard を有効化。

## Alternatives considered
1. **wrapper（ProcessBuilder で COBOL バイナリ起動）** — 却下。rewrite で十分（本番 Java のみ・ADR-0013）。
2. **直訳（COBOL 文を逐語的に Java へ）** — 却下（ADR-0009：JOBOL 回避）。spec の intent から書く。
3. **spec-only バリデーション（移行せず spec だけ作る）** — 却下。等価ゲートまで通すことで NUMVAL/COMP-2 の検証知見が golden に残る。

## References
- [ADR-0009](0009-code-to-doc-to-code-migration.md)（Code→Doc→Code）/ [ADR-0005](0005-golden-master-from-cobol-output.md)（golden）
- [ADR-0017](0017-interest-migration-rewrite.md) / [ADR-0024](0024-trim-migration-rewrite.md)（同型の rewrite 採用・先例）
- [ADR-0018](0018-ai-does-not-touch-ci-program-independent-gate.md)（program 非依存ゲート）
- [ADR-0021](0021-engine-model-selection-policy.md)（discovery を `gpt-5-mini` で実走した検証事例）
- [Postmortem 0003](../postmortems/0003-false-green-vacuous-pass.md)（偽 green を合格にしない）
- PR #11 / Issue #10
