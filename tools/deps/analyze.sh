#!/usr/bin/env bash
# deps/analyze.sh — COBOL 依存の静的スキャン
#
# 抽出対象:
# - PROGRAM-ID
# - CALL
# - COPY
# - EXEC SQL
# - ASSIGN ...
#
# 出力:
# 1) サマリ
# 2) 既知プログラム間依存の Mermaid
# 3) 葉優先(依存先優先)の移行順序
# 4) 主要ホットスポット
set -euo pipefail

ROOT="$(CDPATH= cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

MANIFEST="manifest.yaml"
SCAN_ALL=0

usage() {
  cat <<'USAGE'
Usage:
  tools/deps/analyze.sh [--manifest <path>] [--all]

Options:
  --manifest <path>   manifest file (default: manifest.yaml)
  --all               ignore manifest scope, scan all *.cob/*.cbl/*.cpy under repo
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --manifest)
      [ "$#" -ge 2 ] || { echo "error: --manifest requires a path" >&2; exit 1; }
      MANIFEST="$2"
      shift 2
      ;;
    --all)
      SCAN_ALL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FILES="$TMP/files.txt"
META="$TMP/meta.tsv"
RAW="$TMP/raw.tsv"

: > "$FILES"
: > "$META"
: > "$RAW"

if [ "$SCAN_ALL" -eq 1 ]; then
  find . \( -name '*.cob' -o -name '*.cbl' -o -name '*.cpy' \) -type f | sed 's#^\./##' | sort -u > "$FILES"
else
  if [ ! -f "$MANIFEST" ]; then
    echo "error: manifest not found: $MANIFEST" >&2
    exit 1
  fi

  awk '
    $1=="-" && $2=="name:" { name=toupper($3); path=""; kind="" }
    $1=="path:"            { path=$2 }
    $1=="kind:"            { kind=tolower($2) }
    $1=="tests:" {
      if (name != "") {
        print "M_NAME\t" name
        if (path != "") print "M_PATH\t" path "\t" name
        if (kind != "") print "M_KIND\t" name "\t" kind
      }
    }
  ' "$MANIFEST" > "$META"

  awk -F '\t' '$1=="M_PATH"{print $2}' "$META" | sort -u > "$FILES"
fi

if [ ! -s "$FILES" ]; then
  echo "deps/analyze: no input files"
  exit 0
fi

# 先に manifest 由来のプログラム名/種別を混ぜる（PROGRAM-ID が無い場合にもノードを残す）。
if [ -s "$META" ]; then
  awk -F '\t' '
    $1=="M_NAME" { print "PROGRAM\t" $2 "\t(manifest)" }
    $1=="M_KIND" { print "KIND\t" $2 "\t" $3 }
  ' "$META" >> "$RAW"
fi

while IFS= read -r f; do
  [ -f "$f" ] || continue

  manifest_name=""
  manifest_kind=""
  if [ -s "$META" ]; then
    manifest_name="$(awk -F '\t' -v p="$f" '$1=="M_PATH" && $2==p {print $3; exit}' "$META")"
    if [ -n "$manifest_name" ]; then
      manifest_kind="$(awk -F '\t' -v n="$manifest_name" '$1=="M_KIND" && $2==n {print $3; exit}' "$META")"
    fi
  fi

  awk -v file="$f" -v mname="$manifest_name" -v mkind="$manifest_kind" '
    function emit_unique(tag, prog, val, key) {
      key = tag SUBSEP prog SUBSEP val
      if (!seen[key]) {
        seen[key] = 1
        print tag "\t" prog "\t" val "\t" file
      }
    }
    function add_hotspot(kind, key) {
      key = "HOT" SUBSEP prog SUBSEP kind
      if (!seen[key]) {
        seen[key] = 1
        print "HOTSPOT\t" prog "\t" kind "\t" file
      }
    }
    function norm_token(s) {
      gsub(/^\"+|\"+$/, "", s)
      gsub(/^\047+|\047+$/, "", s)
      gsub(/\.$/, "", s)
      gsub(/^[^A-Z0-9_.-]+/, "", s)
      gsub(/[^A-Z0-9_.-]+$/, "", s)
      return toupper(s)
    }
    BEGIN {
      prog = ""
      if (mname != "") {
        prog = toupper(mname)
        print "PROGRAM\t" prog "\t" file
        if (mkind != "") print "KIND\t" prog "\t" tolower(mkind)
      }
      in_exec_sql = 0
    }
    {
      raw = $0
      gsub(/\r/, "", raw)

      # fixed-format comment (7桁目 *)
      if (length(raw) >= 7 && substr(raw, 7, 1) == "*") next

      line = raw
      sub(/^[[:space:]]+/, "", line)
      # free-format full-line comment
      if (line ~ /^\*>/) next

      u = toupper(raw)
      uq = u
      # シングルクォートをダブルクォートへ寄せ、CALL/ASSIGN 抽出を簡略化する。
      gsub(/\047/, "\"", uq)

      if (match(u, /PROGRAM-ID[[:space:]]*\.[[:space:]]*[A-Z0-9_-]+/)) {
        tok = substr(u, RSTART, RLENGTH)
        sub(/^PROGRAM-ID[[:space:]]*\.[[:space:]]*/, "", tok)
        prog = tok
        print "PROGRAM\t" prog "\t" file
        if (mkind != "") print "KIND\t" prog "\t" tolower(mkind)
      }
      if (prog == "") next

      if (u ~ /EXEC[[:space:]]+SQL/) {
        in_exec_sql = 1
        add_hotspot("exec-sql")
      }
      if (in_exec_sql && u ~ /END-EXEC/) {
        in_exec_sql = 0
      }

      if (u ~ /SCREEN[[:space:]]+SECTION/ ||
          u ~ /DISPLAY[[:space:]].*\b(LINE|COL|COLUMN)\b/ ||
          u ~ /ACCEPT[[:space:]].*\b(AT|LINE|COL|COLUMN)\b/) {
        add_hotspot("screen-io")
      }
      if (u ~ /REPORT[[:space:]]+SECTION/ || u ~ /(^|[[:space:]])RD[[:space:]]/) {
        add_hotspot("report-writer")
      }
      if (u ~ /(^|[[:space:]])SORT[[:space:]]/ || u ~ /(^|[[:space:]])MERGE[[:space:]]/) {
        add_hotspot("sort-merge")
      }
      if (u ~ /JSON[[:space:]]+GENERATE/) add_hotspot("json-generate")
      if (u ~ /XML[[:space:]]+GENERATE/)  add_hotspot("xml-generate")

      if (match(u, /COPY[[:space:]]+[A-Z0-9_.-]+/)) {
        tok = substr(u, RSTART, RLENGTH)
        sub(/^COPY[[:space:]]+/, "", tok)
        emit_unique("COPY", prog, norm_token(tok))
      }

      if (match(uq, /CALL[[:space:]]+\"[A-Z0-9_-]+\"/)) {
        tok = substr(uq, RSTART, RLENGTH)
        sub(/^CALL[[:space:]]+\"/, "", tok)
        sub(/\"$/, "", tok)
        emit_unique("CALL", prog, norm_token(tok))
      } else if (match(u, /CALL[[:space:]]+[A-Z0-9_-]+/)) {
        tok = substr(u, RSTART, RLENGTH)
        sub(/^CALL[[:space:]]+/, "", tok)
        token = norm_token(tok)
        if (token != "USING") emit_unique("CALL", prog, token)
      }

      if (match(uq, /ASSIGN([[:space:]]+TO)?[[:space:]]+[A-Z0-9_\".-]+/)) {
        tok = substr(uq, RSTART, RLENGTH)
        sub(/^ASSIGN([[:space:]]+TO)?[[:space:]]+/, "", tok)
        emit_unique("ASSIGN", prog, norm_token(tok))
      }
    }
  ' "$f" >> "$RAW"
done < "$FILES"

awk -F '\t' '
  function add_node(n) {
    if (n == "") return
    if (!(n in has_node)) {
      has_node[n] = 1
      nodes[++node_n] = n
    }
  }
  function add_edge(a, b, key) {
    key = a SUBSEP b
    if (!edge_seen[key]) {
      edge_seen[key] = 1
      from[++edge_n] = a
      to[edge_n] = b
      outdeg[a]++
      indeg[b]++
    }
  }
  function add_unknown(a, b, key) {
    key = a SUBSEP b
    if (!unknown_seen[key]) {
      unknown_seen[key] = 1
      unknown_from[++unknown_n] = a
      unknown_to[unknown_n] = b
    }
  }
  function add_hot(a, b, key) {
    key = a SUBSEP b
    if (!hot_seen[key]) {
      hot_seen[key] = 1
      hot_list[a] = hot_list[a] (hot_list[a] == "" ? "" : ",") b
      hot_count[a]++
    }
  }
  function yn(v) { return v ? "yes" : "no" }
  {
    if ($1 == "PROGRAM") {
      add_node($2)
      if ($3 != "" && file_of[$2] == "") file_of[$2] = $3
    } else if ($1 == "KIND") {
      kind[$2] = $3
      add_node($2)
    } else if ($1 == "CALL") {
      caller = $2
      callee = $3
      call_from[$2 SUBSEP $3] = 1
      add_node(caller)
      raw_calls[++raw_call_n] = caller SUBSEP callee
    } else if ($1 == "COPY") {
      ckey = $2 SUBSEP $3
      if (!copy_seen[ckey]) {
        copy_seen[ckey] = 1
        copy_list[$2] = copy_list[$2] (copy_list[$2] == "" ? "" : ",") $3
        copy_count[$2]++
      }
    } else if ($1 == "ASSIGN") {
      akey = $2 SUBSEP $3
      if (!assign_seen[akey]) {
        assign_seen[akey] = 1
        assign_list[$2] = assign_list[$2] (assign_list[$2] == "" ? "" : ",") $3
        assign_count[$2]++
      }
    } else if ($1 == "HOTSPOT") {
      add_hot($2, $3)
    }
  }
  END {
    for (i = 1; i <= raw_call_n; i++) {
      split(raw_calls[i], parts, SUBSEP)
      a = parts[1]
      b = parts[2]
      if (has_node[b]) add_edge(a, b)
      else add_unknown(a, b)
    }

    print "# dependency analysis"
    print ""
    print "scanned programs: " (node_n + 0)
    print "known call edges: " (edge_n + 0)
    print "unknown/dynamic calls: " (unknown_n + 0)
    print ""

    print "## graph (known program-to-program calls)"
    print "```mermaid"
    print "flowchart LR"
    if (edge_n == 0) {
      for (i = 1; i <= node_n; i++) print "  " nodes[i] "[\"" nodes[i] "\"]"
    } else {
      for (i = 1; i <= node_n; i++) print "  " nodes[i] "[\"" nodes[i] "\"]"
      for (i = 1; i <= edge_n; i++) print "  " from[i] " --> " to[i]
    }
    print "```"
    print ""

    print "## migration order (leaf-first: dependencies first)"
    for (i = 1; i <= node_n; i++) {
      n = nodes[i]
      alive[n] = 1
      out2[n] = outdeg[n] + 0
    }
    for (i = 1; i <= edge_n; i++) active[i] = 1

    remain = node_n
    step = 0
    while (remain > 0) {
      batch = ""
      batch_n = 0
      for (i = 1; i <= node_n; i++) {
        n = nodes[i]
        if (alive[n] && out2[n] == 0) {
          batch_nodes[++batch_n] = n
        }
      }
      if (batch_n == 0) {
        for (i = 1; i <= node_n; i++) {
          n = nodes[i]
          if (alive[n]) {
            batch_nodes[++batch_n] = n
            cycle_break = 1
            break
          }
        }
      } else {
        cycle_break = 0
      }

      step++
      printf "%d. ", step
      for (i = 1; i <= batch_n; i++) {
        n = batch_nodes[i]
        if (i > 1) printf ", "
        printf "%s", n
      }
      if (cycle_break) printf "  (cycle or unresolved mutual dependency detected)"
      print ""

      for (i = 1; i <= batch_n; i++) {
        n = batch_nodes[i]
        if (!alive[n]) continue
        alive[n] = 0
        remain--
        for (e = 1; e <= edge_n; e++) {
          if (active[e] && to[e] == n) {
            p = from[e]
            if (alive[p] && out2[p] > 0) out2[p]--
            active[e] = 0
          }
        }
      }
      delete batch_nodes
    }
    print ""

    if (unknown_n > 0) {
      print "## unknown or external calls"
      for (i = 1; i <= unknown_n; i++) {
        printf "- %s -> %s\n", unknown_from[i], unknown_to[i]
      }
      print ""
    }

    print "## program summary"
    print "program\tkind\tdeps(out)\tcalled_by(in)\thotspots\tmigratable\tcopybooks\tassigns"
    for (i = 1; i <= node_n; i++) {
      n = nodes[i]
      k = (kind[n] == "" ? "unknown" : kind[n])
      d = outdeg[n] + 0
      indegree_n = indeg[n] + 0
      h = (hot_list[n] == "" ? "-" : hot_list[n])
      c = (copy_list[n] == "" ? "-" : copy_list[n])
      a = (assign_list[n] == "" ? "-" : assign_list[n])

      # 単純な移行可否ヒューリスティクス
      migratable = "yes"
      if (k == "interactive") migratable = "review"
      if (h ~ /exec-sql|screen-io|report-writer|sort-merge|json-generate|xml-generate/) migratable = "review"
      if (d > 0) migratable = (migratable == "yes" ? "later" : migratable)

      printf "%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\n", n, k, d, indegree_n, h, migratable, c, a
    }
  }
' "$RAW"
