# Copilot Instructions — loopengineering

このリポは「レガシー COBOL を **Code→Doc→Code** で Java へ検証付き移行し、Azure にデプロイする自走ループ」。
**原則・場所・数値注意の“正”は [`AGENTS.md`](../AGENTS.md)。まずそれに従う。**
本ファイルは Copilot 向けの **運用ルール** と **skill routing** だけを足す（原則は再掲しない）。

全体像: [docs/architecture.md](../docs/architecture.md) ／ 計画: [docs/plan.md](../docs/plan.md)

## 必ず守る（AGENTS.md に加えて）

- **golden は手書きしない。** `cobc` で freeze した**実出力**が正（ADR-0005）。候補（rewrite/wrapper）は `tests/<prog>/golden/` と一致必須（CI required check）。
- **Code→Doc は必須成果物。** 各 `tests/<prog>/` に `specs/<prog>.md` が無いと **CI で落ちる**（ADR-0015）。CI は 3 ゲート（spec 存在 / drift guard / 等価性 = required check `golden-master equivalence`）。
- **AI は CI・ワークフロー・ビルド設定・保護ファイルを変更しない（ADR-0018）。** 等価ゲートは program 非依存（`tools/golden/check-all` が `manifest.yaml` を回す）。新 program に必要なのは `app/`・`specs/<prog>.md`・`tests/<prog>/{inputs,cmd}`・`manifest.yaml` の 1 行だけ — **`.github/**`（特に `ci.yml`）は触らない**。
- **ADR は [`adr-authoring`](skills/adr-authoring/SKILL.md) skill で書く。agent は `Proposed` で作成し、自分で `Accepted` にしない**（人間がレビューして昇格, ADR-0012）。
- **新しい skill を足したら [`.github/skills/README.md`](skills/README.md)（skill index）に 1 行追加**（ADR-0012）。
- **本番ランタイムは Java のみ。GnuCOBOL はローカル Mac に入れない**（COBOL のビルド/実行/freeze は**コンテナ or CI**, ADR-0013）。
- ※ 直訳禁止・`legacy/` 不変・rewrite 優先/fallback・数値（BigDecimal/COMP-3）の扱いは **`AGENTS.md` が正**（ここでは繰り返さない）。

## skill routing（作業 → 使う skill。一覧: [skill index](skills/README.md)）

| やること | skill |
|---|---|
| 重要な判断を記録する | `adr-authoring` |
| COBOL を読む / `cobc -x` でビルド | `cobol-gnucobol-dialect` |
| discovery（依存/意味論ホットスポット抽出） | `cobol-discovery-hotspot` |
| 業務仕様を抽出（Code→Doc） | `cobol-to-spec`（構造骨子は `bash tools/spec-extract/extract.sh <src.cob>` で機械抽出） |
| spec から Java 生成（Doc→Code） | `spec-to-java` |
| rewrite 不可 → COBOL を包む（fallback） | `cobol-java-wrapper` |
| golden を固定 / 候補を検証 | `golden-master-testing` |
| 長時間処理（gh-aw/CI/Actions）を回す / 安価モデルを worker 運用 | `long-running-ops`（停止・確認・再試行ポリシー, ADR-0022） |
| 1 program を bounded task に分解（planner / 4役経路） | `task-decomposition`（done/stop 条件・model tier, ADR-0023） |

## 参照

- 判断の記録（ADR）: [docs/adr/](../docs/adr/)（索引 [README](../docs/adr/README.md)）
- 動作サンプル（アンカー）: [samples/interest/](../samples/interest/)
- ループ定義（gh-aw）: [.github/workflows/](workflows/)（triage / migrate / verify）
