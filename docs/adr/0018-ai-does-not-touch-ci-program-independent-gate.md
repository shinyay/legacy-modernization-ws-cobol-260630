# ADR-0018: AI は CI・ビルド・保護ファイルを変更しない — 等価ゲートを program 非依存にする

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun (Architect / Maintainer)

## Context

Phase 3 の初回実走（gh-aw migrate run 28282105838 → PR #3）で、`migrate` エージェントは正しいパッチを作れたのに **Draft PR が自動で開かず、保護ファイル変更のため `request_review` で Issue #2 にエスカレーション**した。原因をソースで裏取りした結果、次が分かった（`github/gh-aw`）：

- `create-pull-request` safe-output は **既定で保護ファイルを検査**する（`gh aw compile` が `protected_files` ＋ `protect_top_level_dot_folders: true` ＋ ポリシー `request_review` を自動注入。こちらの `migrate.md` には未記載）。
- `request_review` の本来挙動は「**PR を開いて REQUEST_CHANGES レビューを付ける**」。Issue 化ではない。
- **Issue になった真因は、パッチが `.github/workflows/ci.yml` を含んだこと**。GitHub Actions のトークンは `workflows` 権限（GitHub App 専用）を持てず `.github/workflows/` を push できない。gh-aw は push 失敗を検知し、`gh run download → git am --3way → gh pr create` を案内する **レビュー Issue フォールバック**に降格した。

さらに当時の `ci.yml` は **`interest` 固有にハードコード**されていた（job 名 `golden-master equivalence (interest)`、`freeze interest` / `verify interest` / `tests/interest/golden/` ベタ書き）。このため **2 本目以降の移行で `migrate` は必ず `ci.yml` を編集したくなり**、毎回エスカレーションが起きる構造だった。

## Decision

**AI エージェント（`migrate` ／ `migrator`）は CI・ワークフロー・ビルド設定・保護ファイルを変更しない。** そのために **等価ゲートを program 非依存**にする。

1. **等価ゲートは manifest 駆動の汎用ドライバ `tools/golden/check-all` に集約**する。`ci.yml` は `sh tools/golden/check-all` を呼ぶだけ。ドライバは `manifest.yaml`（台帳）を回し、`tests/<prog>/cmd` を持つ各 program について freeze → drift-guard → verify を実行する。**program を増やしても `ci.yml` も `check-all` も変更不要**。
2. **required check 名を `golden-master equivalence` に汎用化**（`(interest)` を外す）。program が増えても check 名は安定し、branch protection の再設定が不要になる。
3. **AI の書き込み範囲を限定**する。新 program に必要なのは次だけ：
   - `app/src/main/java/<prog>/*.java`（本番 Java。`app/pom.xml` は初回作成済み・以降は触らない）
   - `specs/<prog>.md`（Code→Doc）
   - `tests/<prog>/inputs/*.txt` ＋ `tests/<prog>/cmd`（golden 本体は CI が凍結）
   - `manifest.yaml` への 1 エントリ
   - `docs/adr/<n>-*.md`（移行判断 ADR・Proposed）
4. **`.github/**`（特に `ci.yml`）・ビルド設定・保護ファイルは変更禁止**。配線が要ると感じたら止めて **Human review required** に書く。`pom.xml` / `README.md` の basename は保護対象だが、これらは `request_review`（＝PR を開いて REQUEST_CHANGES）に留まり人間ゲートとして妥当。**禁止が厳格に効くのはワークフローファイル**（push 不可＝Issue 降格の原因）。

## Consequences

- **良い点**:
  - 2 本目以降の `migrate` パッチが `ci.yml` を触らない → **workflow push 失敗が起きず Draft PR が自動で開く**。ループ一周が滑らかになり、人間ゲートは required check ＋ REQUEST_CHANGES で保たれる。
  - CI が **N プログラムに無編集でスケール**。台帳（`manifest.yaml`）に 1 行足すだけ。
  - 「AI は配管（CI/ビルド）を書き換えない」が設計として明文化され、supply-chain 保護と整合（ADR-0016 の least-privilege を CI 面に拡張）。
- **悪い点 / トレードオフ**:
  - 一度きりの移行コスト：required check を `golden-master equivalence` にリネーム（branch protection を更新）。`check-all` は `manifest.yaml` を awk で読む簡易パーサ（台帳の記載形に依存）。
  - `app/pom.xml` に新依存が本当に要るケースは、依然 `request_review`（人間レビュー）になる。これは意図どおり。
- **中立**:
  - ADR-0017 が参照する旧 check 名 `golden-master equivalence (interest)` は当時の事実として残す（ADR は不変）。命名は本 ADR が supersede する。

## Confirmation

- 変更後、`main` で CI job `golden-master equivalence` が green（`tools/golden/check-all` が interest を freeze/drift/verify して PASS）。
- branch protection の required check が `golden-master equivalence` に更新されている。
- 将来 2 本目の program を **`ci.yml` を編集せずに**追加できる（台帳 ＋ `app/` ＋ `specs/` ＋ `tests/` のみ）。

## Alternatives considered

- **program ごとの matrix check**（`golden-master equivalence (<prog>)` を動的生成）: 却下。matrix の context 名が動的で、branch protection の required 指定が program 追加のたびに必要になり、本 ADR の目的（無編集スケール）に反する。
- **`allow-workflows: true` ＋ `safe-outputs.github-app`**（App 認証で `workflows: write` を付与し AI に `ci.yml` を触らせる）: 却下（現時点）。App 資格情報の管理が増え、「AI は配管を書き換えない」方針に逆行する。将来どうしても AI がワークフローを所有する必要が出たら再検討。
- **ハードコードのまま Issue 降格を受容**: 却下。毎周エスカレーションが発生し、滑らかさを損なう。

## References

- 実走の経緯: gh-aw migrate run 28282105838 → escalation Issue #2 → PR #3（`git am` 回収）→ Merge `a2e4686`
- gh-aw 保護ファイル仕様: `create-pull-request` の `protected-files`（`request_review` 既定）／ `protect_top_level_dot_folders` ／ `manifest_protection_push_failed_fallback.md`（`git am` 案内）
- ドライバ: [`tools/golden/check-all`](../../tools/golden/check-all) ／ [`tools/golden/freeze`](../../tools/golden/freeze) ／ [`tools/golden/verify`](../../tools/golden/verify)
- 関連 ADR: ADR-0005（golden master）/ ADR-0010（gh-aw 手動 dispatch）/ ADR-0013（Java only 本番・cobc は CI/コンテナ）/ ADR-0015（Code→Doc spec gate）/ ADR-0016（層2 maker/checker・最小権限）
