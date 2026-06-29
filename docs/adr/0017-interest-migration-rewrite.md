# ADR-0017: interest プログラムの移行判断 — Java rewrite を採用

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun (Architect / Maintainer)

## Context

`samples/interest/interest.cob` は単利計算バッチ（元本 × 年利 ÷ 100 × 年数）で、
Phase 3 dry-run の唯一の稼働候補。ループ全体（Issue → Analyze → Code→Doc → Golden → Rewrite → Verify → ADR）を
ハッカソン本番前に 1 周実証するためのアンカープログラム。

リスクは数値丸め（`ROUNDED` = NEAREST-AWAY-FROM-ZERO）と編集表示（`PIC Z,ZZZ,ZZ9.99`）の 2 点に限定され、
`COMP-3` / `REDEFINES` / `OCCURS` / 外部 I/O はない。
golden case02（570.00 / 1.25 / 1 → INTEREST 7.13）で half-up 丸めを実証済み。

## Decision

`interest` プログラムの移行方式として **Java rewrite** を採用する。

- 実装: `app/src/main/java/interest/Interest.java`（package `interest`）
- ビルド: `mvn -f app/pom.xml compile`（Maven、Java 21）
- 実行: `java -cp app/target/classes interest.Interest`（`tests/interest/cmd` と一致）
- 数値: `BigDecimal` + `RoundingMode.HALF_UP`（COBOL `ROUNDED` = NEAREST-AWAY-FROM-ZERO の実装）
- 編集表示: `DecimalFormat("#,##0.00")` + 12 文字右詰めパディング

wrapper フォールバック（`ProcessBuilder` で COBOL を subprocess 実行）は不要と判断。
プログラムが単純かつ golden 一致が確認できるため、本番ランタイムは純粋 Java のみとする（ADR-0013）。

## Consequences

- **良い点**:
  - 外部 GnuCOBOL ランタイムへの依存がなく、本番コンテナが軽量になる
  - `BigDecimal` + `HALF_UP` によって丸めの意図が明示的にコードに現れる
  - CI required check `golden-master equivalence (interest)` が green であれば等価性が担保される
  - ループの全工程（Analyze → Spec → Golden → Rewrite → Verify → ADR）を 1 周実証できる

- **悪い点 / トレードオフ**:
  - `NUMVAL` の非数値・空入力時の挙動（golden 未確定）はエッジケースとして残る
  - ゼロ入力時の編集表示も golden 未確認（通常運用では問題なし）
  - `interest` は単純プログラムのため、より複雑な COBOL（`REDEFINES` / `COMP-3` / 固定長 I/O）での
    rewrite 成功を保証しない

- **中立**:
  - `samples/interest/interest.cob` は `legacy/` ではなくサンプルディレクトリにあり、
    hackathon 当日支給 COBOL とは別管理。`manifest.yaml` に `path: samples/interest/interest.cob` として登録。
  - `samples/interest/java/Interest.java` はリファレンス実装として残す（本番コードは `app/` が正）

## Confirmation

- CI required check: `golden-master equivalence (interest)` — `tools/golden/verify interest` が green であること
- ADR が `Accepted` に昇格する条件: Architect が PR レビューで golden check green を確認

## Alternatives considered

- **wrapper（ProcessBuilder + COBOL subprocess）**: プログラムが単純なため採用しない。
  GnuCOBOL を本番コンテナに含めるコストが riskに見合わない（ADR-0013 参照）。
- **直訳（JOBOL）**: ADR-0009 で禁止。Code→Doc→Code を経由した。

## References

- COBOL ソース: [`samples/interest/interest.cob`](../../samples/interest/interest.cob)
- 業務仕様: [`specs/interest.md`](../../specs/interest.md)
- golden（不可侵）: [`tests/interest/golden/`](../../tests/interest/golden/)
- Production Java: [`app/src/main/java/interest/Interest.java`](../../app/src/main/java/interest/Interest.java)
- ADR-0004（rewrite 優先）/ ADR-0005（golden master）/ ADR-0008（fallback）/ ADR-0009（Code→Doc→Code）/ ADR-0013（Java only 本番）/ ADR-0015（spec gate）
