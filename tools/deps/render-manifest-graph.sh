#!/usr/bin/env sh
# render-manifest-graph.sh — manifest.yaml から色分けMermaidを生成
set -eu

ROOT="$(CDPATH= cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

IN="${1:-manifest.yaml}"
OUT="${2:-tools/deps/out/deps-graph.manifest.colored.mmd}"

if [ ! -f "$IN" ]; then
  echo "error: manifest not found: $IN" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

awk '
function trim(s){ sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function flush_record(   cls,arr,n,i,c,calls_clean){
  if(name=="") return
  print "  " name "[\"" name "\"]"
  cls = "candidate"
  if (status == "rewritten") cls = "rewritten"
  else if (migratable == "later") cls = "later"
  else if (migratable == "review") cls = "review"
  class_of[name] = cls

  calls_clean = calls
  gsub(/^\[/, "", calls_clean)
  gsub(/\]$/, "", calls_clean)
  gsub(/[ \t]/, "", calls_clean)
  if (calls_clean != "") {
    n = split(calls_clean, arr, ",")
    for (i=1; i<=n; i++) {
      c = trim(arr[i])
      if (c == "") continue
      print "  " name " --> " c
      if (!(c in seen_external)) seen_external[c] = 1
    }
  }
}
BEGIN {
  print "flowchart LR"
  name=status=migratable=hotspots=calls=""
}
/^  - name:/ {
  flush_record()
  name=$3
  status=migratable=hotspots=calls=""
  next
}
/^    status:/ { status=$2; next }
/^    migratable:/ { migratable=$2; next }
/^    hotspots:/ { hotspots=$2; next }
/^    calls:/ {
  calls=$2
  if (NF > 2) {
    for (i=3; i<=NF; i++) calls = calls " " $i
  }
  next
}
END {
  flush_record()

  for (n in seen_external) {
    if (!(n in class_of)) {
      print "  " n "[\"" n "\"]"
      class_of[n] = "external"
    }
  }

  for (n in class_of) print "  class " n " " class_of[n]

  print "  classDef rewritten fill:#c7f9cc,stroke:#2b9348,color:#1b4332,stroke-width:1.5px"
  print "  classDef candidate fill:#dbeafe,stroke:#1d4ed8,color:#1e3a8a,stroke-width:1.5px"
  print "  classDef review fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d,stroke-width:1.5px"
  print "  classDef later fill:#e5e7eb,stroke:#4b5563,color:#111827,stroke-dasharray: 4 2"
  print "  classDef external fill:#fef3c7,stroke:#d97706,color:#92400e,stroke-width:1.5px"
}
' "$IN" > "$OUT"

echo "generated: $OUT"
