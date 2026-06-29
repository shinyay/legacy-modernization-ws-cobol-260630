#!/usr/bin/env bash
# spec-extract: COBOL ソース → 業務仕様の骨子(データ項目/処理フロー/関数) を抽出する。
#
# 使い方:
#   TS_COBOL_DIR=/path/to/tree-sitter-cobol  tools/spec-extract/extract.sh <source.cob>
#   (TS_COBOL_DIR 既定 = /tmp/ts-cobol。調査用にクローンした grammar を指す)
#
# 位置づけ:
#   真実の源は cobc golden(ADR-0005)。本抽出は Code→Doc(ADR-0009) の「構造抽出」を
#   機械化した補助であり、正しさの根拠ではない。grammar は COBOL85/固定形式専用。
set -euo pipefail

SRC="${1:?usage: extract.sh <cobol-source>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
QUERY="$HERE/queries/spec.scm"
FORMAT="$HERE/format.awk"
# 既定は vendoring した grammar (自己完結・ネット非依存・ADR-0019)。env で上書き可。
TS_COBOL_DIR="${TS_COBOL_DIR:-$HERE/vendor/tree-sitter-cobol}"

[ -f "$SRC" ]          || { echo "error: source not found: $SRC" >&2; exit 1; }
[ -f "$QUERY" ]        || { echo "error: query not found: $QUERY" >&2; exit 1; }
[ -f "$FORMAT" ]       || { echo "error: formatter not found: $FORMAT" >&2; exit 1; }
[ -d "$TS_COBOL_DIR" ] || { echo "error: grammar dir not found: $TS_COBOL_DIR (set TS_COBOL_DIR)" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FIXED="$WORK/fixed.cob"
RAW="$WORK/raw.txt"

# COPY 検出 (展開フックは未実装。題材が出たら実装する)
if grep -niE '^[^*]*\bcopy\b' "$SRC" >/dev/null 2>&1; then
  echo "warning: COPY statement found; expansion not implemented — extracted structure may be incomplete" >&2
fi

# 前処理: フリー形式(>>SOURCE FORMAT FREE) を固定形式へ正規化
#   - >> ディレクティブ行を除去
#   - *> インラインコメント行 → 固定形式コメント(7桁目 *)
#   - その他は 7スペース字下げ(8桁目=A領域)
awk '
  /^>>SOURCE FORMAT FREE/ { next }
  { line=$0; sub(/^[ \t]+/,"",line)
    if (line ~ /^\*>/)  { sub(/^\*>[ ]?/,"",line); printf "      *%s\n", line }
    else if (line=="")  { print "" }
    else                { printf "       %s\n", line } }
' "$SRC" > "$FIXED"

# vendored parser.c を必要に応じて展開 (gzip 同梱でリポ軽量化・ADR-0019)
if [ ! -f "$TS_COBOL_DIR/src/parser.c" ] && [ -f "$TS_COBOL_DIR/src/parser.c.gz" ]; then
  gunzip -c "$TS_COBOL_DIR/src/parser.c.gz" > "$TS_COBOL_DIR/src/parser.c"
fi

# tree-sitter query (grammar ディレクトリから実行)
( cd "$TS_COBOL_DIR" && tree-sitter query "$QUERY" "$FIXED" ) > "$RAW" 2>/dev/null || true

# ヘッダ + 整形出力
prog="$(basename "$SRC")"
printf '# spec skeleton (auto-extracted): %s\n\n' "$prog"
printf '> 補助情報。真実の源は cobc golden(ADR-0005)。Code→Doc(ADR-0009) の構造抽出を機械化したもの。\n\n'
awk -v fixed="$FIXED" -f "$FORMAT" "$RAW"
