---
name: golden-master-testing
description: 'COBOL の実行出力を「正解（golden）」として固定し、移行候補（Java rewrite / wrapper）が一致するか正規化 diff で検証する。USE FOR: golden を freeze する / 候補を verify する / 等価性ゲートを作る。DO NOT USE FOR: 仕様抽出（cobol-to-spec）/ Java 生成（spec-to-java）/ golden を手書き・推測で作ること。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# golden-master-testing（等価性ゲート）

振る舞いの「正」を**元 COBOL の実出力**に固定し、候補がそれに一致するかを検証する（ADR-0005）。

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: 元 COBOL を `cobc -x` でビルドして実行した出力（**手書き厳禁**）。
- **gate**: 一致を CI の **required check** にする（不一致は merge ブロック＝ループ停止条件）。
- **artifact**: `tests/<prog>/{cmd,inputs/,golden/}` を出力。`golden/` は freeze で生成。
- **order**: spec（cobol-to-spec）の後 → Java 生成（spec-to-java）の検証として使う。
- **completion criteria**: 正規化後の diff がゼロ（green）。**「結論が green」だけで合格にしない**——実際に **1 件以上のケースを検証した**（freeze→verify が走った件数 > 0）ことをログで確認する。**0 件で素通り（vacuous pass）は不合格**（postmortem 0003）。
- **escape-hatch control**: golden を手書き/推測で作らない。通すために golden や正規化を緩めない。**`success`/緑を鱵呑みにせず evidence（ログ・検証件数・実出力）で判定**し、0 件検証の偽 green を合格にしない（postmortem 0003）。

## freeze / verify

- **freeze**: COBOL を実行し、`tests/<prog>/inputs/*` ごとの出力を `tests/<prog>/golden/` に固定（一度だけ）。
- **verify**: 候補（rewrite Java / wrapper）を同じ入力で実行し、golden と**正規化 diff**。
- **正規化（マスク対象）**: 固定長パディング / 改行コード / 文字エンコード / 数値書式 / 非決定性（日付・乱数・時刻）。

## 手順

1. 入力ケースを `tests/<prog>/inputs/` に用意。
2. `cobc` でビルドし freeze（golden 固定）。**Mac には入れず CI / コンテナで**実行（ADR-0013）。
3. 候補を verify。不一致は**候補側**を直す（golden は不変）。
4. CI（`.github/workflows/ci.yml`）から呼び、required check にする。
5. **合否はログで判定**（結論だけで見ない）: `verify` が **1 件以上 PASS** したことを確認する。`PASS` 件数 = 0 や `no programs` / `nothing to verify` は **偽 green＝不合格**（postmortem 0003）。

## 関連

- ADR-0005（golden master）/ ADR-0013（cobc は CI/ビルド限定）/ ADR-0014（ground truth）/ [postmortem 0003](../../../docs/postmortems/0003-false-green-vacuous-pass.md)（偽 green を合格にしない）。
- 題材: `samples/interest/`。ハーネス: `tools/golden/`（freeze/verify）。
