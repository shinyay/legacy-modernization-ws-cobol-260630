# ADR-0011: リポジトリ構成（横割り・legacy 不変・gh-aw は .github/workflows・manifest）

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
外部のパブリック OpenCOBOL プロジェクトを取り込んで移行する。チーム 4 人が並行作業する。
ビルドの単純さ、プログラム単位の追跡性、役割分担のしやすさを両立したい。

## Decision
**種類別（horizontal）レイアウト**を採用する。
- `legacy/` … 移行元 COBOL を**原形のままベンダリング**（**不変 = golden の oracle**、改変しない）。出典・ライセンスは `legacy/UPSTREAM.md`。
- `app/` … 移行先 Java の**単一モジュール**（プログラムはパッケージで分ける）＋ fallback ＋ `Dockerfile`。
- `specs/<prog>.md`（Code→Doc）／ `tests/<prog>/{cmd,inputs,golden}`（golden）／ `tools/golden/`（runner）。
- `infra/*.bicep` ＋ `azure.yaml`（Azure）／ `samples/`（ドライラン用 自作 GnuCOBOL）。
- **gh-aw は `.github/workflows/`**（公式デフォルト、`.md`＋`.lock.yml`）。CI/deploy も同フォルダ。
- `manifest.yaml` … 移行対象 COBOL の台帳（triage が「次の 1 本」を選ぶバックログ）。

## Consequences
- **良い点**: ビルドが単純（単一 app）。`specs/` `tests/` でプログラム単位に追跡可能。4 人が役割別に並行しやすい。
- **悪い点 / トレードオフ**: 1 プログラムが `legacy/` `app/` `specs/` `tests/` に分散する（縦割りなら 1 フォルダだがビルドが複雑化）。
- **中立**: ライブな進行状況は Issues/Projects、静的 inventory は `manifest.yaml`、と役割分担。

## Alternatives considered
- 縦割り `programs/<prog>/`（spec+tests+java を同梱）→ Java ビルドが複雑化し 5h に不利。不採用。
- gh-aw をリポ直下 `workflows/` に置く流儀（autoloop 方式）→ 公式デフォルトの `.github/workflows/` 一元化を採用。

## References
- README.md / docs/plan.md §8
