# Postmortem 0001: Code→Doc 工程を飛ばして直訳した

- **Date**: 2026-06-27
- **Status**: Resolved（再発防止を ADR-0015 で強制）
- **Severity**: Medium（方法論の主役が一時未実証。振る舞いは golden で担保されていた）
- **Author**: @hagishun（agent 実装 ＋ 人間レビュー）

## 要約
Phase 2 縦切り（`interest`）で、移行方式の核 **Code→Doc→Code**（ADR-0009）の **Code→Doc 工程を飛ばし**、
Java 候補を COBOL から**直接**書いた（＝本プロジェクトが禁じる直訳 / JOBOL）。`specs/interest.md` が生成されず、
「振る舞いは golden / intent は Doc」の **Doc 側が欠落**した。

## タイムライン
1. 「次の一手」で Phase 2（等価ハーネス）を実装。目標＝**CI を緑に**。
2. 候補が必要 → COBOL を見て Java を直接実装 → golden と一致 → CI green。
3. golden ハーネス・drift guard まで完成し「縦切り GREEN」と報告。
4. 人間が **「Doc は？」** と指摘 → `specs/interest.md` 不在が発覚。
5. COBOL ＋ golden を出典に `specs/interest.md` を後追い作成し復旧。

## 影響
- 一時的に **方法論（直訳しない＝発表の主役）が未実証**。
- 等価性（振る舞い）は golden で担保されており **実害は限定的**。
- Doc を書いて初めて **case01 が丸め（half-up）を検証していない**穴も判明（副次的発見・TODO化）。

## 根本原因
1. **ゴールのすり替え**: 「等価ゲートを緑に」が目先の目標になり、最速の候補＝直訳を選んだ。
2. **チェックリストの欠陥**: build-tasks「次の一手」が *「手で Java 化」* と書き、`specs/<prog>.md` を成果物に列挙していなかった。**リストに無い＝落ちる**。
3. **サンプルが小さすぎ**: 数行なので「業務が分からない」痛み（Doc を書く動機）が出ず、省略の摩擦がゼロ。
4. **フェーズ境界の取り違え**: Code→Doc を「後で（Skills/Agents）」と分類し、harness（今）と分離。隙間に落ちた。
5. **（核心）Doc にゲートが無い**: 等価性は CI で強制されるが、spec 存在は誰も強制しない。**強制されない軸は時間圧で最初に削られる**。

## 検知
人間レビューの一言「Doc は？」。＝ intent 側の番人は（まだ）人間。

## 対応（実施済み）
- `specs/interest.md` を COBOL ＋ golden を出典に作成（推測で創作しない）。
- **ADR-0015**: `specs/<prog>.md` を必須化し **CI で存在を強制**。
- `ci.yml` に "Require Code→Doc spec" ゲートを追加。

## 再発防止
- **構造ゲート化**（ADR-0015）: spec 不在は CI fail ＝ 口約束を仕組みに。
- **チェックリスト修正**: 縦切りの定義に「spec を出す」を含める（build-tasks）。
- ループの `migrate.md` / `verify.md` は rewrite 前に spec を生成・更新する。

## 教訓（一般化）
> **守りたい価値は、ゲートにしないと最初に消える。** 強制力のある軸だけが生き残る。
> 方法論を主役にするなら、その方法論自体を CI の停止条件に組み込め。

## 関連
- ADR-0015（spec 必須ゲート）/ ADR-0009（Code→Doc→Code）/ ADR-0005（golden master）。
- `specs/interest.md` / `.github/skills/cobol-to-spec/`。
