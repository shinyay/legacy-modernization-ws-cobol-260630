# ADR-0019: tree-sitter で COBOL 構造を抽出する（spec-extract）— grammar を凍結 vendoring する

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun (Architect / Maintainer)

## Context

ADR-0009 で **Code→Doc→Code**（COBOL を業務仕様に起こしてから Java へ）を定めたが、Code→Doc の「構造抽出」は手作業だった。直訳（JOBOL）回避と spec の網羅性のため、**データ項目・処理フロー・組込関数の抽出を機械化**したい。LLM にテキストではなく構造（AST）を渡すと理解の質とトークン効率が上がることは、構造ベースのコード検索（Tree-Sitter ＋ ナレッジグラフ）の先行研究でも示されている。

候補は `tree-sitter`（高速・エラー耐性・多言語のインクリメンタルパーサ）。COBOL grammar は `yutaro-sakamoto/tree-sitter-cobol`（**MIT**, COBOL85 / **固定形式専用**）。実測で素性を確認した：

- `samples/interest/interest.cob`（フリー形式）は**そのままだと全行 ERROR**。`>>SOURCE FORMAT FREE` を固定形式へ正規化すると **100% パース成功**。`FUNCTION NUMVAL` / `COMPUTE ... ROUNDED` / 編集 PIC まで構造化できる。
- `legacy/cobol-examples` の `.cbl` 24 本を前処理なしで測定 → **12/24（50%）成功**。失敗は**形式でなく機能起因**（画面制御 `SCREEN`/`CRT`/`DISPLAY LINE COL`、`EXEC SQL`、`JSON`/`XML GENERATE`、Report Writer、`SORT`/`MERGE` ＝ いずれも COBOL85 コア外）。計算・データ変換ロジックは確実に取れる。

当初は grammar を `/tmp` に git clone して検証したが、**`/tmp` は揮発し、他メンバーや CI には存在しない**。ハッカソンは複数メンバー＋CI が**同じ環境で再現**できる必要がある。

## Decision

1. **構造抽出ツール `tools/spec-extract/` を導入する。** `extract.sh`（前処理→parse→query→整形）／ `queries/spec.scm`（抽出クエリ）／ `format.awk`（Markdown 整形）。COBOL ソースから **spec 骨子**（データ項目表・処理フロー・組込関数）を出力する。フリー形式は前処理で固定形式へ正規化し、複数行文は固定形式ソースから行結合して補完する。

2. **grammar を「凍結 vendoring（gzip 同梱）」する。** `tools/spec-extract/vendor/tree-sitter-cobol/` に取り込む（upstream `e99dbdc`・MIT・出所は `UPSTREAM.md`）。巨大な生成物 `src/parser.c`(29MB) は **`parser.c.gz`(約2.2MB) として同梱**し、`extract.sh` が初回に展開する（生 `parser.c` は `.gitignore`）。**ネット非依存・CI 再現・全メンバー同一環境**を担保しつつ**リポを軽量化**。`npm` 固定ではなく vendoring を選ぶ（`legacy/` と同じ手法、golden の「凍結・自己完結」思想と一貫）。

3. **位置づけは Code→Doc（ADR-0009）の補助に限定する。** 振る舞いの正は **cobc golden（ADR-0005）**のまま。本ツールは **CI 等価ゲートに組み込まない**（ADR-0018: AI は配管を触らない／ゲートは program 非依存）。`vendor/` と `legacy/` は **改変しない source-of-truth**。

## Consequences

- **良い点**:
  - 環境構築ゼロ：clone のみで `bash tools/spec-extract/extract.sh <src.cob>` が動く（`/tmp` 不要・`npm` 不要・オフライン可）。
  - spec の**網羅性チェック**（変数・処理の取りこぼし検出）／**裏付け**（記載が実コードに在ることを機械確認）／AI への**構造材料**＝直訳回避。`interest` で `specs/interest.md` とデータ項目 9 件が**完全一致**を実証。
- **悪い点 / トレードオフ**:
  - リポジトリ **+約2.5MB**（`parser.c.gz` 2.2MB ＋ `grammar.json`/`node-types.json` 等）。展開後の生 `parser.c`(29MB) は `.gitignore` で履歴に入れない。
  - grammar は **COBOL85 / 固定形式専用** ＝ フリー形式は前処理に依存。**機能カバレッジ 50%**（画面制御・`EXEC SQL`・帳票・`JSON`/`XML` は抽出対象外。これらは golden 主体で移行）。
  - upstream 更新は**手動再 vendoring**。`COPY` 展開は未実装（検出 `warning` のみ＝題材が出たら実装）。
- **中立**:
  - 抽出できるのは構造の**存在**のみ。**意味**（丸め根拠＝half-up、エッジケース、golden 実証）は抽出不可で、**人＋golden の領域**。役割分担がむしろ明確になる。

## Confirmation

- `bash tools/spec-extract/extract.sh samples/interest/interest.cob` が **vendor 単独**（`/tmp/ts-cobol` 削除済み・ネット不要）で spec 骨子を出力し、データ項目 9 件が `specs/interest.md` と一致。生 `parser.c` を削除した状態でも **`parser.c.gz` から自動展開して動作**することを確認済み。
- CI には組み込まない手動ツール。再現性は vendor の凍結（`UPSTREAM.md` に commit 固定）で担保。

## Alternatives considered

- **npm 固定（`package.json` で version pin）**: 却下。npm レジストリ／ネット依存で、ハッカソンの即動作・オフライン・全員再現に不利。
- **軽量 vendoring（`grammar.js`＋`scanner.c` のみ＋使用時 `tree-sitter generate`）**: 却下。`generate` のひと手間と CLI バージョン差異リスク。確実性を優先し `parser.c` を同梱。
- **`/tmp` clone のまま**: 却下。揮発し、メンバー間・CI で再現しない（本 ADR の動機そのもの）。
- **別 grammar / 自作**: 却下。MIT の既存 grammar で計算ロジックは 100% 取れ、コア用途に十分。方言・現代機能は golden で担保する。

## References

- 着想: *Codebase-Memory: Tree-Sitter-Based Knowledge Graphs for LLM Code Exploration via MCP*（arXiv:2603.27277）— LLM に構造を渡す有効性。
- ツール: [`tools/spec-extract/extract.sh`](../../tools/spec-extract/extract.sh) ／ [`queries/spec.scm`](../../tools/spec-extract/queries/spec.scm) ／ [`format.awk`](../../tools/spec-extract/format.awk) ／ 出所 [`vendor/tree-sitter-cobol/UPSTREAM.md`](../../tools/spec-extract/vendor/tree-sitter-cobol/UPSTREAM.md)
- grammar: `yutaro-sakamoto/tree-sitter-cobol`（MIT, commit `e99dbdc`, COBOL85 / 固定形式）
- 関連 ADR: ADR-0005（golden master）/ ADR-0009（Code→Doc→Code）/ ADR-0013（cobc は CI/コンテナ限定）/ ADR-0015（Code→Doc spec gate）/ ADR-0016（層2 maker/checker・最小権限）/ ADR-0018（AI は配管を触らない・program 非依存ゲート）
