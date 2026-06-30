# サブシステム設計書 — 16-fee（当日手数料徴収）

> **記入ガイド**: Java/PostgreSQL への モダナイゼーション設計書
> テンプレート参照: [subsystem-design-template.md](../templates/subsystem-design-template.md)
> 仕様出典: [specs-asis/02-transaction-pipeline.md](../specs-asis/02-transaction-pipeline.md)

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `16-fee`（当日手数料徴収） |
| ディレクトリ | [subsystems/16-fee/](../../../subsystems/16-fee/) |
| 分類 | トランザクション処理系（取引パイプライン） |
| API契約 | [copy/api/fee-api.cpy](../../../subsystems/16-fee/copy/api/fee-api.cpy) |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

当日に記帳完了した取引（transactions、status='PT'）に対し、手数料体系（07-feeschedule）を参照して該当する手数料を決定し、顧客口座から手数料収益勘定へ複式簿記（category=60）で徴収する。残高不足（NSF: No Sufficient Funds）の場合は処理をスキップし、結果をレポートする。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|---|
| 上流（呼び出し元） | `22-operations / ops-batch-daily.sqb` | 日次バッチの一部、記帳処理（12-txnpost）完了後に実行 |
| 下流（呼び出し先） | `12-txnpost`（複式簿記記帳エンジン）/ `21-audit`（監査記録） | 手数料記帳を delegate / 監査ログ投入 |
| 参照マスタ API | `07-feeschedule` (fs-api) | category + amount → tier → fee_jpy 参照 |
| 参照データ | `transactions` (status='PT') / `fee_schedules` / `accounts` / `account_balances` | TO-BE: PostgreSQL |
| パイプライン上の位置 | 記帳後（12-txnpost）の並列処理 | 利息・振替・手数料は同時実行可能 |

### 1.3 構成プログラム

| Program-ID | ファイル | 機能 | 主要PARAGRAPH |
|---|---|---|---|
| `FEE-CHARGE` | [src/fee-charge.sqb](../../../subsystems/16-fee/src/fee-charge.sqb) | 当日手数料徴収（メイン） | `M-START`, `LOAD-TXN-SNAPSHOT`, `LOOKUP-FEE-TIER`, `POST-FEE-PAIR`, `UPDATE-ACCT-BALANCE` |
| `FEE-REPORT-SUMMARY` | [src/fee-report-summary.sqb](../../../subsystems/16-fee/src/fee-report-summary.sqb) | 日次手数料収益レポート生成 | `M-START`, `GEN-REPORT`, `PG-CROSS-VERIFY` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | バッチ / 日次スケジュール（operationsから） |
| 実行契機 | 日次（営業日）、記帳処理（12-txnpost）完了後 |
| 多重度・冪等性 | **冪等不可** — 同一ビジネス日付で重複実行すると手数料が二重徴収される。ALREADY フラグで重複検出可 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
【FEE-CHARGE】
1. 入力パラメータ検証
   - BATCH-ID（14文字）、BUSINESS-DATE（YYYYMMDD）の形式チェック
   
2. PostgreSQL 接続（--with-db）
   
3. システム勘定の確認
   - 決済勘定（WS-CASH-ACCT = "0010010000001"）
   - 手数料収益勘定（WS-FEE-REV-ACCT = "0010010000004"）
   → 存在確認、有効状態確認
   
4. 当日取引のスナップショット取得
   - SELECT txn_id, account_number, amount, category
     FROM transactions
     WHERE business_date = BUSINESS-DATE
       AND status = 'PT'  （=記帳完了）
   - メモリにロード（MAX 500件）
   
