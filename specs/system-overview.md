# spec: system-overview — Practice Bank（COBOL 銀行業務バッチ）

> **Code→Doc 全体像**（ADR-0009）。出典＝ [legacy/legacy-modernization-ws-cobol-260630](../legacy/legacy-modernization-ws-cobol-260630)。
> 根拠（Makefile / db/migration / systemd / subsystems/*/src）と推測を分けて記す。詳細は `specs/subsystems/<id>-<name>.md`。
> 振る舞いの正は golden、intent の正はこの Doc 群（system-analyzer 抽出 → 人レビュー）。

## 概要
22 サブシステムから成る **銀行業務バッチ**。COBOL(GnuCOBOL) + 組込 SQL(OCESQL)、PostgreSQL、RabbitMQ、ISAM 固定長。
マスタ管理(01-08)→ 取引パイプライン(10-12)→ 日次決算(13/15/16/17/19/20)→ 月次(14/21)→ 監査(21)→ 統制(22)。

## サブシステム構成（根拠: Makefile SUBSYSTEMS, subsystems/*/src）
| # | name | 区分 | SQL | 主対象 |
|---|---|---|---|---|
| 01 | calendar | master/lib | - | calendar.idx |
| 02 | branch | master/lib | - | branch.idx |
| 03 | customer | master/lib | - | customer.idx |
| 04 | customersearch | online | - | - |
| 05 | product | master/lib | - | product.idx |
| 06 | interestrate | master/lib | - | interest_rates |
| 07 | feeschedule | master/lib | - | fee_schedules |
| 08 | account | master/lib | - | accounts.idx |
| 09 | accountlifecycle | batch | - | accounts.idx |
| 10 | txnvalidate | batch | - | (file) |
| 11 | txnsortmerge | batch | - | (file) |
| 12 | txnpost | batch | ✓ | accounts, audit_outbox |
| 13 | interestaccrual | batch | ✓ | accounts |
| 14 | interestpost | batch/月次 | ✓ | accounts |
| 15 | autodebit | batch | ✓ | accounts |
| 16 | fee | batch | ✓ | accounts, fee_schedules |
| 17 | statement | batch | ✓ | accounts |
| 18 | inquiry | online | ✓ | (参照) |
| 19 | integrationin | batch | - | (file) |
| 20 | integrationout | batch | - | audit_outbox |
| 21 | audit | batch/月次 | ✓ | audit_log, audit_outbox |
| 22 | operations | orchestrator | ✓ | batch_run |

## データモデル（根拠: db/migration V2/V3/V7）
accounts / customers / branches / products / calendar / interest_rates / fee_schedules /
transactions / postings / balances / interest_accruals / autodebit_schedules /
audit_log(月次 RANGE partition) / audit_outbox(transactional outbox) / batch_run。
金額=BIGINT(JPY)、利率=NUMERIC(7,6)、固定長 CHAR キー、JPY 固定 CHECK 制約。

## バッチ実行順序（根拠: ops-batch-*, systemd/*.timer）
- 日次 23:00 JST: 19→13→15→16→17→20(drain)→recon
- 月次 1日 02:00 JST: 14→21(partition rollover)
- 補助: autodebit-retry / dormancy-scan / partition-rollover

## PG / MQ / ISAM 役割
- **PostgreSQL**: 取引・残高・監査の権威ストア。Azure DB for PostgreSQL Flexible。
- **RabbitMQ**: audit_outbox → 外部連携 publish。当面コンテナ、stretch Service Bus。
- **ISAM(.idx)**: 01-08 マスタのローカル索引。Azure Files マウント。

## 縦切り候補（推測）
取引記帳パイプライン **19→10→11→12**（依存集約・hotspot 集中）。難所=12-txnpost(double-entry+SQL retry)/13-interestaccrual(COMP-3 精度)。

## Open Questions
- CALL 依存の確証（ops-batch の EXEC-STEP 連鎖から推定）。
- console / tests/e2e の golden 化範囲。
