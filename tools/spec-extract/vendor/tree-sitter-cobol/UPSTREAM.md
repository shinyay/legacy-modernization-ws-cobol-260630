# Provenance — tools/spec-extract/vendor/tree-sitter-cobol

- **Source**: https://github.com/yutaro-sakamoto/tree-sitter-cobol
- **Upstream commit**: `e99dbdc3d800d5fa2796476efd60af91f6b43d93` (2024-12-17 10:09:16 +0900)
- **Imported**: 2026-06-27
- **License**: **MIT** — see `LICENSE` in this directory (retained verbatim).
- **Grammar**: COBOL85 / 固定形式専用（フリー形式は `extract.sh` が前処理で正規化）。

## 方針（ADR-0019）
- **凍結 vendoring（gzip 同梱）**: 巨大な生成物 `src/parser.c`(29MB) は **`parser.c.gz`(約2.2MB) として同梱**し、`extract.sh` が初回に展開する。**ネット非依存・CI 再現・全メンバー同一環境**を担保しつつ**リポを軽量化**。`npm install` も外部取得も不要で、clone すれば（tree-sitter CLI 前提で）動く。
- **取り込んだもの**: `grammar.js` / `src/{parser.c.gz, scanner.c, grammar.json, node-types.json, tree_sitter/}` / `queries/` / `LICENSE` / `package.json` / `README.md`。生 `parser.c` は `.gitignore`（展開生成物・履歴に入れない）。
- **除外**: `test/` `sample/` `bindings/` `Cargo.*` `binding.gyp` `.github/` `*.lock`（parse/query に不要）。
- **不可侵**: ここは upstream の source-of-truth。**改変しない**。更新するときは upstream から再 import し、本ファイルの commit を更新する（`legacy/` と同じ運用）。

## 位置づけ
- 用途は **Code→Doc（ADR-0009）の構造抽出の補助**のみ。
- **正しさの源は cobc golden（ADR-0005）**。本 grammar による抽出は spec の裏付け・網羅性チェックであり、振る舞いの正ではない。
