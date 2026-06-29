# Build Tasks — フレームワーク構築の現在地ボード

> **これは「環境構築（フレームワーク構築）」のタスク追跡**。別セッションはまずこのファイルを開く。
> **変換（COBOL→Java 移行ループ）が始まったら、個別タスクは GitHub Issue へ**（triage→Issue→Next Issue, ADR-0011）。
> 計画本体: [docs/plan.md](plan.md) ／ 全体図: [docs/architecture.md](architecture.md) ／ 判断: [docs/adr/](adr/)。

## 現在地（2026-06-27）

**Phase 2 縦切り（interest）= 完全 GREEN** ✅。golden ハーネス（`tools/golden` freeze/verify）＋ `tests/interest/`（inputs/cmd/golden）＋ Java rewrite（`samples/interest/java/Interest.java`）＋ `.github/workflows/ci.yml`（GnuCOBOL 等価ゲート）が CI で green。**Java rewrite の出力が GnuCOBOL golden と完全一致**（run 28277859676）。CI 生成 golden を不変基準として commit（`11a6128`）し、**drift guard 稼働確認済み**。branch protection に **required check**（`golden-master equivalence`）も追加済み（Flexible: `enforce_admins=false`、管理者は直 push 維持）。**Phase 1（5層フレームワーク）完了** ✅: Instructions 層＋Skills（全6本＋雛形 `_TEMPLATE.md`）＋Agents（全5体・最小権限・ADR-0016 Accepted）＋gh-aw（`triage/migrate/verify` の `*.md` 実在、awesome-copilot/gh-aw 準拠・read-only＋safe-outputs）。

**🎉 Phase 3 完全1周クローズ＋Merge 完了** ✅（2026-06-27）: **Issue #1**（triage 起票）→ **migrate** run 28282105838 → 保護ファイル（`pom.xml`/`README`/`ci.yml`）変更のため `request_review` で **Issue #2 にエスカレーション**（gh-aw 安全機構＝正しい挙動／Actions トークンは `.github/workflows` 改変不可も理由）→ Owner が patch を `git am` で branch 化 → **Draft PR #3** → **CI `golden-master equivalence (interest)` = PASS**（COBOL golden == `app/` Java を CI で証明）→ `/verify` run 28282606724 → 等価 checker レポート（直訳臭なし・NUMVAL 符号未カバー等を Human Review Required に列挙）＋ **Next Issue #4** 起票 → **ADR-0017 を Accepted・manifest `rewritten` 化 → PR #3 Merge（commit `a2e4686`、#1/#2 クローズ）**。**1周合計 ≈ 260 AIC**（triage 102＋migrate 87＋verify 72）。`app/` に本番 Java モジュール（Maven・`com.nridigital.loopengineering`・Java 21・`package interest`・BigDecimal+HALF_UP）が main に載った。**残り = Issue #4 の B（golden case03-05）／C（次 triage）＋ 安価モデル最適化**。

**🔧 ADR-0018：等価ゲートを program 非依存化**（Proposed, 2026-06-27）: 今回 Issue #2 エスカレの真因は migrate が **`.github/workflows/ci.yml`** を触り、Actions トークンが workflow を push できず Issue 降格したこと（gh-aw ソースで裏取り済）。改善: CI を **manifest 駆動の `tools/golden/check-all`** に集約し、`ci.yml` は program 非依存。required check を **`golden-master equivalence`**（`(interest)` を外した・branch protection 更新済）に汎用化。migrate/migrator/instructions に **「AI は CI・ワークフロー・ビルド・保護ファイルを触らない」** ガードを明記。→ **2 本目以降は `ci.yml` 無編集で Draft PR が自動オープン**（人間ゲートは required check＋REQUEST_CHANGES で保持）。CI green 確認済（run 28285127284）。**ADR-0018 = Accepted（2026-06-27, human）**。**✅ 2026-06-28 実測で確定**: `migrate prog=trim`（run 28313314355・96 AIC・10.4分）が **Draft PR #8 を自動オープン**（Issue 降格なし・`ci.yml`/保護ファイル無編集／`app/.../TrimFunctionTest.java`＋`specs/trim-function-test.md`＋`tests/trim-function-test/{cmd,inputs}`＋`manifest.yaml` 1 行のみ）。interest（ci.yml 改変→Issue #2 降格）と明確に対照。**新発見の caveat**: bot（`GITHUB_TOKEN`）が作った PR には CI（`on: pull_request`）が**自動起動しない**（GitHub の再帰防止）。PR #8 は `no checks` 状態で、等価ゲートを回すには**人間の push か `ci.yml` の手動 dispatch**が要る（＝人間ゲートが CI 起動の形で自然に入る）。

