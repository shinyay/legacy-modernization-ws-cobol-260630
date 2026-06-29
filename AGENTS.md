# AGENTS.md — リポジトリ全体の指示（全エージェント共通）

このリポは「レガシー COBOL を **ドメイン分析(Code→Doc)し、rehost コンテナで Azure へ移行**する」。Java 直訳はしない（ADR-0027）。
全体計画: `docs/plan.md` ／ 概念: `docs/loop-engineering.md` ／ 判断: `docs/adr/`

## 原則
- **Code→Doc を必須**とし、業務仕様を `specs/` に抽出してドメインを再発見する。Java 逆語訳はしない。
- **golden master が振る舞いの正**。rehost コンテナの出力は `tests/.../golden/` と一致必須。
- 移行は **rehost（COBOL+OCESQL をコンテナでそのまま）**。ジョブ/サブシステム単位で ACA Jobs/Service へ（ADR-0026）。
- `legacy/` は**不変**（移行元の oracle）。**改変しない**。
- 重要な判断は **ADR**（`docs/adr/`）に残す。

## 場所
- 移行元: `legacy/<project>/`（出典・ライセンスは `legacy/UPSTREAM.md`）
- 業務仕様: `specs/<prog>.md` ／ テスト: `tests/<prog>/{cmd,inputs,golden}` ／ 移行先: `app/`（本番。サンプル/PoC は `samples/<prog>/java/`）
- ループ定義: `.github/workflows/{triage,migrate,verify}.md`（gh-aw, 手動 dispatch 可）
- 台帳: `manifest.yaml`（triage が次の 1 本を選ぶ）

## COBOL / 数値の注意
- COMP-3（packed decimal）・固定長レコード・丸め・桁を厳密に。
- 改行コード・文字エンコード・非決定性（日付 / 乱数 / 時刻）に注意（golden は入力固定・出力マスク）。
