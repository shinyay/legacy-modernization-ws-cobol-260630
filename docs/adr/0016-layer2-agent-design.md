# ADR-0016: 層2 エージェント設計 — maker/checker 分離・最小権限・source-of-truth 不可侵（awesome-copilot 準拠の .agent.md）

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun

## Context
5層フレームワークの層2（Agents・ADR-0006）を実体化するにあたり、各ループ工程（triage / Analyze / Code→Doc / Doc→Code / Verify）を `.github/agents/*.agent.md` として定義する必要があった。設計上の問いは3つ: **(1) ファイル書式と規約 / (2) 各エージェントの権限 / (3) maker と checker の関係**。

既存の価値観 — **golden = 振る舞いの正・不可侵**（ADR-0005）、**「検証されないものはドリフトする」**（ADR-0015）— をエージェント層にも一貫させたい。

コミュニティ標準として **github/awesome-copilot の `agents/` コレクション**を確認した。移行系（`oracle-to-postgres-migration-expert` 等）・ADR 生成（`adr-generator`）・React 移行スカッド（`react19-migrator` ＋ `react18-test-guardian` の **maker/checker 分離**）の実例があり、`.agent.md` の書式と実務的な落とし穴（**`name` 必須＝`title` 不可・`tools` 配列の末尾カンマ・無効/非名前空間ツール名は弾かれる**）が判明した。とくに oracle 例は「**source = 期待挙動の正・スキーマは immutable（本文で縛る）**」を採っており、本プロジェクトの golden 思想と一致していた。

## Decision
- **書式**: `.agent.md` は awesome-copilot 準拠。frontmatter = `name`（`title` 不可）/ `description`（`USE FOR:`・`DO NOT USE FOR:` 入り）/ `tools`（**配列・末尾カンマ禁止・公式の名前空間名**）/ 任意 `model`。本文は薄く保ち、手順は層3 Skill に委譲（ADR-0012）。
- **役割**: 5体（`triage` / `cobol-analyzer` / `spec-extractor` / `migrator` / `verifier`）をループ工程に 1 対 1 で対応させる。
- **最小権限**: `tools` をエージェントごとに絞る（analyzer = read-only、spec-extractor = `specs/` のみ書く、migrator = Java＋build、verifier = ADR＋verify 実行）。
- **maker / checker 分離**: 作る側（migrator）は **golden を触らない**。確認する側（verifier）は **コードを触らない**。ADR は `Proposed` 止まり（`Accepted` は人間・ADR-0012）。
- **source of truth 不可侵**: `legacy/` と `tests/<prog>/golden/` は**どのエージェントも編集しない**（本文ガードレールで明文化）。
- **GitHub 副作用は層4へ**: Issue / PR 発行は gh-aw（triage / migrate / verify）に寄せ、層2 は read / make に徹する。

## Consequences
- **良い点**: 権限が役割に一致し、checker が成果物を改変できない。golden / legacy をエージェントが壊せない。書式がコミュニティ標準に乗るので保守・流用が楽。本文が薄くスキルと二重管理にならない。
- **悪い点 / トレードオフ**: frontmatter の `tools` は**パス制限まではできず**、「migrator は golden を触らない」等は本文ガードレール頼み（強制力は弱い）。層2（ロジック）と層4 gh-aw（実行）で役割が一部重複する。
- **中立**: `.agent.md` は VS Code 用。gh-aw（層4）は別ランタイムで同じ役割境界を再現する（gh-aw 不調時の L0 手動デモの保険にもなる）。

## Confirmation
- **Review-verifiable**: 各 `.agent.md` の `tools` と本文ガードレールが、上表の最小権限・source-of-truth 不可侵に一致しているか。
- **将来**: gh-aw 配線時（層4）に同じ役割境界・不可侵を踏襲する。

## Alternatives considered
1. **1つの汎用エージェントで全工程** — maker と checker が混ざり、source of truth を改変するリスク。却下。
2. **全エージェントにフルツール付与** — 単純だが最小権限に反し、checker がコードを書けてしまう。却下。
3. **独自フォーマット** — 保守性・流用性で awesome-copilot 準拠に劣る。却下。

## References
- 関連 ADR: [0006](0006-five-layer-framework-as-self-driving-loop.md)（5層）/ [0009](0009-code-to-doc-to-code-migration.md)（Code→Doc→Code）/ [0011](0011-repository-structure.md)（リポ構成・1周1本）/ [0012](0012-use-curated-focused-skills.md)（focused skills・agent は Accepted にしない）/ [0013](0013-java-only-production-runtime.md)（本番 Java）/ [0015](0015-require-code-to-doc-spec-gate.md)（spec ゲート）。
- 参考: github/awesome-copilot `agents/`（`.agent.md` の実例・書式・落とし穴）。
- skills: `.github/skills/`（各エージェントが呼ぶ手順）。
