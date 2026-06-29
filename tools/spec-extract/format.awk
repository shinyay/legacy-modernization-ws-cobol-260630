# spec-extract: tree-sitter query の出力 → 業務仕様の骨子(Markdown)
# 真実の源は cobc golden(ADR-0005)。本出力は Code→Doc(ADR-0009) の補助。
# BWK awk(macOS 既定) 互換: gawk 拡張(3引数 match 等)は使わない。

BEGIN {
  # 複数行 capture の text 補完用に、固定形式ソースを行配列へ読み込む
  if (fixed != "") { nl=0; while ((getline ln < fixed) > 0) src[++nl]=ln; close(fixed) }
}

# 範囲(0-based start..end row)から固定形式ソース行を連結(先頭空白は圧縮)
function srcjoin(sl, el,   r, line, txt) {
  txt=""
  for (r=sl+1; r<=el+1; r++) { line=src[r]; sub(/^[ ]+/,"",line); txt=(txt==""?line:txt" "line) }
  return txt
}

function store(name, text) {
  if      (name == "data.level") { lvl = text }
  else if (name == "data.name")  { nm = text }
  else if (name == "data.pic")   { di++; dl[di]=lvl; dn[di]=nm; dp[di]=text }
  else if (name ~ /^stmt\./)     { k=name; sub(/^stmt\./,"",k); pi++; ps[pi]=toupper(k); pt[pi]=text }
  else if (name == "func.name")  { fc[text]++ }
}

# 複数行 capture (text 省略): "capture: stmt.compute, start: (28, 7), end: (29, 46)"
/capture: [A-Za-z._]+, start:/ {
  s=$0; sub(/^.*capture: /,"",s); name=s; sub(/,.*/,"",name)
  a=$0; sub(/^.*start: \(/,"",a); sl=a; sub(/,.*/,"",sl)
  b=$0; sub(/^.*end: \(/,"",b);   el=b; sub(/,.*/,"",el)
  joined = (fixed != "" ? srcjoin(sl, el) : "")
  store(name, (joined != "" ? joined : "(L" (sl+1) "-L" (el+1) ", multi-line)"))
  next
}
# 単一 capture (text あり): "capture: 0 - data.level, ..., text: `01`"
/capture: [0-9]+ - [A-Za-z._]+,.*text: `/ {
  s=$0; sub(/^.*capture: [0-9]+ - /,"",s); name=s; sub(/,.*/,"",name)
  t=$0; sub(/^.*text: `/,"",t); sub(/`[ \t]*$/,"",t)
  store(name, t)
  next
}

END {
  print "## データ項目"
  print "| level | name | picture |"
  print "|---|---|---|"
  for (i=1;i<=di;i++) printf "| %s | %s | %s |\n", dl[i], dn[i], dp[i]
  if (di==0) print "| - | - | - |"
  print ""
  print "## 処理フロー (PROCEDURE, 出現順)"
  for (i=1;i<=pi;i++) printf "%d. %s  `%s`\n", i, ps[i], pt[i]
  if (pi==0) print "_(なし)_"
  print ""
  print "## 使用された組み込み関数"
  n=0; for (f in fc) { n++; printf "- %s (%d回)\n", f, fc[f] }
  if (n==0) print "- (なし)"
}
