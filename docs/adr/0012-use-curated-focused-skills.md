# ADR-0012: Agentic Modernization では focused な Skill をキュレーションし index で運用する

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun（提案）

## Context
Agentic Modernization Loop では、ADR 作成・COBOL 解析・golden master 作成など、agent に**繰り返し実行させたい
手順**がある。これらを自然文の都度プロンプトではなく `SKILL.md` としてリポジトリ内に外部化すると、再利用しやすく
なる（5 層フレームワークの Skill 層 = ADR-0006、ADR 運用 = ADR-0001、`adr-authoring` skill と関連）。

一方で、Skill 系の研究・実践知見では、**Skill は有効だが、網羅的すぎる Skill や agent が自己生成した Skill は
必ずしも性能を上げない**ことが示唆されている。また:

- Skill が増えすぎると、agent が**どの Skill を使うべきか迷う**（検索・選択コスト）。
- Skill は強力な一方で、**誤った手順・古い判断・prompt injection 的リスク・memory poisoning 的リスク**を
  持ち込む可能性がある。

そのため、このリポジトリでは Skill を「多く作ること」ではなく、**「短く・具体的で・人間がレビューした手順として
維持すること」**を重視する。

## Decision
- このリポジトリでは、Agentic Modernization Loop のために `SKILL.md` を利用する。
- Skill は **人間がキュレーションしたもの**を基本とする。
- Agent が自動生成した Skill は、**そのまま採用せず、人間レビュー後に採用**する。
- Skill は**短く・具体的**で、**実行手順・制約・完了条件**が明確なものにする。
- Comprehensive な長大ドキュメントではなく、**focused な手順書**として作る。
- Skill は **Loop の工程単位**で focused にする。当面の中核 Skill:
  - `adr-authoring` — ADR を採番・書式・索引規約どおり作成
  - `cobol-to-spec` — Code→Doc（業務ルール・入出力・エッジケースを仕様に抽出）
  - `spec-to-java` — Doc→Code（spec から idiomatic Java 生成）
  - `cobol-java-wrapper` — fallback（`ProcessBuilder` で COBOL バイナリ起動）
  - `golden-master-testing` — COBOL 出力を golden に固定し等価性検証
  - （`cobol-gnucobol-dialect` は手順というより**参照知識**寄り。将来 instructions 層へ移す検討余地あり）
- Skill の数は、対象プログラム・方言が増えれば**自然に増える前提**に立つ。選択コストは「数を無理に絞る」ことではなく、**skill index（[`.github/skills/README.md`](../../.github/skills/README.md) のカタログ）**で発見性を担保する（各 skill の名前・目的・使うタイミングを一覧化）。
- 新しい Skill を追加する場合は、**既存 Skill で代替できない理由**を確認し、**skill index に追記**する。
- Skill の内容が**判断や承認に関わる**場合、**人間レビューのゲート**を残す。
- 特に ADR 作成 Skill では、**agent が単独で `Accepted` にしてはならず、人間合意前は `Proposed`** とする。

## Consequences
- **良い点**:
  - agent が毎回同じ手順を再導出しなくてよくなる。
  - ADR・COBOL 解析・golden master などの作業品質を安定させられる。
  - 人間がレビューした手順を repo 内メモリとして再利用できる。
  - skill index により、数が増えても**どれを使うかの発見性・選択性**を保てる。
  - ハッカソン後も提案・実案件化の資産として使える。
- **悪い点 / トレードオフ**:
  - Skill が増えると **skill index の維持**が必要（追記漏れで index が陳腐化するリスク）。
  - 短く保つため、詳細な背景や例は別ドキュメントに逃がす必要がある。
  - Agent の自己改善に任せきることはできず、人間のメンテナンスが必要。
  - Skill が古くなると、agent が古い判断を再利用するリスクがある。

## Confirmation
- **Review-verifiable**: 新規 Skill 追加時は、人間が内容・必要性・重複有無をレビューする。
- **Process-verifiable**: Skill の追加・大幅変更は PR に含め、ADR または PR コメントで理由を残す。
- **Test-verifiable**: golden master など検証系 Skill は、実際の CI / テストで期待通り動くことを確認する。
- **Review-verifiable**: ADR Skill により生成された ADR は、人間レビュー前は `Proposed` のままにする。

## Alternatives considered
1. **Skill を使わず、毎回プロンプトで指示する** — 柔軟だが、再現性が低く、判断や手順が散らばる。
2. **Agent に Skill を自己生成・自己更新させる** — 速いが、drift や誤った手順の蓄積、人間が意図しない変更のリスクがある。
3. **大きな包括的 Skill を 1 つ作る** — 一見便利だが、agent が重要箇所を見落としやすく、実行時に迷いやすい。
4. **Skill 数に厳しい上限を設ける（hard cap）** — 選択コストは下がるが、工程ごとに必要な focused skill を作れなくなり実態に合わない。本 ADR では数を制限せず、index で選択性を担保する。

## References
> ※出典はベンチ名のみ（URL は要確認）。
- **SkillsBench** — curated / focused skills の有効性と、self-generated / comprehensive skills のリスクを示す知見。
- **SkillLearnBench** — skill の継続学習は有効だが、自己フィードバックだけでは drift しうるという知見。
- **SkillRet** — skill が増えると検索・選択が課題になるという知見（→ 本 ADR では skill index で対応）。
- **SkillVetBench** — agent skills の自然言語命令層や multi-agent risk に関する安全性評価の知見。
- 関連 ADR: [0001](0001-record-architecture-decisions.md)（ADR 運用）/ [0006](0006-five-layer-framework-as-self-driving-loop.md)（5 層に Skill を含む）。関連 Skill: `.github/skills/adr-authoring/`。