5. 取引毎に処理ループ
   a) 当日手数料が既に徴収済みかチェック
      - WHERE source_txn_id = txn_id AND category = '60'
      → あれば SKIPPED-ALREADY でスキップ
      
   b) 手数料体系参照
      - category（取引区分） + amount（金額）から tier 決定
      - fs-api.FEE-LOOKUP-BY-TIER を CALL
      - 手数料額（fee_jpy）を取得
      
   c) 手数料=0の場合
      - SKIPPED-NO-FEE でスキップ（非対象商品など）
      
   d) 顧客口座の確認
      - 存在確認、ステータス確認（='A'）
      - status ≠ 'A' ⟹ SKIPPED-CLOSED でスキップ
      
   e) 顧客口座の残高確認
      - SELECT balance FROM account_balances
        WHERE account_number = account_number
      - balance < fee_jpy ⟹ NSF スキップ (SKIPPED-NSF)
      
   f) DOUBLE-ENTRY-HELPER に delegate
      - txn_id 生成（9000000002-indexed）
      - DR: 顧客口座 DEBIT account_number, fee_jpy
      - CR: 手数料収益勘定 CREDIT WS-FEE-REV-ACCT, fee_jpy
      - TXN-TYPE = "FEE-CHARGE" (category=60)
      - 成功 → `00` / 失敗 → `04`, `12` コード
      
   g) 成功時：
      - account_balances テーブル UPDATE（残高 -fee_jpy）
      - HISTORY / AUDIT ログ記録
      
6. 集計・統計
   - スキャン取引数（TXNS-SCANNED）
   - 徴収成功数（CHARGES-POSTED）
   - スキップカウンタ（NO-FEE, CLOSED, NSF, ALREADY, HELPER）
   - 合計徴収手数料（TOTAL-FEE-JPY）
   - 処理時間（DURATION-SEC）

【FEE-REPORT-SUMMARY】
1. サマリファイルを読み込み
2. 手数料体系別集計
3. 保存則検証（PG-CROSS-VERIFY）
4. 手数料収益勘定残高確認
5. レポート生成・出力
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | **当日限定** | business_date = BUSINESS-DATE のみ処理。ALREADY フラグで二重実行を検出 |
| 2 | **体系参照** | category（取引区分）+ amount（金額） → tier 決定 → fs-api.FEE-LOOKUP-BY-TIER で手数料額取得 |
| 3 | **手数料=0** | tier 照合で手数料=0の場合（非対象商品など）→ SKIPPED-NO-FEE でスキップ |
| 4 | **口座確認** | 存在確認、status='A'（有効）のみ処理。その他は SKIPPED-CLOSED |
| 5 | **残高確認** | balance < fee_jpy → NSF スキップ（徴収不可） |
| 6 | **複式簿記原則** | DR+CR がペア（借方=顧客口座、貸方=手数料収益勘定）。常に借方 = 貸方 |
| 7 | **システム勘定必須** | 決済/手数料収益勘定が存在し有効であること。欠落時 `16`（致命的） |
| 8 | **金額単位** | JPY のみ。COMP-3（zoned decimal）で精度保持 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | 全手数料徴収成功、または処理対象なし（取引0件） |
| `04` | 部分失敗 | 一部口座の徴収が失敗（NSF/CL など失敗理由記録） |
| `08` | 入力不正 | BATCH-ID / BUSINESS-DATE 形式エラー |
| `12` | I/O 失敗 | DB接続失敗、SQL エラー、fs-api 呼び出し失敗 |
| `16` | 致命的エラー | システム勘定（決済/手数料収益）欠落、fs-api 全体エラー |

### 2.4 排他・トランザクション制御

- **DB トランザクション**: 各手数料記帳は 12-txnpost（複式簿記エンジン）内の ACID トランザクション下で実行
  - リトライ可能な競合（SQLSTATE 40001/40P01）は指数バックオフで再試行
  - ロックタイムアウト（DEFER）は recon-defer ファイルに記録
  
- **行ロック**: transactions テーブルの行は SELECT FOR UPDATE で確保、重複処理防止
  
- **残高チェック**: account_balances の行を SELECT FOR UPDATE で確保、並行更新防止
  
