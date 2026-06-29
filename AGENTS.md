# AGENTS.md — リポジトリ全体の指示（全エージェント共通）

このリポは「レガシー COBOL を **Code→Doc→Code** で Java へ検証付き移行し、Azure にデプロイする自走ループ」。
全体計画: `docs/plan.md` ／ 概念: `docs/loop-engineering.md` ／ 判断: `docs/adr/`

## 原則
- **直訳（COBOL→Java）禁止**。必ず `Code→Doc`（業務仕様を `specs/<prog>.md` に抽出）→ `Doc→Code`（Java 生成）。
- **golden master が振る舞いの正**。候補（rewrite / wrapper）は `tests/<prog>/golden/` と一致必須（CI required check）。
- **spec が無いと CI で落ちる（ADR-0015）**。各 `tests/<prog>/` には `specs/<prog>.md` が必須。CI は **3 ゲート**（① spec 存在 ② drift guard ③ 等価性）。
- **rewrite(Java) 優先**、budget 超で **fallback**（Java の `ProcessBuilder` で legacy COBOL を subprocess 実行）。
- `legacy/` は**不変**（移行元の oracle）。**改変しない**。
- 重要な判断は **ADR**（`docs/adr/`）に残す。ループ運用中は `verify.md` が周回ごとに移行判断の ADR を追記する。

## 場所
- 移行元: `legacy/<project>/`（出典・ライセンスは `legacy/UPSTREAM.md`）
- 業務仕様: `specs/<prog>.md` ／ テスト: `tests/<prog>/{cmd,inputs,golden}` ／ 移行先: `app/`（本番。サンプル/PoC は `samples/<prog>/java/`）
- ループ定義: `.github/workflows/{triage,migrate,verify}.md`（gh-aw, 手動 dispatch 可）
- 台帳: `manifest.yaml`（triage が次の 1 本を選ぶ）

## COBOL / 数値の注意
- COMP-3（packed decimal）・固定長レコード・丸め・桁を厳密に。Java は **BigDecimal**。
- 改行コード・文字エンコード・非決定性（日付 / 乱数 / 時刻）に注意（golden は入力固定・出力マスク）。
