---
name: <skill-name>            # フォルダ名と一致（小文字・ダッシュ）。例: cobol-to-spec
description: '<1行で何をするか>。USE FOR: <使う合図（Loop 工程・トリガ）>。DO NOT USE FOR: <使わない合図／隣接 skill との境界>。'
compatibility: GitHub Copilot (VS Code), Copilot CLI
---

# <skill-name>（<日本語で一言説明>）

<このスキルが「何を入力に何を出すか」を 1〜3 行で。直訳・重複を避ける一言方針も書く。>

## Skill Quality（6条件 / ADR-0014）

- **ground truth**: <唯一の正＝何を根拠にするか（例: `specs/<prog>.md` / golden）>。
- **gate**: <通過条件＝何が満たされたら次へ進めるか（例: golden 一致＝CI required check）>。
- **artifact**: <生成/更新する具体物＝どこに何を出すか（パスを明記）>。
- **order**: <Loop のどの工程か・前提となる先行成果物>。
- **completion criteria**: <完了の定義＝何を見て「終わった」と言えるか>。
- **escape-hatch control**: <禁止する近道（例: golden 手書き禁止 / `double` 禁止 / spec 無しで書かない / gate を緩めない）>。

## 手順

1. <ステップ>
2. <ステップ>
3. <検証（どの skill / gate で確認するか）>

## 品質チェックリスト

- [ ] frontmatter に `USE FOR:` / `DO NOT USE FOR:` / `compatibility` を書いた
- [ ] 本文に Skill Quality 6条件（ground truth / gate / artifact / order / completion / escape-hatch）を書いた
- [ ] 隣接 skill との境界（DO NOT USE FOR）が明確
- [ ] ground truth と gate が ADR / CI（`ci.yml`）と一致している

## 関連

- 関連 ADR: <ADR-NNNN …>
- 前工程 / 検証 / fallback: <隣接 skill 名>

<!--
このファイルは雛形であり、実スキルではない（`<skill-name>/SKILL.md` 形式でないため skill index には載らない）。
新規 skill の作り方:
1. `.github/skills/<skill-name>/SKILL.md` を作成し、この内容をコピーして埋める。
2. プレースホルダ <…> と、このコメントを必ず消す。
3. `README.md` の skill index 表に 1 行追加する（ADR-0012 / ADR-0014）。
-->