- **監査記録**: 各手数料徴収を 21-audit に非同期投入（RabbitMQ or 同期 CALL）

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| DB接続失敗 | 戻り値12でリターン | shared-log-api 経由、レベル ERROR |
| SQL エラー（SELECT/UPDATE）| 戻り値12 / エラー理由コード | レベル ERROR、SQLCODE/SQLSTATE 記録 |
| fs-api 呼び出し失敗 | 戻り値16（全体エラー） | レベル ERROR |
| システム勘定欠落 | 戻り値16 | レベル ERROR（E025相当） |
| 複式簿記記帳失敗（NSF/CL など） | 失敗理由記録、スキップ | レベル INFO（業務ロジック） |
| リトライ FSM: CONFLICT | 指数バックオフで自動リトライ（max 5回） | レベル WARN, 最終失敗は ERROR |
| リトライ FSM: DEFER | recon-defer ファイル記録 | レベル WARN、後続ジョブ手動対応 |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: [copy/api/fee-api.cpy](../../../subsystems/16-fee/copy/api/fee-api.cpy)

#### FEE-CHARGE-INPUT（当日手数料徴収）

| COBOLフィールド名 | PIC | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `FEE-CHARGE-BATCH-ID` | `X(14)` | ✓ | バッチ実行ID（日時ベース） | 形式: `YYYYMMDDHHMISS`（14桁） |
| `FEE-CHARGE-BUSINESS-DATE` | `9(8)` | ✓ | 手数料徴収対象営業日 | 形式: YYYYMMDD（8桁数字）、営業日カレンダー登録済み |
| `FEE-CHARGE-SUMMARY-FILENAME` | `X(80)` | ✓ | 実績サマリファイル | 絶対PATH、FEE-REPORT-SUMMARY の入力ファイル |

#### FEE-REPORT-INPUT（レポート生成）

| COBOLフィールド名 | PIC | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `FEE-RPT-BUSINESS-DATE` | `9(8)` | ✓ | ビジネス日付 | YYYYMMDD |
| `FEE-RPT-BATCH-ID` | `X(14)` | ✓ | バッチID | FEE-CHARGE と同一 |
| `FEE-RPT-SUMMARY-FILENAME` | `X(80)` | ✓ | サマリ入力ファイル | FEE-CHARGE の出力 |
| `FEE-RPT-REPORT-FILENAME` | `X(80)` | ✓ | レポート出力ファイル | 人間可読形式（TSV/CSV） |

### 3.2 入力データソース

| 種別 | 名称 | 形式 | キー | 備考 |
|---|---|---|---|---|
| テーブル | `transactions` | PostgreSQL | `txn_id` (PK) / `business_date`, `status='PT'` | 当日記帳済み取引 |
| テーブル | `fee_schedules` | PostgreSQL | `(category, tier, effective_date)` (複合PK) | 手数料体系 |
| テーブル | `accounts` | PostgreSQL | `account_number` | 顧客口座、徴収先 |
| テーブル | `account_balances` | PostgreSQL | `account_number` | 残高確認 |
| マスタ API | `07-feeschedule` (fs-api) | CALL | category + amount → tier / fee_jpy | 手数料体系参照 |

### 3.3 前提・事前条件

- `transactions` テーブルに当日分の取引が status='PT' で記帳済み（12-txnpost 完了）
- `fee_schedules` テーブルが最新の手数料体系で LOAD 済み
- システム勘定（決済/手数料収益勘定）が accounts テーブルに存在し有効状態
- PostgreSQL への接続情報が環境変数設定済み
- fs-api（07-feeschedule）が正常に稼働している

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時）

#### FEE-CHARGE-OUTPUT（当日手数料徴収結果）

