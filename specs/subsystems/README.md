# サブシステム仕様（統合・詳細）

本書は各サブシステムの仕様を以下から抽出して統合したものです。

- `manifest.yaml`（`subsystems:` 台帳）
- `subsystems/*/src`（COBOL/SQB ソースモジュール）
- `subsystems/*/tests`（ユニットテスト資産）

各サブシステムの詳細は個別ファイル `specs/subsystems/<id>-<name>.md` を参照してください。

注記:

- `confirmed` は manifest が status を confirmed としているもの。
- `inferred` はソース命名・CALL グラフ・SQL/ファイル I/O パターン・テストスクリプトから推定したもの。

---

## サブシステム索引

各サブシステムの詳細仕様は個別ファイルを参照してください。下表は概要の早見表です。

| # | name | 区分 | 信頼度 | SQL | モダナイズ先 | 仕様 |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | calendar | master | confirmed | - | init_job | [01-calendar.md](01-calendar.md) |
| 02 | branch | master | confirmed | - | init_job | [02-branch.md](02-branch.md) |
| 03 | customer | master | confirmed | - | init_job | [03-customer.md](03-customer.md) |
| 04 | customersearch | online | inferred | - | container_apps_service | [04-customersearch.md](04-customersearch.md) |
| 05 | product | master | confirmed | - | init_job | [05-product.md](05-product.md) |
| 06 | interestrate | master | inferred | - | init_job | [06-interestrate.md](06-interestrate.md) |
| 07 | feeschedule | master | inferred | - | init_job | [07-feeschedule.md](07-feeschedule.md) |
| 08 | account | master | confirmed | - | init_job | [08-account.md](08-account.md) |
| 09 | accountlifecycle | batch | inferred | - | container_apps_job | [09-accountlifecycle.md](09-accountlifecycle.md) |
| 10 | txnvalidate | batch | inferred | - | container_apps_job | [10-txnvalidate.md](10-txnvalidate.md) |
| 11 | txnsortmerge | batch | inferred | - | container_apps_job | [11-txnsortmerge.md](11-txnsortmerge.md) |
| 12 | txnpost | batch | confirmed | ✓ | container_apps_job | [12-txnpost.md](12-txnpost.md) |
| 13 | interestaccrual | batch | confirmed | ✓ | container_apps_job | [13-interestaccrual.md](13-interestaccrual.md) |
| 14 | interestpost | batch(月次) | confirmed | ✓ | container_apps_job | [14-interestpost.md](14-interestpost.md) |
| 15 | autodebit | batch | inferred | ✓ | container_apps_job | [15-autodebit.md](15-autodebit.md) |
| 16 | fee | batch | inferred | ✓ | container_apps_job | [16-fee.md](16-fee.md) |
| 17 | statement | batch | inferred | ✓ | container_apps_job | [17-statement.md](17-statement.md) |
| 18 | inquiry | online | inferred | ✓ | container_apps_service | [18-inquiry.md](18-inquiry.md) |
| 19 | integrationin | batch | confirmed | - | container_apps_job | [19-integrationin.md](19-integrationin.md) |
| 20 | integrationout | batch | confirmed | - | container_apps_job | [20-integrationout.md](20-integrationout.md) |
| 21 | audit | batch(月次) | confirmed | ✓ | container_apps_job | [21-audit.md](21-audit.md) |
| 22 | operations | orchestrator | confirmed | ✓ | container_apps_job | [22-operations.md](22-operations.md) |

---

## サブシステム間契約（重要）

- ファイルパイプライン（日次コア経路）:
  - `19-integrationin` -> `10-txnvalidate` -> `11-txnsortmerge` -> `12-txnpost`
- 財務クローズ経路:
  - 日次利息計算 `13-interestaccrual` -> 月末記帳 `14-interestpost`
- 請求/回収経路:
  - `15-autodebit` と `16-fee` が記帳側に作用し、明細表/照会/監査ビューが消費する。
- 連携/監査経路:
  - `12-txnpost` が outbox 証跡を書き込み -> `20-integrationout` が公開 -> `21-audit` が集計/フォレンジック。
- オーケストレーション経路:
  - `22-operations` がステップ実行と `batch_run` の状態遷移を統制する。

## 検証の推奨事項

- サブシステム単位で golden データセットを固定・維持する対象:
  - 数値精度経路（`12`, `13`, `14`, `16`）
  - エンコード/相互運用経路（`19`, `20`）
  - オーケストレーション冪等性（`22`）
- ソート/検索/レポート経路（`04`, `11`, `17`, `21`）の決定的な順序を保証する。
- 月/年境界・休日/休眠遷移（`01`, `09`, `14`）のエッジケース fixture を明示的に追加する。
