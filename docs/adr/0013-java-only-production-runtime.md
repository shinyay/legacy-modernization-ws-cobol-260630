# ADR-0013: 本番ランタイムは Java のみとし、GnuCOBOL は CI/ビルドと fallback に限定する

- **Status**: Accepted
- **Date**: 2026-06-26
- **Deciders**: @hagishun

## Context
移行方式は Strategy B（ADR-0004 / ADR-0008）= **rewrite（Java）優先・wrapper（ProcessBuilder→GnuCOBOL）fallback**。
golden master は**元 COBOL を実行した出力を「正」として固定**する（ADR-0005）ため、**golden を作る/比較する CI には GnuCOBOL（`cobc`）が必須**。

ここで「**本番（Azure Container Apps, ADR-0007）に GnuCOBOL が要るのか**」「コンテナ化すれば不要では」という疑問が出た。整理すると GnuCOBOL が要る場所は次のとおり:

- **CI / golden master**: 常に必須（正解を作る側。ADR-0005）。
- **本番ランタイム**: **rewrite した本は JRE のみで動く**。GnuCOBOL が要るのは **wrapper（fallback）で包んだ本を実際にデプロイ/実行する場合だけ**。
- **ローカル（Mac）**: 必須ではない。COBOL のビルド/実行/golden freeze は**コンテナ or CI**で代替できる。

加えて今回のハッカソンは**ライブデモの時間がない**。等価性・移行・稼働は**画面スクリーンショットと CI ログ**で提示できるため、**本番で fallback をライブ実行する要件はない**。

## Decision
- **本番（Azure Container Apps）の既定イメージは Java（JRE）のみ**とし、GnuCOBOL は**含めない**。
- GnuCOBOL（`cobc` / `libcob`）を要する場所を次に限定する:
  - **CI / golden master**: 必須（`ci.yml`）。
  - **wrapper（fallback）の本を実際に本番で動かす場合のみ**、その image に `libcob` ＋コンパイル済みバイナリを同梱する（multi-stage: build に `cobc`、runtime は JRE＋必要時のみ `libcob`）。
- **ローカル（Mac）には GnuCOBOL を入れない**。COBOL のビルド・実行・golden freeze は**コンテナ／CI**で行う。
- ショーケースは**ライブデモを行わず、スクリーンショット／CI ログ**で「rewrite→green」「fallback→green」「Azure 稼働」を提示する。よって**本番での live fallback 実行は必須要件としない**。

## Consequences
- **良い点**:
  - 本番イメージが軽い（JRE のみ）＝ サイズ・攻撃面・コスト減。
  - ローカル環境を汚さず、再現性が上がる（COBOL はコンテナ/CI に隔離）。
  - 「等価性の権威は CI（golden master）」という原則（ADR-0005）が一貫する。
  - 当日のライブ実行リスク（ネットワーク／環境差）を避けられる。
- **悪い点 / トレードオフ**:
  - wrapper の本を**本番で動かしたくなった場合**は、image 拡張（`libcob` 同梱）が別途必要。
  - スクショ／CI ログ提示なので、ライブの臨場感は出ない（代わりに確実性）。
  - golden を作る CI は引き続き GnuCOBOL 必須（この依存は消えない）。

## Confirmation
- **Review-verifiable**: 本番 `Dockerfile` の runtime ステージに GnuCOBOL/`libcob` が**含まれない**（rewrite 本のみデプロイ時）ことをレビュー。
- **Test-verifiable**: `ci.yml` が GnuCOBOL で golden を生成・比較し、required check として機能する。
- **Review-verifiable**: 発表資料に「rewrite→green / fallback→green / Azure 稼働」のスクショ・CI ログが含まれる。

## Alternatives considered
1. **本番にも GnuCOBOL を常時同梱**（rewrite/fallback 両対応） — image が重く、rewrite 本には不要。ライブ実行しないなら過剰。
2. **ローカル Mac に GnuCOBOL を入れて開発** — 速いが環境差・再現性低下。コンテナ/CI へ寄せる方が安全。
3. **ライブデモを行う** — 時間がなく当日リスク。スクショ／CI ログで代替できる。

## References
- 関連 ADR: [0004](0004-migration-strategy-rewrite-first-rehost-fallback.md)（Strategy B）/ [0005](0005-golden-master-from-cobol-output.md)（golden master）/ [0007](0007-deploy-to-azure-container-apps.md)（Container Apps）/ [0008](0008-rewrite-java-fallback-processbuilder.md)（Java＋ProcessBuilder fallback）。
