---
name: cobol-gnucobol-dialect
description: 'GnuCOBOL(OpenCOBOL) 方言の参照知識：PIC/暗黙小数(V)/COMP-3、編集語、ACCEPT/DISPLAY と FILE I/O、`COMPUTE ... ROUNDED` の丸め、`cobc -x` ビルド（free/fixed format）。USE FOR: COBOL を読む/ビルドする/golden を freeze する/型・桁・丸めの意味を確かめるとき。DO NOT USE FOR: 業務ルール抽出（cobol-to-spec）/ Java 生成（spec-to-java）/ golden 検証（golden-master-testing）/ Mac host で cobc を実行すること（ADR-0013 で禁止）。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# cobol-gnucobol-dialect（GnuCOBOL 方言の参照知識）

COBOL を「読む・ビルドする」ための方言知識。spec 抽出（Code→Doc）や Java 生成（Doc→Code）の**前提**として、PIC/桁/丸め/編集語/ビルドの意味を正しく取るための**参照寄り** skill（直接の成果物は持たない・ADR-0012）。推測ではなく `cobc` の実挙動を正とする。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: GnuCOBOL の実挙動（`cobc` / 実行バイナリの出力）。型・桁・丸めは推測せず実行で確かめる。
- **gate**: 対象 COBOL が `cobc -x` でビルドでき、`tools/golden/freeze` で golden を固定できること。
- **artifact**: なし（参照知識）。成果は他 skill が出す spec / golden / Java の**正確さ**に反映される。
- **order**: Loop の最上流。Analyze / Code→Doc / Golden Master の前提知識。
- **completion criteria**: ビルドが通り、PIC・桁・丸め・編集語の解釈を golden と一致して説明できる。
- **escape-hatch control**: Mac host で `cobc` を実行しない（ADR-0013＝CI/コンテナ専用）。曖昧な桁・丸め・パディングを「たぶん」で進めず golden で確定する。

## ビルド（`cobc -x`・format に注意）

GnuCOBOL の既定は **fixed format**。free-format ソース（先頭 `>>SOURCE FORMAT FREE`）は `-free` を明示しないと、その指令を**7桁目の indicator** と誤読して落ちる（`invalid indicator 'C' at column 7`）。

```bash
# 実行可能バイナリを生成（-x）。free format は -free を明示
cobc -x -free -o /tmp/<prog> samples/<prog>/<prog>.cob
```

- 固定長レガシは `-fixed`。ハーネスは `COBC_FLAGS` で上書き可: `COBC_FLAGS=-fixed tools/golden/freeze <prog>`（既定は `-free`）。
- ⚠️ **ローカル（Mac）では実行しない**。`tools/golden/freeze` も `cobc` 不在なら拒否する（ADR-0013）。CI（`ci.yml`）またはコンテナで実行する。

## 型と桁（PIC → 意味）

- `9`=数字 / `X`=英数字 / `V`=**暗黙小数点**（位置のみ・桁は消費しない）/ `S`=符号 / `Z`=ゼロサプレス / `,` `.`=編集語。
- 例: `PIC 9(7)V99` = 整数7桁＋小数2桁（暗黙小数）。`PIC 9(2)` = 整数2桁。
- `COMP-3`（packed decimal）= 1バイト2桁＋符号ニブル。**Java では `BigDecimal`**（`double` 禁止）。桁とスケールを保つ。
- 編集語 `Z,ZZZ,ZZ9.99` = 桁区切りカンマ＋ゼロサプレス＋小数2桁。先頭ゼロは空白、最小桁は `9` で残す。**空白詰め幅は実装依存 → golden で確定**（手書きしない）。

## 計算と丸め

- `COMPUTE ... ROUNDED` = NEAREST-AWAY-FROM-ZERO ≒ Java `RoundingMode.HALF_UP`。
- 中間結果は受け側 PIC の桁・スケールに切り詰め。`ROUNDED` 無しは切り捨て（truncate）。
- 例（`samples/interest`）: `COMPUTE WS-INTEREST ROUNDED = WS-PRINCIPAL * WS-RATE / 100 * WS-YEARS` → 7.125 は **7.13**（HALF_EVEN なら 7.12 になるところ）。

## 入出力

- `ACCEPT` = stdin から1行 / `DISPLAY` = stdout（末尾改行付き）。固定長 FILE I/O はレコード長・パディングに注意。
- `FUNCTION NUMVAL(x)` = 文字列→数値（前後空白・桁区切りカンマを許容）。Java 側は trim＋カンマ除去で再現する。

## 手順（読む / ビルドするとき）

1. 冒頭の format 指令（`>>SOURCE FORMAT FREE` の有無）を確認 → `-free` / `-fixed` を決める。
2. DATA DIVISION の PIC を桁・スケール・符号・編集語に分解（→ spec のデータ定義へ）。
3. PROCEDURE の `COMPUTE` / `ROUNDED` / `MOVE`（編集）を数値規則として読む。
4. `cobc -x` でビルド → `tools/golden/freeze <prog>` で実出力を golden 化（CI/コンテナ）。

## 関連

- 関連 ADR: 0005（golden master）/ 0008（rewrite=Java・数値=BigDecimal）/ 0013（cobc は CI/コンテナ専用）。
- 後工程: `cobol-to-spec`（Code→Doc）/ `spec-to-java`（Doc→Code）/ `golden-master-testing`（検証）。
- 実例: `samples/interest/interest.cob`（`9(7)V99` / `ROUNDED` / `Z,ZZZ,ZZ9.99`）。