**🌳 tree-sitter で COBOL 構造抽出（spec-extract）導入**（ADR-0019 Accepted, 2026-06-27）: Code→Doc（ADR-0009）の構造抽出を機械化する**補助ツール** `tools/spec-extract/`（`extract.sh` / `queries/spec.scm` / `format.awk`）。COBOL → **spec 骨子**（データ項目表・処理フロー・組込関数）を出力。grammar（`tree-sitter-cobol`, MIT）を **gzip 凍結 vendoring**（`parser.c.gz` 2.2MB・初回自動展開・生は `.gitignore`・**clone のみで動く**）。interest で `specs/interest.md` と**完全一致**を実証。legacy 24本の素 parse は 12/24（失敗は画面/`EXEC SQL`/`JSON·XML GENERATE` 等＝**COBOL85 コア外の機能起因**で、形式ではない）。**真実の源は golden（ADR-0005）のまま＝補助**。着想元論文ノート [docs/papers/codebase-memory-tree-sitter-mcp.md](papers/codebase-memory-tree-sitter-mcp.md)。commit `7797215` / `1d03987` push 済み。

> ⚠️ **当初 Code→Doc（ADR-0009）を飛ばして Java を直訳していた**ため、`specs/interest.md` を後追いで作成（出典＝COBOL＋golden）。これで interest は **spec＋golden＋Java の Code→Doc→Code 完全例**（hero）に。丸め（half-up）も **case02**（570.00/1.25/1 → 7.125→7.13）で golden 実証済み（CI で PASS case01/case02）。
> **再発防止済み**: ADR-0015（`specs/<prog>.md` 存在を CI で強制）＋ポストモーテム [docs/postmortems/0001-skipped-code-to-doc.md](postmortems/0001-skipped-code-to-doc.md)。

**🎉 2・3本目の縦切り完了 ＋ discovery を安価モデルで実証**（2026-06-28）: **trim**（PR #8・ADR-0024・固定形式 legacy 初）と **numval**（PR #11・ADR-0025・merge `4510622`）を Code→Doc→Code で main にマージ。**移行済み = interest / trim / numval の3本**。numval は **discovery（triage）を `gpt-5-mini` で実走**（run 28315044876・**12.99 AIC**＝前回 triage 102 AIC の約1/8・429 なし・1 Issue で bounded 停止・既存 Issue と**重複回避**）し、`/migrate`（130 AIC）→ CI 等価（**4ケース真green**・`drift-guard OK`＋`all 4 PASS`・COMP-2 表示も Java `formatComp2()` で再現）→ `/verify`（79 AIC）→ finalize まで通した初の1本。**NUMVAL の符号（-5）・小数（3.14）・先頭空白を等価実証**（interest で未カバーだった符号をカバー）。**ADR-0021/0022/0023 を human Accepted**（commit `f0d3f96`）＝Proposed 状態の ADR なし（次番号 0026）。ループの自動進行は **verify まで回り、Accept/merge だけが人間ゲート**（ADR-0012/0022/0023 の設計どおり）。

## 次の一手

