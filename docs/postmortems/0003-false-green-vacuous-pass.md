# Postmortem 0003: 偽 green（vacuous pass）— 成功を「結論」だけで判定した

- **Date**: 2026-06-28
- **Status**: Resolved（構造ガードを `tools/golden/check-all` に追加）
- **Severity**: Low（merge 前にログ確認で捕捉・実害なし。だが「偽 green を信じる」一歩手前だった）
- **Author**: @hagishun（agent 実装 ＋ 人間レビュー）

> ※ awk の単純タイポ（`$1="-"` vs `$1=="-"`）そのものは本題ではない。**本題は「成功・失敗をどう判定するか」**。タイポは「判定の穴」を露出させた引き金にすぎない。

## 要約
golden 等価ゲート（CI `golden-master equivalence`）の `tools/golden/check-all` を編集した際、
パーサ（awk）のバグで **登録プログラムが 0 件**と解釈された。check-all は「0 件 → `exit 0`」だったため、
**実際には何も検証していないのに CI は `success`** を返した（＝**偽 green / vacuous pass**）。
top-level の「success」だけ見れば「trim 通過」と誤認するところを、**ログを読んで**「no programs registered」に気づき捕捉した。

## タイムライン
1. ハーネス修正をコミット → PR ブランチで CI 実行 → **`success`**。
2. 「やった、通った」と一度報告しかけた。
3. ログを確認 → `check-all: no programs registered in manifest.yaml — nothing to verify.` を発見。
4. 「success なのに 1 件も検証していない」＝矛盾に気づく。
5. 原因＝awk の `$1="-"`（代入）が毎行 `$1` を書き換え、全プログラムが不一致 → 0 件。
6. `$1=="-"`（比較）に修正 ＋ **vacuous-pass ガード**を追加 → 再実行で **真の green**（interest＋trim を実検証）。

## 影響
- 一時的に「trim が等価検証を通過した」と**誤認しかけた**（実際は未検証）。
- merge 前・ログ確認で止めたため**実害なし**。もしログを読まずに次工程へ進めば、未検証の Java を「等価」として扱う事故になり得た。

## 根本原因（＝判定の仕方の問題）
1. **成功を「結論」だけで判定した**: `success` / 緑のチェックマークを見て「OK」とした。「**何件検証したか**」を見ていなかった。
2. **ゲートが vacuously true を許す設計だった**: 「検証対象 0 件 → pass」。守りたい不変条件（**1 件以上を実際に検証した**）が強制されていなかった。
3. （副次）awk タイポ。ただし本質はタイポではなく、**タイポが静かに偽 green 化した**こと。

## 検知
人間が**ログを読んだ**こと。＝成功判定の番人はまだ人間の規律であり、仕組みではなかった。

## 対応（実施済み）
- `tools/golden/check-all` に **vacuous-pass ガード**を追加（commit `6a4e48f`）:
  manifest に `- name:` エントリがあるのにパース結果が 0 件なら、`::error` で**明示 fail**（`exit 0` させない）。
- awk を `$1=="-"` に修正。
- → 「パーサ/形式バグで 0 件」は今後 **緑ではなく赤**で止まる。

## 再発防止 / 一般原則（成功・失敗の判定）
> **green は必要条件であって十分条件ではない。**

- **「何を・何件」検証したかを必ず確認する**。`0 件で pass` は偽 green。
- **ゲートは vacuously true を fail にする**（期待対象が 0 なら成功ではなくエラー）。
- **結論（success/緑）ではなく evidence（ログ・件数・実出力）で判定する**。
- **「動いた」と「期待した検証が実行された」を区別する**。前者は後者を含意しない。

## 教訓（一般化）
> **守りたい不変条件はゲートにしないと最初に消える**（postmortem 0001 と同型）。
> ここでの不変条件は「**ゲートは 0 件で素通りしない**」。
> そして **success は「動いた」ではなく「期待した検証が実行された」で判定する**。

## 関連
- [Postmortem 0001](0001-skipped-code-to-doc.md)（守りたい価値はゲート化しないと消える）
- ADR-0005（golden = ground truth）/ ADR-0014（2層 Scorecard＝成果の判定）/ ADR-0018（program 非依存ゲート）
- `tools/golden/check-all`（vacuous-pass ガード, commit `6a4e48f`）
- 観測一般: `docs/observability/gh-aw-audit.md`（run 結果は結論でなく artifact/ログで判定する）
