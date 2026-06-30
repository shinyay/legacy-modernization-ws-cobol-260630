# サブシステム設計書：14-interestpost（月末利息計上）

> **TO-BE 設計書** — COBOL/PostgreSQL から Java/Spring Boot/PostgreSQL への移行設計書

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `14-interestpost` — 月末利息計上 |
| ディレクトリ | [subsystems/14-interestpost/](../../../subsystems/14-interestpost/) |
| 分類 | トランザクション処理系（利息計上・複式簿記） |
| API契約（AS-IS） | [copy/api/ipst-api.cpy](../../../subsystems/14-interestpost/copy/api/ipst-api.cpy) |
| API契約（TO-BE） | `InterestPostingService` インターフェース（Java） |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

月末営業日に、13-interestaccrual で計算された日次利息（`interest_accruals.status='AC'`）を口座別に集計し、複式簿記（category=50、借方=決済勘定/貸方=顧客口座）で取引記帳として記録する。同時に `interest_accruals` のステータスを `'PT'`（計上済）に更新し、`balances` テーブルの各口座残高を利息分増加させる。月末利息計上の完全なプロセス。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|
| 上流（呼び出し元） | バッチスケジューラ（systemd timer） | 月末営業日に起動 |
| 上流（呼び出し元） | 13-interestaccrual | 当月分の利息を計算済状態で提供 |
| 下流（呼び出し先） | 12-txnpost ロジック | 複式簿記記帳の共通ヘルパー（`DOUBLE-ENTRY-HELPER`） |
| 下流（呼び出し先） | 20-integrationout | 利息計上イベントを RabbitMQ へ発行 |
| 下流（呼び出し先） | 21-audit | 月末利息計上開始・完了・エラーを記録 |
| 参照データ | `interest_accruals` テーブル | status='AC' の月内累積利息 |
| 参照データ | `accounts` テーブル | 口座マスタ（ステータス、商品） |
| 参照データ | `balances` テーブル | 口座残高（更新対象） |
| 参照データ | `transactions`, `postings` テーブル | 複式簿記記帳の出力先 |
| 参照データ | `business_calendar` テーブル | 月末営業日判定 |

### 1.3 構成プログラム

| 主要クラス/メソッド | パッケージ | 機能 | 主要ロジック |
|---|---|---|---|
| `InterestPostingService` | `com.practice.interestpost.service` | 月末利息計上の主オーケストレーション | `runMonthEnd(businessDate)` |
| `AccrualAggregator` | `com.practice.interestpost.aggregator` | 日次利息を口座別に集計 | `aggregateByAccount(accruals)` |
| `DoubleEntryHelper` | `com.practice.interestpost.posting` | 複式簿記記帳（共用部品） | `postInterest(account, amount, date)` |
| `InterestPostingRepository` | `com.practice.interestpost.repository` | DB操作（集計、更新） | `findAccrualsForMonthEnd(month)`, `updateStatus()` |
| `BalanceUpdater` | `com.practice.interestpost.balance` | 口座残高の更新 | `updateBalance(accountId, amount)` |
| `PostingValidator` | `com.practice.interestpost.validator` | 記帳検証・保存則 | `validate(txns, postings, balanceChanges)` |
| `ConservationLawValidator` | `com.practice.interestpost.validator` | 保存則検証（資金循環） | `validateConservationLaw(postings)` |
| `MonthEndCheckpoint` | `com.practice.interestpost.checkpoint` | チェックポイント記録・復帰 | `saveCheckpoint(month, postedCount)` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | バッチ（systemd timer） |
| 実行契機 | 月末営業日終了時。毎月 1 回。 |
| 多重度・冪等性 | 完全冪等。同一月の再実行は同一結果を生成。ステータス確認で重複防止。 |
| リカバリ | 中断時：チェックポイント記録により続行可能。再実行時：前回の完了口座数から再開。 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
1. 入力パラメータ検証
   - businessDate: YYYYMMDD 形式、月末営業日であること
   - batchId: バッチ追跡用
   - checkpointFile: チェックポイント保存先

