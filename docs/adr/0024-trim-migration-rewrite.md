# ADR-0024: TRIM-FUNCTION-TEST 移行判断 — Java rewrite 採用

- **Status**: Accepted
- **Date**: 2026-06-28
- **Deciders**: Architect / Owner, COBOL Reviewer, Maintainer

## Context
`legacy/cobol-examples/trim/trim.cbl`（GnuCOBOL の `FUNCTION TRIM` デモ・**fixed-format**・依存なし leaf/batch）を
Code→Doc→Code（ADR-0009）で移行した。**固定形式 legacy を golden 等価ゲートに通した初の1本**であり、
ハーネスに per-program の `format: fixed`（`COBC_FLAGS=-fixed`）対応を追加して freeze 可能にした（commit `f86a240`）。

verifier（checker）の検証で、CI golden 等価が PASS（candidate Java == golden）し、spec intent も高品質（直訳臭なし・Risk Hotspot なし）と確認された。

## Decision
**Java rewrite**（`app/src/main/java/trim/TrimFunctionTest.java`）を採用する。**wrapper（ProcessBuilder）フォールバックは不要**。

## Rationale
- **数値演算なし** → `BigDecimal` 不要・ロジックが単純。
- **REDEFINES / OCCURS / EXEC SQL / ファイル I/O なし** → Risk Hotspot なし。
- **`FUNCTION TRIM` は SPACE（X'20'）限定** → Java で `charAt(n) == ' '` の独自実装で完全再現（`String.strip()` は Unicode 空白も除去するため不採用）。
- **`PIC X(n)` の MOVE セマンティクス**（左詰め・空白パディング）→ `pic(s, n)` helper 1 関数で再現。
- **入力非依存のデモ**（stdin 不使用・固定の 16 行出力）→ 非決定性なし。golden は 1 ケースで十分。
- **CI golden 等価 PASS**（run `28314207724`：trim を `cobc -fixed` で freeze → candidate == golden）。

## Consequences
- **良い点**:
  - 純粋ロジックで保守容易・golden で振る舞いを固定。
  - **固定形式 legacy の移行パターンを確立**（`format: fixed` ＋ rewrite）。2 本目（interest に次ぐ）の Code→Doc→Code 完全例。
- **悪い点 / トレードオフ**:
  - `FUNCTION TRIM = 0x20 限定`は規格依存（HR-1：spec の "Confirmed by source" を COBOL 2014 規格引用に昇格させるのが望ましい）。
- **中立**:
  - 入力非依存のため代表ケースは 1 本。将来 trim 対象を拡張する場合はケース追加。

## Confirmation
- **CI required check `golden-master equivalence`** が PASS（run `28314207724`：interest 2 ケース＋trim 1 ケースを実検証。**0 件 vacuous pass ではない**＝postmortem 0003 の判定原則に適合）。
- golden（`tests/trim-function-test/golden/case01.txt`）を**不変基準として commit**し、drift-guard を有効化。

## Alternatives considered
1. **wrapper（ProcessBuilder で COBOL バイナリ起動）** — 却下。rewrite で十分（本番 Java のみ・ADR-0013）。
2. **直訳（COBOL 文を逐語的に Java へ）** — 却下（ADR-0009：JOBOL 回避）。spec の intent から書く。

## References
- [ADR-0009](0009-code-to-doc-to-code-migration.md)（Code→Doc→Code）/ [ADR-0005](0005-golden-master-from-cobol-output.md)（golden）
- [ADR-0017](0017-interest-migration-rewrite.md)（interest 移行判断 — 同型の rewrite 採用）
- [ADR-0018](0018-ai-does-not-touch-ci-program-independent-gate.md)（program 非依存ゲート）
- [Postmortem 0003](../postmortems/0003-false-green-vacuous-pass.md)（偽 green を合格にしない）
- `fix(golden)`：per-program `format: fixed`（commit `f86a240`）/ PR #8