| COBOLフィールド名 | PIC | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `FEE-CHARGE-STATUS` | `X(2)` | 戻り値コード | 全ケースで設定（`00`/`04`/`08`/`12`/`16`） |
| `FEE-OUT-TXNS-SCANNED` | `9(7)` | スキャン対象取引数 | SELECT COUNT(*) WHERE business_date=BD AND status='PT' |
| `FEE-OUT-CHARGES-POSTED` | `9(7)` | 手数料徴収成功数 | トランザクション確定した取引数 |
| `FEE-OUT-SKIPPED-NO-FEE` | `9(7)` | スキップ：手数料=0（非対象商品） | fs-api 参照で fee_jpy=0 の場合 |
| `FEE-OUT-SKIPPED-CLOSED` | `9(7)` | スキップ：口座ステータス非有効 | 口座が status≠'A' または存在しない |
| `FEE-OUT-SKIPPED-NSF` | `9(7)` | スキップ：残高不足（No Sufficient Funds） | balance < fee_jpy |
| `FEE-OUT-SKIPPED-ALREADY` | `9(7)` | スキップ：既に徴収済み（同日重複） | category='60' のレコードが既存 |
| `FEE-OUT-SKIPPED-HELPER` | `9(7)` | スキップ：ロジック判定不可 | その他業務ルール違反 |
| `FEE-OUT-TOTAL-FEE-JPY` | `S9(15) COMP-3` | 徴収成功した合計手数料（JPY） | 符号付き 18桁、円単位 |
| `FEE-OUT-DURATION-SEC` | `9(5)` | 処理実行時間（秒） | 開始～終了の実時間 |

#### FEE-REPORT-OUTPUT（レポート生成結果）

| COBOLフィールド名 | PIC | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `FEE-RPT-STATUS` | `X(2)` | 戻り値コード | `00`/`04`/`08`/`12`/`16` |
| `FEE-RPT-TOTAL-CHARGES` | `9(7)` | レポート対象の手数料徴収総数 | サマリから復元 |
| `FEE-RPT-TOTAL-FEE-JPY` | `S9(15) COMP-3` | 徴収成功した手数料合計（JPY） | CHARGES-POSTED の金額合計 |
| `FEE-RPT-FEE-REVENUE-BAL` | `S9(15) COMP-3` | 手数料収益勘定残高（CR） | SELECT balance FROM accounts WHERE account_number=FEE-REV-ACCT |
| `FEE-RPT-CONSERVATION-PASS` | `X(1)` | 保存則検証結果 | `Y`=TOTAL-FEE-JPY==FEE-REVENUE-BAL, `N`=不一致 |
| `FEE-RPT-DURATION-SEC` | `9(5)` | レポート生成時間（秒） | — |

### 4.2 出力データ更新（更新系の場合）

| 種別 | 名称 | 操作 | 対象項目 | 備考 |
|---|---|---|---|---|
| テーブル | `postings` | INSERT | `posting_id`, `txn_id`, `account_number`, `debit_jpy`/`credit_jpy`, `category=60` | 複式簿記の明細（DR/CR ペア） |
| テーブル | `account_balances` | UPDATE | 顧客口座残高 -手数料, 手数料収益勘定残高 +手数料 | 各記帳後に更新 |
| 監査ログ | 21-audit | INSERT | action=`FEE-CHARGE-EXECUTE`, txn_id, fee_jpy | 監査記録（成功時） |
| ファイル | recon-defer-file | WRITE（追記） | SQLSTATE 40001/40P01 対象レコード | リトライ FSM: DEFER の場合のみ |

### 4.3 後続・事後条件

- **残高反映**: `account_balances` に即座に反映（顧客口座-手数料、手数料収益勘定+手数料）
- **監査記録**: 各手数料徴収取引を 21-audit へ記録（イベント キー=txn_id）
- **保存則**: TOTAL-FEE-JPY = 手数料収益勘定残高を検証（レポート出力時）

---

## 5. レコード定義

レコードレイアウト: `transactions` / `postings` / スナップショット: `WS-SNAPSHOT` / `WS-CUR`

