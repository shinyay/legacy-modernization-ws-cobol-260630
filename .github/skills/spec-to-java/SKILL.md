---
name: spec-to-java
description: 'specs/<prog>.md から idiomatic な Java を生成する（Doc→Code）。数値は BigDecimal＋丸めモード、桁/固定長/編集表示を spec どおり再現。USE FOR: spec から Java rewrite を作る / Plan→Rewrite 工程。DO NOT USE FOR: COBOL を直訳すること / spec が無い状態で書くこと / golden 検証（golden-master-testing）/ rewrite 不可時の wrapper（cobol-java-wrapper）。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# spec-to-java（Doc→Code：spec から Java 生成）

`specs/<prog>.md` を唯一の入力に idiomatic Java を生成する（直訳禁止, ADR-0009）。出力先は用途で分ける:

- **本番移行**（支給 COBOL の移行先）= `app/`（Maven/Gradle, ADR-0011）。
- **サンプル / PoC**（`samples/<prog>/` の実証用）= `samples/<prog>/java/`（サンプルと同居）。例: `samples/interest/java/Interest.java`。

いずれも **`tests/<prog>/cmd` が起動する場所と一致**させる（verify/CI がその候補を実行する）。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: `specs/<prog>.md`（最終検証は Golden Master）。COBOL ソースを直訳しない。
- **gate**: 生成物は `golden-master-testing` で golden 一致が必須（CI required check）。
- **artifact**: ビルド可能な Java を出力する（本番移行=`app/` / サンプル・PoC=`samples/<prog>/java/`、`tests/<prog>/cmd` と一致）。
- **order**: spec と golden が在ること前提。Plan → Rewrite の位置。
- **completion criteria**: golden 一致 green。未一致なら未完了。
- **escape-hatch control**: `double` 禁止（金額は `BigDecimal`）。spec に無い挙動を足さない。golden を緩めて通さない。

## Java 生成の規約

- 数値 = `BigDecimal`、丸め = spec の丸めモード（COBOL `ROUNDED` ＝ `RoundingMode.HALF_UP`）。
- 桁・暗黙小数・固定長・編集表示（`Z,ZZZ,ZZ9.99` 等）を spec どおり再現。
- 入出力契約（stdin/stdout・固定長・改行）を spec に一致させる。
- フレームワークは軽量（Javalin/Spark）。例外・ログは最小限で明示的に。

## 手順

1. spec の入出力契約・数値規則を Java の型・整形に落とす。
2. 計算は `BigDecimal` で、丸めモードを明示。
3. ビルドできる形で出力（本番 `app/` / サンプル `samples/<prog>/java/`）。`tests/<prog>/cmd` がその場所を起動するよう揃える。
4. `golden-master-testing` で検証 → 不一致は spec/実装を直す（**golden は触らない**）。

## 関連

- 題材例: `samples/interest/`（spec=`specs/interest.md` / Java=`samples/interest/java/Interest.java`）。
- ADR-0008（rewrite=Java）/ ADR-0009 / ADR-0011（リポ構成：`app/`=移行先）/ ADR-0014。
- 前工程: `cobol-to-spec`。検証: `golden-master-testing`。fallback: `cobol-java-wrapper`。
