# ADR-0008: 実装 = rewrite は Java / fallback は ProcessBuilder→GnuCOBOL（JNI/FFM 不要）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
移行先言語と、fallback で COBOL を呼び出す方式を決める必要がある。COBOL の `PIC` / `COMP-3`(packed decimal)
を正しく扱えること、5h で現実的なことが要件。

## Decision
- **rewrite = Java（ネイティブ）**。API host は軽量 Java（Javalin / Spark）、数値は **BigDecimal**。
- **fallback = Java の `ProcessBuilder`** で GnuCOBOL の実行ファイルを **subprocess 起動**（入力=stdin/一時ファイル、
  出力=stdout/ファイル）。
- **JNI / FFM(Project Panama) / JNA は使わない**。`.so`(`cobc -m`) を in-process リンクすると COMP-3 の
  メモリレイアウト対応が重く、5h では不利。

## Consequences
- **良い点**: subprocess は単純で確実。Java は前回資産・enterprise 受け・BigDecimal が COMP-3 に好相性。host と
  rewrite と fallback を Java で統一できる。
- **悪い点 / トレードオフ**: Java はビルド/起動が重め（軽量 FW・最小依存・単一モジュールで緩和）。subprocess は
  1 往復前提のため interactive COBOL は工夫 or fallback 対象。
- **中立**: rewrite 先を Python にする案もあったが、host 統一の観点で Java を選択。

## References
- docs/plan.md §3 / ADR-0004