### fee_schedules テーブル（PostgreSQL）

| フィールド名 | 型 | キー区分 | 説明 |
|---|---|---|---|
| `category` | CHAR(2) | 複合PK | 取引区分コード（例: `01`=振込） |
| `tier` | SMALLINT | 複合PK | 手数料ティア番号（金額帯による） |
| `effective_date` | DATE | 複合PK | 適用開始日 |
| `fee_jpy` | NUMERIC(15,0) | — | 手数料額（JPY） |
| `description` | VARCHAR(200) | — | 手数料説明 |
| `created_at` | TIMESTAMP | — | 作成日時 |
| `updated_at` | TIMESTAMP | — | 更新日時 |

### transactions テーブル（PostgreSQL、記帳済取引）

| フィールド名 | 型 | キー区分 | 説明 |
|---|---|---|---|
| `txn_id` | VARCHAR(18) | 主キー | 取引ID |
| `account_number` | VARCHAR(13) | 副キー (FK) | 主口座番号 |
| `business_date` | DATE | 副キー | 取引営業日 |
| `amount_jpy` | NUMERIC(15,0) | — | 取引金額（JPY） |
| `category` | CHAR(2) | 副キー | 取引区分（手数料参照用） |
| `status` | CHAR(2) | — | ステータス（PT=記帳済） |
| `created_at` | TIMESTAMP | — | 作成日時 |

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/ISAM） | TO-BE（Java/PostgreSQL） | 対応方針 |
|---|---|---|---|---|
| 1 | 取引マスタ | テンポラリテーブル/ファイル | `transactions` テーブル | DB テーブルマッピング |
| 2 | メモリスナップショット | OCCURS 500 配列 | List<> / HashMap 検討 | JVM メモリモデル、GC 対策 |
| 3 | 複式簿記記帳 | DOUBLE-ENTRY-HELPER CALL | txnpost サービス API化 | マイクロサービス化 |
| 4 | 手数料体系参照 | fs-api CALL（COBOL） | 07-feeschedule マイクロサービス化 | サービス化、再利用性向上 |
| 5 | Tier 決定ロジック | category + amount → tier 計算 | DB クエリ or プログラムロジック | 参照テーブル JOIN vs アルゴリズム |
| 6 | リトライFSM | SQLCODE 分類コード | SQLSTATE 標準コード | 標準 SQL エラーコード準拠 |
| 7 | 監査記録 | 別個ログファイル | `audit_logs` テーブル + イベントキュー | 監査ログ一元化 |
| 8 | マルチテナント対応 | 非対応 | tenant_id 列追加の検討 | 将来拡張性 |

---

## 7. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | リトライ FSM の詳細実装 | SQLSTATE 分類・バックオフ戦略を確認、Java 実装方針決定 | — | — |
| 2 | 複式簿記 API の詳細 | txnpost への delegate 仕様、リターンコード、エラー処理を確認 | — | — |
| 3 | fs-api マイクロサービス化 | 07-feeschedule を REST/gRPC 化する戦略、キャッシュ戦略 | — | — |
| 4 | Tier 決定ロジック | category + amount → tier のマッピング仕様を詳細確認 | — | — |
| 5 | メモリ効率化 | スナップショット 500件上限、大規模取引への対応（ページング等） | — | — |
| 6 | パフォーマンス要件 | 日次に 1000件/分以上の徴収要件確認、DB インデックス戦略 | — | — |
| 7 | 保存則検証の厳密性 | TOTAL-FEE-JPY ≠ 手数料収益勘定残高の場合のエスカレーション手順 | — | — |
| 8 | マルチ通貨対応 | 現在 JPY のみ、将来の通貨追加時の アーキテクチャ設計 | — | — |
| 9 | 手数料無料期間・キャンペーン | 除外ロジック、適用期間管理の実装方針 | — | — |

---

*テンプレートバージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, doc/work/modernization-brief.md*
