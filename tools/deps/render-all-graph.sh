#!/usr/bin/env sh
# render-all-graph.sh — deps全体グラフをmanifest属性で色分け
set -eu

ROOT="$(CDPATH= cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

MANIFEST="${1:-manifest.yaml}"
OUT="${2:-tools/deps/out/deps-graph.all.colored.mmd}"
REPORT="tools/deps/out/deps-report.all.txt"

if [ ! -f "$MANIFEST" ]; then
  echo "error: manifest not found: $MANIFEST" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

# 最新の全体解析レポートを生成
"$ROOT/tools/deps/analyze.sh" --all > "$REPORT"

awk '
function emit_style(){
  print "  classDef rewritten fill:#c7f9cc,stroke:#2b9348,color:#1b4332,stroke-width:1.5px"
  print "  classDef candidate fill:#dbeafe,stroke:#1d4ed8,color:#1e3a8a,stroke-width:1.5px"
  print "  classDef review fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d,stroke-width:1.5px"
  print "  classDef later fill:#e5e7eb,stroke:#4b5563,color:#111827,stroke-dasharray: 4 2"
  print "  classDef external fill:#fef3c7,stroke:#d97706,color:#92400e,stroke-width:1.5px"
}
function flush_manifest(){
  if (m_name == "") return
  cls = "candidate"
  if (m_status == "rewritten") cls = "rewritten"
  else if (m_migratable == "later") cls = "later"
  else if (m_migratable == "review") cls = "review"
  manifest_cls[m_name] = cls
}
FNR == NR {
  if ($1 == "-" && $2 == "name:") {
    flush_manifest()
    m_name = $3
    m_status = m_migratable = m_hotspots = ""
    next
  }
  if ($1 == "status:") { m_status = $2; next }
  if ($1 == "migratable:") { m_migratable = $2; next }
  if ($1 == "hotspots:") { m_hotspots = $2; next }
  next
}
{
  if ($0 ~ /^```mermaid/) { in_graph = 1; next }
  if (in_graph && $0 ~ /^```/) { in_graph = 0; next }
  if (!in_graph) next

  if ($0 ~ /^  [A-Z0-9_-]+\[\"/) {
    line = $0
    sub(/^  /, "", line)
    sub(/\[.*/, "", line)
    n = line
    nodes[n] = 1
    labels[n] = n
    next
  }
  if ($0 ~ /^  [A-Z0-9_-]+ --> [A-Z0-9_-]+/) {
    line = $0
    sub(/^  /, "", line)
    split(line, a, " --> ")
    from = a[1]
    to = a[2]
    edges[++edge_n] = from SUBSEP to
    nodes[from] = 1
    nodes[to] = 1
    labels[from] = from
    labels[to] = to
    next
  }
}
END {
  flush_manifest()

  print "flowchart LR"
  for (n in nodes) {
    print "  " n "[\"" labels[n] "\"]"
  }
  for (i = 1; i <= edge_n; i++) {
    split(edges[i], e, SUBSEP)
    print "  " e[1] " --> " e[2]
  }

  for (n in nodes) {
    cls = manifest_cls[n]
    if (cls == "") cls = "external"
    print "  class " n " " cls
  }

  emit_style()
}
' "$MANIFEST" "$REPORT" > "$OUT"

echo "generated: $OUT"