2. 前提条件確認
   - businessDate が月末営業日？（business_calendar で検証）
   - 当月の利息計算（status='AC'）は完了済み？（COUNT で確認）
   - 当月の利息計上（status='PT'）が未実施？（既に PT なら戻り値 04）

3. 集計フェーズ
   SELECT account_id, SUM(accrued_amount_jpy) as total_interest
   FROM interest_accruals
   WHERE accrual_date BETWEEN '2026-06-01' AND '2026-06-30'
   AND status = 'AC'
   AND account_id IN (SELECT account_id FROM accounts WHERE status IN ('A', 'D'))
   GROUP BY account_id

   結果をメモリ内スナップショット（最大 10,000 口座）に保持

4. 口座別記帳ループ
   FOR EACH (account_id, total_interest) IN snapshot:
   a. 対象口座の検証
      - ステータス チェック（A/D 以外は SKIP）
      - 商品チェック（利息対象商品か確認）
      - 既計上チェック（既に status='PT' なら SKIP → SKIPPED-ALREADY）
   b. 複式簿記記帳（category=50）
      - txn_id 生成（9000000001 + sequential）
      - 記帳区分コード: 50（利息）
      - `DOUBLE-ENTRY-HELPER` 呼び出し
        - DR（借方）: 決済勘定（0010010000002）、金額 = total_interest
        - CR（貸方）: 顧客口座（account_id）、金額 = total_interest
      - INSERT INTO transactions (txn_id, status='PT', category=50, posting_date)
      - INSERT INTO postings (2 行: DR+CR）
      - リトライ FSM（SERIALIZABLE トランザクション）
   c. 口座残高更新
      - UPDATE balances SET closing_balance = closing_balance + total_interest
      - balance_date = businessDate
   d. 利息ステータス更新
      - UPDATE interest_accruals SET status = 'PT' WHERE account_id = :id AND accrual_date <= :business_date AND status = 'AC'

5. エラーハンドリング
   - 記帳失敗（CONFLICT/DEFER）: recon-defer ファイルへ、SKIPPED-HELPER +1
   - 残高更新失敗: SKIPPED-HELPER +1
   - ステータス更新失敗（一部のみ PT）: 警告ログ、SKIPPED-ALREADY +1

6. 統計情報の計算
   - ACCOUNTS-AGGREGATED: 集計対象口座数
   - POSTED: 正常に記帳した口座数
   - SKIPPED-CLOSED: ステータス C/S の口座
   - SKIPPED-PRODUCT: 利息対象外商品の口座
   - SKIPPED-ALREADY: 既に status='PT' の利息
   - SKIPPED-HELPER: 記帳ヘルパー失敗
   - AC-ROWS-CONSUMED: 処理した利息行数（Σ利息件数）
   - TOTAL-POSTED-JPY: 合計計上額（JPY）

7. 保存則検証
   - 貸方合計（利息金額の合計）= 借方合計（決済勘定への振替）
   - 資金保存（Σ利息 ≥ 0）
   - 統計ログ出力（INFO レベル）

8. チェックポイント更新
   - 月末日
   - 計上口座数
   - 計上総額
   - checkpoint_created_at

9. イベント発行
   - event_type = 'interest.posted'
   - 20-integrationout へ通知

10. 監査ログ記録
    - action = 'INTEREST_POST_RUN_MONTHEND'
    - result_code = status
    - accounts_aggregated, posted, total_amount など
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | 集計期間 | 月初（例：2026-06-01）から月末営業日（例：2026-06-30）までの status='AC' 利息 |
| 2 | ステータス遷移 | AC（計算済） → PT（計上済）。CN（取消）は計上対象外。 |
| 3 | 口座フィルタ | status='A'（稼働）or 'D'（休眠）のみ対象。C/S は SKIP。 |
| 4 | 複式簿記 | category=50、DR=決済勘定(0010010000002)、CR=顧客口座。金額は対称。 |
| 5 | txn_id 体系 | 9000000001～9999999999 の範囲。自動採番。 |
| 6 | リトライ | 記帳失敗時のリトライ（CONFLICT/DEFER）。最大 5 回。 |
| 7 | 冪等性 | 同一月の再実行で同一結果。既に PT のレコードはスキップ。 |
| 8 | 残高更新 | 利息計上と同時に balance 更新。balance_date = businessDate。 |
| 9 | 保存則 | Σ(DR) = Σ(CR)（複式簿記の原則）。同時に Σ利息 > 0 であるべき。 |
| 10 | 排他制限なし | 利息計上は月末に 1 回のみ。並行実行の可能性は低い。 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | 全集計対象口座の利息を計上完了。 |
| `04` | 部分完了 | 一部の口座で記帳ヘルパー失敗があったが、処理は続行。SKIPPED-HELPER > 0。 |
| `08` | 入力不正 | businessDate 形式エラー / 月末営業日でない / batchId 不正。 |
| `10` | EOF（対象なし） | 当月の status='AC' 利息がない。ACCOUNTS-AGGREGATED=0。 |
| `12` | I/O失敗 | DB接続失敗 / SELECT タイムアウト / UPDATE 失敗。リトライ対象。 |
| `16` | 致命的エラー | 集計失敗 / 計算エラー / OUT OF MEMORY / 予期しない例外。スタックトレース出力。 |

### 2.4 排他・トランザクション制御

- **SERIALIZABLE トランザクション**：複式簿記記帳は `SERIALIZABLE` 分離レベルで実行。デッドロック回避のため、アカウントをソートして一定順序でロック。
- **複数テーブル更新**：transactions、postings、balances、interest_accruals を同一トランザクション内で更新。
- **ロック順序**：account1 < account2（決済勘定 < 顧客口座）の順でロック。デッドロック防止。
- **チェックポイント**：月別に記録。同一月の重複実行を検出。
- **監査記録**：計上完了時に非同期で 21-audit へ記録（監査失敗は無視）。

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| 集計対象なし（AC 利息なし） | 戻り値 `10` 返却。統計=0。 | INFO: "No accruals found for month-end posting" |
| 口座ステータス不適格 | SKIP。SKIPPED-CLOSED +1 | DEBUG: "Account {id} status ineligible: {status}" |
| 商品が利息対象外 | SKIP。SKIPPED-PRODUCT +1 | DEBUG: "Account {id} product non-interest-bearing" |
| 既に status='PT' | SKIP。SKIPPED-ALREADY +1 | INFO: "Accruals already posted for account {id}" |
| 記帳ヘルパー失敗（CONFLICT） | リトライ FSM 実行 | WARN: "Posting conflict for account {id}, retrying..." |
| 記帳ヘルパー失敗（枯渇） | SKIP。SKIPPED-HELPER +1 | WARN: "Posting failed after retries for account {id}" |
| 残高更新失敗 | SKIP。SKIPPED-HELPER +1 | WARN: "Balance update failed for account {id}: {reason}" |
| 保存則不一致 | ログ警告。統計情報に記録。処理続行。 | WARN: "Conservation law violation: DR_sum={dr}, CR_sum={cr}" |
| DB 接続タイムアウト | 即座に `12` 返却。スタックトレース出力。 | ERROR: "Database connection timeout after {sec}s" |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: `com.practice.interestpost.api.InterestPostingRunRequest`

| パラメータ名 | 型 | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `businessDate` | LocalDate (YYYYMMDD) | ✓ | 月末営業日 | 月末営業日であること。business_calendar で検証。 |
| `batchId` | String | ✓ | バッチ追跡用ID | UUID または `YYYYMMDDHHMMSS` 形式。デフォルト自動生成。 |
| `checkpointFile` | String | — | チェックポイント保存ファイルパス | 相対パス時は `$DATA_HOME/checkpoints/` を基点。 |
| `maxRetries` | Integer | — | リトライ回数 | 1～10。デフォルト 5。 |
| `skipAlreadyPosted` | String | — | 既計上利息をスキップ | `Y`（スキップ）/ `N`（エラーで止める）。デフォルト `Y`。 |
| `forceRecompute` | String | — | 再計上強制実行 | `Y`（既に PT でも再実行）/ `N`（スキップ）。デフォルト `N`。通常は `N`。 |

### 3.2 入力データソース

| 種別 | テーブル | 形式 | キー | 備考 |
|---|---|---|---|---|
| 利息データ | `interest_accruals` | PostgreSQL | `accrual_id` (pk) | status='AC'、当月分 |
| マスタ | `accounts` | PostgreSQL | `account_id` (pk) | ステータス A/D/C/S でフィルタ |
| マスタ | `products` | PostgreSQL | `product_id` (pk) | 利息対象フラグ確認 |
| マスタ | `business_calendar` | PostgreSQL | `calendar_date` (pk) | 月末営業日判定 |
| 参照 | `balances` | PostgreSQL | `account_id` (pk) + `balance_date` (sk) | 更新対象 |
| 参照 | `transactions`, `postings` | PostgreSQL | — | 複式簿記記帳先 |

### 3.3 前提・事前条件

- データベース（PostgreSQL）が稼働し、全テーブルに読取・書込権限があること
- 指定された `businessDate` は月末営業日であること（business_calendar で検証）
- 当月の 13-interestaccrual が完了済み、status='AC' の利息が存在すること
- `$DATA_HOME` 環境変数が設定されており、チェックポイントディレクトリが存在または作成可能であること

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時）

API契約: `com.practice.interestpost.api.InterestPostingRunResponse`

| パラメータ名 | 型 | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `status` | String | 戻り値コード | `00`/`04`/`08`/`10`/`12`/`16` |
| `businessDate` | LocalDate | 月末営業日 | リクエストの businessDate をエコーバック |
| `batchId` | String | バッチID | 入力された batchId または自動生成値 |
| `accountsAggregated` | Integer | 集計対象口座数 | status='A','D' でフィルタ後のカウント |
| `posted` | Integer | 正常に計上した口座数 | {count} |
| `skippedClosed` | Integer | 解約/停止口座数 | status != 'A','D' |
| `skippedProduct` | Integer | 利息対象外商品の口座 | is_interest_bearing = false |
| `skippedAlready` | Integer | 既計上済の口座 | status='PT' で既にある |
| `skippedHelper` | Integer | 記帳ヘルパー失敗口座 | リトライ枯渇 |
| `acRowsConsumed` | Integer | 処理した利息行数 | Σ(AC 利息件数) |
| `totalPostedJpy` | BigDecimal | 合計計上額（JPY） | 保存則検証用 |
| `durationMs` | Long | 処理時間 | ミリ秒単位 |
| `checkpointId` | String | チェックポイントID | 再実行用の復帰ポイント（UUID） |

### 4.2 出力データ更新

| 種別 | テーブル | 操作 | 対象列 | 備考 |
|---|---|---|---|---|
| 取引 | `transactions` | INSERT | txn_id, category=50, status='PT' | 利息計上取引 |
| 振替記帳 | `postings` | INSERT（2行） | posting_id（DR/CR） | 複式簿記の 2 行 |
| 残高 | `balances` | UPDATE | closing_balance += 利息額 | 月末営業日現在 |
| 利息 | `interest_accruals` | UPDATE | status='AC' → 'PT' | 計上完了状態 |
| チェックポイント | `interestpost_checkpoints` | INSERT | business_date, posted_count | 再実行時の復帰 |
| 監査ログ | 21-audit | INSERT（非同期） | action='INTEREST_POST_RUN_MONTHEND' | 実行記録 |

### 4.3 後続・事後条件

- 計上された取引（category=50）は会計上の確定取引として残高に反映
- 利息ステータスの PT 遷移により、翌月以降の利息計上対象から除外
- イベント発行（20-integrationout）により、外部システムに利息計上を通知
- チェックポイント記録により、月末処理中断時の復帰が可能
- 監査ログにより、いつ・どの月の利息を計上したか、計上額が追跡可能

---

## 5. レコード定義

### 5.1 入力レコード（AggregatedInterest）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `account_id` | String(13) | 口座ID |
| `aggregated_accrued_jpy` | BigDecimal | 月内累積利息（JPY） |
| `accrual_count` | Integer | 利息行数（日数） |

### 5.2 出力レコード（InterestPostingTransaction）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `txn_id` | String(16) | 9000000001 系列 |
| `category` | String(2) | 50 固定 |
| `posting_date` | LocalDate | 月末営業日 |
| `dr_account_id` | String(13) | 決済勘定（0010010000002） |
| `dr_amount_jpy` | BigDecimal | 利息額（借方） |
| `cr_account_id` | String(13) | 顧客口座 |
| `cr_amount_jpy` | BigDecimal | 利息額（貸方） |
| `status` | Char(2) | PT 固定 |

### 5.3 バランス更新（BalanceUpdate）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `account_id` | String(13) | 口座ID |
| `balance_date` | LocalDate | 月末営業日 |
| `opening_balance` | BigDecimal | 月初残高 |
| `interest_increase_jpy` | BigDecimal | 利息増加分 |
| `closing_balance` | BigDecimal | 月末残高（opening + interest） |

### 5.4 利息ステータス更新（InterestAccrualStatusUpdate）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `accrual_id` | String(36) | UUID |
| `account_id` | String(13) | 口座ID |
| `accrual_date` | LocalDate | 計算基準日 |
| `status_before` | Char(2) | AC（計算済） |
| `status_after` | Char(2) | PT（計上済） |
| `posted_at` | LocalDateTime | 計上日時 |

### 5.5 チェックポイント（InterestPostingCheckpoint）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `checkpoint_id` | String(36) | UUID |
| `month_end_date` | LocalDate | 月末営業日 |
| `posted_account_count` | Integer | 計上済口座数 |
| `total_posted_jpy` | BigDecimal | 合計計上額 |
| `checkpoint_created_at` | LocalDateTime | チェックポイント作成日時 |

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/Embedded SQL） | TO-BE（Java/Spring Boot） | 対応方針 |
|---|---|---|---|---|
| 1 | プログラム言語 | COBOL（SQB） | Java（Spring Boot） | クラス設計で保守性向上 |
| 2 | 集計処理 | SQL GROUP BY または COBOL ループ集計 | Spring Data JPA / SQL GROUP BY | パフォーマンス維持 |
| 3 | 複式簿記 | `DOUBLE-ENTRY-HELPER` CALL | DoubleEntryHelper クラス（共用） | 共通化・疎結合 |
| 4 | リトライ | COBOL EVALUATE 手動制御 | Spring Retry / @Retryable | 宣言的・保守性向上 |
| 5 | チェックポイント | ファイル保存 | DB メタデータテーブル | 永続化・問合せ容易 |
| 6 | 残高更新 | SQL UPDATE | Spring Data JPA / JDBC | ORM で型安全化 |
| 7 | 統計情報 | ファイル / メモリ変数 | Response オブジェクト | 構造化・監視容易 |
| 8 | 監査ログ | 同期 CALL | Spring Event / 非同期 Event Listener | 疎結合・パフォーマンス向上 |
| 9 | エラーハンドリング | COBOL EVALUATE ネスト | Java Exception 階層 | スタックトレース自動ログ |
| 10 | 本番/テスト分岐 | COBOL IF 条件分岐 | Spring Profile（dev/prod） | 環境分離・クリア |

---

## 7. 複式簿記記帳の詳細（DOUBLE-ENTRY-HELPER）

### 7.1 利息計上の記帳スキーム

```
取引科目: 利息計上（category=50）

借方（DR）:
  科目: 決済勘定（決済用）
  口座: 0010010000002（システム勘定）
  金額: aggregated_interest_jpy

貸方（CR）:
  科目: 顧客口座
  口座: account_id（対象口座）
  金額: aggregated_interest_jpy

複式簿記の原則:
  Σ(借方) = Σ(貸方)

例:
  Account-A: 1,000 JPY の利息 → DR 決済 1,000 / CR Account-A 1,000
  Account-B: 500 JPY の利息  → DR 決済 500 / CR Account-B 500
  ___
  小計:                    DR 決済 1,500 / CR 顧客 1,500

この例では決済勘定に 1,500 が計上され、顧客側に利息が反映される。
```

### 7.2 リトライ FSM（SERIALIZABLE トランザクション）

```
[INIT]
  ↓
[VALIDATE_ACCOUNT]
  ├→ [ERROR: 不適格] → SKIP
  └→ [LOCK_ACCOUNTS: SERIALIZABLE]
     - account1 ロック（決済勘定）
     - account2 ロック（顧客口座）
     ↓
     [INSERT_TRANSACTION]
       → INSERT INTO transactions (txn_id, status='PT', category=50, ...)
     ↓
     [INSERT_POSTINGS]
       → INSERT INTO postings (DR)
       → INSERT INTO postings (CR)
     ↓
     [UPDATE_BALANCES]
       → UPDATE balances WHERE account_id = account1
       → UPDATE balances WHERE account_id = account2
     ↓
     [CLASSIFY_RESULT]
       ├→ SQLCODE=0 → [SUCCESS: COMMIT]
       ├→ SQLSTATE 40001/40P01 → [CONFLICT: リトライ]
       │  └→ [RETRY_LOOP: 最大5回]
       ├→ ロックタイムアウト → [DEFER: recon-defer]
       └→ その他 → [FATAL: エラー]
```

---

## 8. 並行実行・スケーラビリティ

### 8.1 月末の単一実行

通常、月末利息計上は 1 ヶ月に 1 回のみ実行されるため、並行実行の懸念は低い。ただし、再実行時の冪等性を確保するため：

```
チェックポイント制約：
  CREATE UNIQUE INDEX uq_interestpost_month
    ON interestpost_checkpoints(month_end_date)

既計上判定：
  SELECT 1 FROM interest_accruals
  WHERE accrual_date BETWEEN :month_start AND :month_end
  AND status = 'PT'
  LIMIT 1

結果: 既に PT なら戻り値 04（部分完了）、スキップ
```

### 8.2 大規模口座数への対応

```
バッチサイズ制御:
  - スナップショット化: 最大 10,000 口座
  - 記帳ループ: 1 回に 100 口座処理後、チェックポイント保存
  - メモリ管理: 定期的に GC ヒント

例：1,000,000 口座の月末処理
  - ループ 1: 口座 1～100 処理 → checkpoint
  - ループ 2: 口座 101～200 処理 → checkpoint
  - ...
  - ループ 10000: 口座 999901～1000000 処理 → checkpoint (final)
  - 再実行時: checkpoint から続行
```

---

## 9. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | 決済勘定の利息計上ルール | 決済勘定（0010010000002）に計上された利息の扱い（相殺・消去等）。会計上の処理。 | 会計基準 | 2026-08-30 |
| 2 | 利息計上後の税計算 | 利息に対する税控除（源泉徴収税等）の処理タイミング。14-interestpost の責務か。 | 税務設計 | 2026-09-15 |
| 3 | マイナス利息への対応 | 金利が負の場合（レートが負）、利息が負数になる場合の処理。手数料化するか。 | 商品企画 | 2026-08-30 |
| 4 | 月末以外の臨時計上 | 月の途中で利息を計上する必要性（イベント駆動的）。スコープ外か。 | ビジネス要件 | 2026-09-30 |
| 5 | パフォーマンス目標値 | 100万口座時の月末処理時間 SLA を設定。バッチサイズ・リトライ戦略の見直しポイント。 | パフォーマンス検証 | 2026-09-30 |
| 6 | 外部システム連携の遅延 | イベント発行（20-integrationout）の失敗が月末処理に与える影響。非同期化の要件確認。 | 連携設計 | 2026-09-15 |

---

*設計書バージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, subsystem-design-template.md*