1. ~~golden ハーネス（freeze/verify）＋ tests/interest（inputs/cmd）~~ ✅
2. ~~`.github/workflows/ci.yml`（GnuCOBOL・golden 等価ゲート）~~ ✅
3. ~~interest の Java rewrite~~ ✅（`samples/interest/java/Interest.java`）
4. ~~push → CI 緑 → 生成 golden を commit（不変基準確定）~~ ✅（`11a6128`、drift guard 稼働）
5. ~~branch protection に `golden-master equivalence (interest)` を required check 追加~~ ✅（Flexible: 管理者は直 push 維持）
6. ~~Agents 5体（`.agent.md`・awesome-copilot 準拠・最小権限）~~ ✅（ADR-0016 Accepted）
7. ~~gh-aw（triage/migrate/verify）でループを包む~~ ✅（`*.md` 実在・read-only＋safe-outputs・engine copilot）
8. ~~Phase 3: `gh aw compile` → tokenless 認証 → triage/migrate/verify で interest を完全1周~~ ✅（Issue #1 → PR #3[CI golden PASS] → Next Issue #4）
9. ~~PR #3 を Merge（ADR-0017 Accepted・manifest `rewritten`）~~ ✅（commit `a2e4686`・#1/#2 クローズ）
10. **安価モデル最適化（`engine.model`）／ Issue #4 の B（golden case03-05）／C（次 triage）**
11. ~~tree-sitter spec-extract（Code→Doc 構造抽出の機械化・grammar 凍結 vendoring）~~ ✅（ADR-0019・2026-06-27）
12. **【明日】依存関係調査フェーズ**: ① spec-extract 横展開（legacy OK 群で抽出・クエリ汎用化）② 依存解析ツール `tools/deps`（`PROGRAM-ID`/`CALL`/`COPY`/`EXEC SQL`/`ASSIGN` → **依存グラフ＋トポロジカル順＋移行可否**）③ `manifest.yaml` に依存フィールド ④ triage が**葉・バッチ・決定的**を優先選定
13. **【次の心拍】Issue #9 UNSTRING-EXAMPLE を1周**（discovery 済・`format: fixed` 済）: `/migrate` → CI 等価 → `/verify` → finalize。trim/numval と同じ固定形式 leaf/batch の縦切りパターン。

## チェックリスト

### Phase 0 — 土台
- [x] scaffold（ディレクトリ＋README）
- [x] ADR 0001–0015（全 Accepted）
- [x] branch protection（force push/削除禁止）
- [ ] gh-aw 拡張インストール ＋ 認証（トークンレス `copilot-requests: write` 推奨 / or `COPILOT_GITHUB_TOKEN` PAT）（Phase 3 直前）
- [x] branch protection に golden required check（`golden-master equivalence`、Flexible）

### Phase 1 — 5層フレームワーク
- [x] Instructions: `AGENTS.md` / `copilot-instructions.md`（`.instructions.md` は後回し）
- [x] Skills 中核: `adr-authoring` / `cobol-to-spec` / `spec-to-java` / `golden-master-testing` ＋ skill index
- [x] Skills 残: `cobol-gnucobol-dialect` / `cobol-java-wrapper`（雛形 `_TEMPLATE.md` から実体化）
- [x] Agents: `cobol-analyzer` / `spec-extractor` / `migrator` / `verifier` / `triage`（awesome-copilot 準拠 `.agent.md`・最小権限・ADR-0016）
- [x] gh-aw workflows: `triage.md` / `migrate.md` / `verify.md`（`*.md` 実在・read-only＋safe-outputs・`gh aw compile` で `.lock.yml` 生成）

### Phase 2 — 検証ハーネス（ループの心臓）
- [x] `tools/golden`（freeze / verify・正規化）
- [x] `tests/interest/{cmd,inputs,golden}`（golden は CI 生成→commit 済み）
- [x] `.github/workflows/ci.yml`（GnuCOBOL・golden 等価ゲート）
- [x] interest の Java rewrite（`samples/interest/java/Interest.java`）
- [x] **push→CI 緑→生成 golden を commit**（`11a6128`、drift guard 稼働）
- [x] branch protection に `golden-master equivalence` を required check 追加（Flexible）

