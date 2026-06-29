# ADR-0015: Code→Doc 仕様（specs/<prog>.md）を必須化し CI で強制する

- **Status**: Accepted
- **Date**: 2026-06-27
- **Deciders**: @hagishun

## Context
ADR-0009 は移行方式を **Code→Doc→Code**（直訳=JOBOL を避け、業務仕様を `specs/<prog>.md` に起こしてから Java 生成）と定めた。
しかし Phase 2 の縦切り（`interest`）実装で、**この Code→Doc 工程が実際には飛ばされた**。golden 等価ゲートを緑にすることが
目先のゴールになり、候補 Java を COBOL から直接書いた（＝直訳）。`specs/interest.md` は後追いで作成して復旧した
（経緯: `docs/postmortems/0001-skipped-code-to-doc.md`）。

根本原因は構造的だった: **強制力のある軸（golden の CI required check）は守られ、強制力のない軸（Code→Doc）が
時間圧で落ちた**。"検証されないものはドリフトする" という本プロジェクトの主張が、自分のプロセスにそのまま当てはまった。
方法論（発表の主役）を口約束のままにすると、最初に削られる。

## Decision
**golden テストを持つ各プログラム（`tests/<prog>/`）には、対応する Code→Doc 仕様 `specs/<prog>.md` の存在を必須**とする。

- CI（`ci.yml`）に **spec 存在ゲート**を追加し、`specs/<prog>.md` が無い／空なら **fail**（merge ブロック）。
- ループの `migrate.md` / `verify.md` は、rewrite / PR の前に spec を生成・更新する（spec が成果物）。
- 本ゲートは **存在**を強制する（構造ゲート）。**内容の正しさ**は golden（振る舞い）＋人／verifier レビュー（intent）で
  別途担保する（ADR-0005 / ADR-0009）。

## Consequences
- **良い点**: Code→Doc を黙って飛ばせなくなる。living documentation が必ず残る。発表の主役（直訳しない）が構造的に守られる。
- **悪い点 / トレードオフ**: 存在 ≠ 正しさ（空でない spec でも質が低い可能性）。中身の質は別レビュー頼み。ごく小さな本でも spec を書く手間が増える。
- **中立**: gate を1つ増やす。将来 spec の最低項目（入出力契約・数値規則等）の lint を足す余地がある。

## Confirmation
- **Test-verifiable**: `ci.yml` の "Require Code→Doc spec" ステップが、`tests/<prog>/` ごとに `specs/<prog>.md` の存在を確認し、欠落で fail。
- **Review-verifiable**: hero サンプル（`interest`）が spec ＋ golden ＋ Java の3点を揃える。

## Alternatives considered
1. **運用ルール（ドキュメント）だけで徹底** — 強制力がなく、まさに今回飛ばした。却下。
2. **spec の内容まで自動検証** — 構文/項目 lint は可能だが intent の正しさは機械判定不能。まず存在ゲート、内容は人＋golden。段階導入。
3. **golden ゲートに含めず別 job 化** — 将来検討。今は同 job の早期ステップで fail-fast。

## References
- 関連 ADR: [0009](0009-code-to-doc-to-code-migration.md)（Code→Doc→Code）/ [0005](0005-golden-master-from-cobol-output.md)（golden master）/ [0014](0014-two-layer-scorecard-with-cost-efficiency.md)（Skill Quality）。
- ポストモーテム: `docs/postmortems/0001-skipped-code-to-doc.md`。
- skill: `.github/skills/cobol-to-spec/`（Code→Doc）。