### Phase 3 — ループ配線 ＆ ドライラン
- [x] 前揜a: `gh extension install github/gh-aw`（v0.80.9）＋ `gh aw compile`（3本 green・`.lock.yml`・maintenance 無効化）
- [x] 前揜b: 認証 = B案トークンレス（`copilot-requests: write`・org enterprise・policy ON 確認・PAT不要）
- [x] **triage 実走 green**（run 28281403114・**Issue #1 起票**・102 AIC/9.9分/33turns/954k tokens・tokenless 実証）
- [x] **migrate → Draft PR → CI → verify で interest を完全1周** ✅（Issue #1 → migrate run 28282105838[87 AIC] → 保護ファイル変更で `request_review` ＝ **Issue #2 にエスカレーション**[gh-aw 安全機構] → Owner が patch を `git am` で branch 化 → **Draft PR #3** → **CI `golden-master equivalence (interest)` = PASS** → `/verify` run 28282606724[72 AIC] → 等価 checker レポート＋**Next Issue #4** 起票。1周合計 ≈ 260 AIC）
- [x] PR #3 のクローズ処理 ✅（ADR-0017 Accepted・manifest `rewritten`・Draft 解除 → **Merge** `a2e4686`・#1/#2 クローズ）
- [x] コスパ最適化（**ADR-0021**）: `gpt-4.1-mini`=retired / `gpt-4o-mini`=utility 429 で失敗（[postmortem 0002](postmortems/0002-cheap-model-rate-limit.md)）→ **`gpt-5-mini` で triage を実走＝12.99 AIC（前回 102 AIC の約1/8）・429 なし・1 Issue で bounded 停止**（run 28315044876, 2026-06-28）。**triage = `gpt-5-mini` を採用**。migrate/verify は生成・判断が重く default（claude-sonnet）維持（ADR-0021/0022）。

### ループ運用の改善バックログ（2026-06-28 NUMVAL ループで判明）
> 縦切り3本（interest/trim/numval）を回して見えた、ループ自体の改善余地。移行の個別タスクは GitHub Issue、これら運用改善はこのボードで追う。
- [ ] **【中】verify の Next 起票で重複防止**: verifier（claude-sonnet）が Next Issue を起票する際、既存 open `[migrate]` Issue を確認せず再起票 → #9 と #12（両 UNSTRING）の重複が発生（#12 をクローズ集約済）。`verify.md` / `verifier.agent.md` に「既存 open migrate Issue を検索し、対象が既起票なら新規作成しない」手順を追加。（discovery の triage/`gpt-5-mini` は既存を避けた＝対照的）
- [ ] **【中】migrate の heavy profile 改善（DeterministicOps）**: numval migrate=27 turns・1.70M tok・130 AIC、約50%が data-gathering（`gh aw audit` [HIGH]）。COBOL ソース読込・manifest 参照など決定的な前処理を frontmatter steps（pre-agent, `/tmp/gh-aw/agent/`）へ前倒しして推論コストを削減。
- [ ] **【中】Maven firewall allow-list**: migrate が `repo.maven.apache.org:443` をブロックされた（audit [MEDIUM]）。ネットワーク allow-list へ追加するか、依存を事前取得してオフライン build にする。
- [ ] **【低】NUMVAL の HR#2/#3（future work）**: `FUNCTION NUMVAL` / `PIC 9(10)` に非数値文字列を渡した場合の GnuCOBOL 挙動が未確認。`specs/numval-test.md` に Confirmed Limitation として記録するか、追加 golden ケースを足す。
- [ ] **【低】review 系 prog の `format` 設定**: json/xml/merge/report/sql/sub/main は manifest に `format` 未設定（shamrice 由来＝全て fixed の想定）。各々の移行時に `format: fixed` を設定（unstring/search/redefines/comp/numval は設定済・commit 07bed28）。
- [ ] **【低】Issue #4 の整理**: interest 後処理の旧 Issue（2026-06-27）。完了済み項目が多く open のまま。クローズ可否を判断。
- [ ] **【任意】ADR-0023 §3-§6 の playbook 切り出し**: supervisor/planner/executor/checker の実行フロー・判断表を運用 playbook に外出し（Accept 済なので任意）。

### 構造抽出 & 依存解析（ADR-0019・移行順序決定の前段）
- [x] **spec-extract**: `tools/spec-extract/`（`extract.sh`/`spec.scm`/`format.awk`）で COBOL→spec 骨子。grammar を **gzip 凍結 vendoring**（clone のみで動く・ADR-0019 Accepted）。interest で `specs/interest.md` と完全一致を実証
- [ ] **【明日】横展開**: legacy OK 群（`trim`/`unstring`/`search`/`redefines`/`comp`/`numval`）で抽出を試し、クエリ（`spec.scm`）の汎用性を確認・改善
- [x] **依存解析ツール `tools/deps`**: `PROGRAM-ID`/`CALL`/`COPY`/`EXEC SQL`/`ASSIGN file` を抽出 → プログラム間**依存グラフ（mermaid）＋葉優先順＋移行可否**を出力（`tools/deps/analyze.sh` 実装済み, 2026-06-28）
- [x] **manifest 拡張**: `manifest.yaml` に依存フィールド（calls/copybooks/sql/files/hotspots/kind/migratable）を追加（2026-06-28）
- [x] **triage 拡張**: 依存グラフを使った優先規則（葉・バッチ・決定的を優先、画面/SQL/帳票を後段）を `triage.md` / `triage.agent.md` に反映（2026-06-28）
- [ ] COPY 展開本体（題材が出たら。現状は検出 warning のみ）

### ドキュメント整合 — spec-extract（ADR-0019）反映【✅ 2026-06-28 完了】
> tree-sitter spec-extract 導入を既存ドキュメントへ反映。8ファイルをまとめて commit。
- [x] **【高】`README.md`**: ディレクトリ構成に `tools/spec-extract/` を追記／セットアップに **tree-sitter CLI** 要件＋「clone のみで動く（vendoring・ネット不要）」
- [x] **【高】`.github/copilot-instructions.md`**: skill routing の `cobol-to-spec` に実装ツール `tools/spec-extract` への参照を追加（Copilot がツールを発見できるように）
- [x] **【高】`docs/architecture.md`**: 全体フロー図の Code→Doc を **tree-sitter 機械化**として可視化（今は手作業に見える）
- [x] **【中】`.github/agents/spec-extractor.agent.md` ＋ `agents/README.md`**: 実装ツール（tree-sitter / spec-extract）への言及を追加
- [x] **【中】`.github/workflows/README.md`**: migrate の Code-to-Doc 工程に spec-extract 言及
- [x] **【中】`docs/plan.md`**: パイプライン図の Code→Doc に tree-sitter の役割を追記
- [x] **【低】`docs/loop-engineering.md`**: 5層マッピングの Skills 具体例に構造抽出を追加
- [ ] **【任意】`tools/README.md` / `tools/spec-extract/README.md`** 新規作成（「不要な MD を増やさない」方針と要相談）

### Phase 3.5 — デプロイ土台
- [ ] `Dockerfile`（多段: build=cobc / runtime=JRE, ADR-0013）
- [ ] `infra/*.bicep` ＋ `azure.yaml`（Container Apps）
- [ ] `.github/workflows/deploy.yml`（Entra OIDC, secretless）
- [ ] Azure MCP 配線（`.vscode/mcp.json`）

### Phase 4 — 発表
- [ ] `docs/presentation.md` / runbook
- [ ] Agent Scorecard サンプル（品質×コスパ, ADR-0014）— 観測の取り方: [docs/observability/gh-aw-audit.md](observability/gh-aw-audit.md)
- [ ] スクショ / CI ログ（ライブデモなし, ADR-0013）
- [ ] **`.devcontainer/`（Codespaces 配布環境）** — gh-aw拡張＋JDK＋GnuCOBOL（コンテナ＝cobc 可・ADR-0013）。チームが設定ゼロで `gh aw run` / L0（VS Code agent mode）を触れる。Codespaces の `gh` 自動ログインで共有トークン不要。**最後に作る（他が出来てから）**。

## 運用メモ
- 決定は **ADR**（agent は `Proposed` 止まり、人間が `Accepted`）。
- **Code→Doc 必須**: 各 `tests/<prog>/` に対応する `specs/<prog>.md` を出す（ADR-0015）。CI が存在を強制—縦切りでも spec を飛ばさない。
- skill は **Skill Quality 6条件**（ground truth / gate / artifact / order / completion / escape-hatch, ADR-0014）で書く。
- コミットは区切りごと、push は確認してから。
- **変換タスク（COBOL 1本ごと）は GitHub Issue**（このボードではなく）。
