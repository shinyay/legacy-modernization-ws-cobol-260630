# サブシステム設計書：13-interestaccrual（日次利息計算）

> **TO-BE 設計書** — COBOL/PostgreSQL から Java/Spring Boot/PostgreSQL への移行設計書

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `13-interestaccrual` — 日次利息計算 |
| ディレクトリ | [subsystems/13-interestaccrual/](../../../subsystems/13-interestaccrual/) |
| 分類 | トランザクション処理系（利息計算） |
| API契約（AS-IS） | [copy/api/iacr-api.cpy](../../../subsystems/13-interestaccrual/copy/api/iacr-api.cpy) |
| API契約（TO-BE） | `InterestAccrualService` インターフェース（Java） |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

指定された営業日に、全有効口座（ステータス A/D）に対し、日次利息を日数按分で計算し、`interest_accruals` テーブルに `status='AC'`（計算済）で挿入する。翌月末の利息計上（14-interestpost）の入力となる累積利息データを生成。保存則（合計利息=0）を常に検証。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|
| 上流（呼び出し元） | バッチスケジューラ（systemd timer） | 営業日終了後に日次実行 |
| 下流（呼び出し先） | 06-interestrate（金利参照API） | 口座の商品・利息対象フラグから金利を取得 |
| 下流（呼び出し先） | 14-interestpost | 当月の累積利息（AC）を集計して計上 |
| 下流（呼び出し先） | 21-audit（監査ログ） | 日次利息計算開始・完了・エラーを記録 |
| 参照データ | `accounts` テーブル | 口座マスタ（ステータス、開設日、商品ID） |
| 参照データ | `balances` テーブル | 口座残高（前営業日 closing_balance を参照） |
| 参照データ | `interest_rates` テーブル | 金利マスタ（商品別・期間別） |
| 参照データ | `interest_accruals` テーブル | 累積利息テーブル（INSERT 先） |
| 参照データ | `business_calendar` テーブル | 営業日判定・経過日数計算 |

### 1.3 構成プログラム

| 主要クラス/メソッド | パッケージ | 機能 | 主要ロジック |
|---|---|---|---|
| `InterestAccrualService` | `com.practice.interestaccrual.service` | 日次利息計算の主オーケストレーション | `runDaily(businessDate)` |
| `InterestCalculator` | `com.practice.interestaccrual.calculator` | 利息計算ロジック（日数按分、丸め） | `calculate(balance, rate, days)` |
| `AccountEligibilityChecker` | `com.practice.interestaccrual.validator` | 利息対象口座の適格性判定 | `isEligible(account, balance)` |
| `InterestRateResolver` | `com.practice.interestaccrual.rate` | 金利マスタ参照（API/キャッシュ経由） | `resolveRate(productId, businessDate)` |
| `InterestAccrualRepository` | `com.practice.interestaccrual.repository` | DB操作（INSERT、既計算判定） | `insert(accrual)`, `findExisting(accountId, date)` |
| `AccrualValidator` | `com.practice.interestaccrual.validator` | 保存則検証・統計情報計算 | `validateConservationLaw(accruals)` |
| `DailyCheckpoint` | `com.practice.interestaccrual.checkpoint` | チェックポイント記録・復帰 | `saveCheckpoint(businessDate, processedCount)` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | バッチ（systemd timer） |
| 実行契機 | 営業日終了時（夜間バッチ）。定期スケジュール。 |
| 多重度・冪等性 | 完全冪等。同一営業日の再実行は同一結果を生成。既計算判定で重複 INSERT 防止。 |
| リカバリ | 中断時：チェックポイント記録により続行可能。再実行時：前回の完了口座数から再開。 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
1. 入力パラメータ検証
   - businessDate: YYYYMMDD 形式、営業日であること
   - batchId: バッチ追跡用
   - checkpointFile: チェックポイント保存先

2. 初期化・キャッシュ準備
   - 金利マスタを事前読込（LRU キャッシュ、商品ID で索引）
   - 営業日カレンダー参照（経過日数計算用）
   - チェックポイント確認（中断からの復帰判定）

3. 対象口座の抽出
   - SELECT accounts WHERE status IN ('A', 'D')
   - ORDER BY account_id（無損失イテレーション保証）
   - スナップショット化（最大 10,000 件、バッチサイズ 1,000）

4. 利息計算ループ
   FOR EACH account IN snapshot:
   a. 前営業日の残高取得
      SELECT closing_balance FROM balances
      WHERE account_id = :id AND balance_date = :prev_business_date
   b. 適格性チェック（CHECK-ELIGIBILITY）
      - ステータス = 'A' or 'D'？
      - 残高 > 0？
      - 商品は利息対象？
      - 当日の利息既計算状態は？ → status='AC' 既存？
   c. 金利参照（RESOLVE-RATE）
      - 商品 ID と businessDate から金利取得
      - キャッシュヒット: データ返す
      - キャッシュミス: DB 参照 → キャッシュに追加
      - 参照失敗: スキップ、エラーカウント
   d. 利息計算（CALCULATE-ACCRUAL）
      ```
      days = businessDate - account.opened_date（営業日ベース）
      accrued_jpy = balance × rate × days / 36500
      ```
      - BigDecimal で精度確保（端数処理：HALF_UP）
   e. 既計算チェック
      - 同一 account_id + businessDate で interest_accruals.status='AC' 存在？
      - 存在 → スキップ、`WS-CTR-ALREADY` +1
      - 不存在 → INSERT
   f. INSERT INTO interest_accruals
      - accrual_id (UUID)
      - account_id
      - accrued_amount_jpy (計算値)
      - status = 'AC'
      - accrual_date = businessDate
      - created_at = now()

5. 統計情報の計算
   - ACCOUNTS-SCANNED: 走査口座数
   - ACCRUALS-INSERTED: 新規計算件数
   - INELIGIBLE-STATE: ステータス不適格
   - INELIGIBLE-PRODUCT: 利息対象外商品
   - INELIGIBLE-BALANCE: 残高 ≤ 0
   - INELIGIBLE-RATE: 金利参照失敗
   - ALREADY-ACCRUED: 既計算済み
   - TOTAL-ACCRUED-JPY: 合計利息（保存則検証用）

6. 保存則検証
   - Σ(accrued_jpy for 全利息対象口座) = ？
   - 統計ログ出力（INFO レベル）
   - 不一致警告（ただし処理続行、戻り値 00 のまま）

7. チェックポイント更新
   - business_date
   - processed_account_count
   - inserted_accrual_count
   - checkpoint_created_at

8. 監査ログ記録
   - action = 'INTEREST_ACCRUAL_RUN_DAILY'
   - result_code = status
   - accounts_scanned, accruals_inserted など
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | 適格性フィルタ | 状態 'A'（稼働）or 'D'（休眠）のみ対象。'C'（解約）'S'（停止）は除外。 |
| 2 | 残高条件 | `closing_balance > 0` の口座のみ対象。0 以下は無利息。 |
| 3 | 商品条件 | 商品マスタの `is_interest_bearing` フラグ = true の商品のみ対象。 |
| 4 | 金利参照 | 商品 ID と businessDate から当日の適用金利を取得。複数金利タイア存在時は最優先の tier を使用。 |
| 5 | 日数計算 | 開設日から計算基準日までの営業日数を使用（土日・祝日除外）。 |
| 6 | 計算式 | `accrued = balance × rate × days / 36500`（日本の銀行慣行: 360日ベース） |
| 7 | 端数処理 | BigDecimal HALF_UP で小数点第2位（銭）に丸め。 |
| 8 | 既計算判定 | SELECT 1 FROM interest_accruals WHERE account_id = :id AND accrual_date = :date AND status = 'AC'。存在 → スキップ（冪等性）。 |
| 9 | 保存則 | 全利息対象口座の accrued_jpy 合計は 0 に収束（資金保存）。不一致警告は INFO/WARN で出力。 |
| 10 | リトライ不可 | 計算エラー・金利参照失敗は即座に次口座へ。リトライなし（統計にカウント）。 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | 全口座の利息計算完了。保存則警告があっても `00` 返す。 |
| `04` | 部分完了 | 一部の口座で金利参照失敗があったが、処理は続行。適格外カウンタに計上。 |
| `08` | 入力不正 | businessDate 形式エラー / 営業日でない / batchId 不正。リトライなし。 |
| `10` | EOF（対象口座なし） | 適格な口座がない（全口座が不適格）。統計情報：ACCOUNTS-SCANNED=0。 |
| `12` | I/O失敗 | DB接続失敗 / SELECT タイムアウト / INSERT 失敗。リトライ対象。 |
| `16` | 致命的エラー | 計算エラー（数値オーバーフロー等） / OUT OF MEMORY / 予期しない例外。スタックトレース出力。 |

### 2.4 排他・トランザクション制御

- **読取主体**：`balances`、`accounts` は読取のみ。`interest_rates` も参照のみ。
- **INSERT のみ**：`interest_accruals` へ新規 INSERT。既計算判定により重複を回避。
- **トランザクション隔離**：`READ COMMITTED` で十分。各口座の利息計算は独立。
- **並行性**：複数の日次バッチが同一営業日で並行実行される場合、唯一キー制約（account_id + accrual_date）で重複 INSERT 防止。
- **ロック**：不要。計算は読取のみで、書込ロックなし。ただし INSERT 時のシーケンシャルアクセスは DBMS レベルで直列化。

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| 口座ステータス不適格 | スキップ。WS-CTR-INELIG-STATE +1 | DEBUG: "Account {id} ineligible: status={status}" |
| 残高 ≤ 0 | スキップ。WS-CTR-INELIG-BAL +1 | DEBUG: "Account {id} balance not positive: {balance}" |
| 商品が利息対象外 | スキップ。WS-CTR-INELIG-PROD +1 | DEBUG: "Product {id} non-interest-bearing" |
| 金利参照失敗 | スキップ。WS-CTR-INELIG-RATE +1 | WARN: "Interest rate resolution failed for account {id}, product {pid}" |
| 既計算状態あり | スキップ。WS-CTR-ALREADY +1 | INFO: "Accrual already computed for account {id} on {date}" |
| INSERT 失敗（unique violation） | スキップ（既計算扱い）。統計カウント。 | WARN: "Accrual insert failed (unique constraint): account={id}, date={date}" |
| DB 接続タイムアウト | 即座に `12` 返却。スタックトレース出力。再実行推奨。 | ERROR: "Database connection timeout after {sec}s" |
| 保存則不一致 | ログ警告。統計情報に差分を記録。処理続行、`00` 返す。 | WARN: "Conservation law violation: expected_sum=0, actual_sum={amount} JPY" |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: `com.practice.interestaccrual.api.InterestAccrualRunRequest`

| パラメータ名 | 型 | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `businessDate` | LocalDate (YYYYMMDD) | ✓ | 利息計算対象の営業日 | 営業日であること。カレンダーマスタで検証。 |
| `batchId` | String | ✓ | バッチ追跡用ID | UUID または `YYYYMMDDHHMMSS` 形式。デフォルト自動生成。 |
| `checkpointFile` | String | — | チェックポイント保存ファイルパス | 相対パス時は `$DATA_HOME/checkpoints/` を基点。 |
| `rateRefreshMode` | String | — | 金利キャッシュ戦略 | `CACHE`（メモリキャッシュ）/ `ALWAYS_FRESH`（毎回 DB 参照）。デフォルト `CACHE`。 |
| `skipAlreadyAccrued` | String | — | 既計算口座をスキップするか | `Y`（スキップ）/ `N`（エラーで止める）。デフォルト `Y`。 |

### 3.2 入力データソース

| 種別 | テーブル | 形式 | キー | 備考 |
|---|---|---|---|---|
| マスタ | `accounts` | PostgreSQL | `account_id` (pk) | ステータス A/D/C/S でフィルタ |
| マスタ | `balances` | PostgreSQL | `account_id` (pk) + `balance_date` (sk) | 前営業日の closing_balance を参照 |
| マスタ | `interest_rates` | PostgreSQL | `product_id` (pk) + `rate_effective_date` (sk) | 商品別・有効期間別金利 |
| マスタ | `products` | PostgreSQL | `product_id` (pk) | `is_interest_bearing` フラグで判定 |
| マスタ | `business_calendar` | PostgreSQL | `calendar_date` (pk) | 営業日判定・経過日数計算 |
| 出力 | `interest_accruals` | PostgreSQL | `accrual_id` (pk) | INSERT 先テーブル |

### 3.3 前提・事前条件

- データベース（PostgreSQL）が稼働し、全テーブルに読取・書込権限があること
- 指定された `businessDate` は営業日であること（カレンダーマスタで検証）
- 金利マスタ（`interest_rates`）が当日分までロード済みであること
- `$DATA_HOME` 環境変数が設定されており、チェックポイントディレクトリが存在または作成可能であること
- 前営業日の `balances` スナップショットが存在すること

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時）

API契約: `com.practice.interestaccrual.api.InterestAccrualRunResponse`

| パラメータ名 | 型 | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `status` | String | 戻り値コード | `00`/`04`/`08`/`10`/`12`/`16` |
| `businessDate` | LocalDate | 計算対象営業日 | リクエストの businessDate をエコーバック |
| `batchId` | String | バッチID | 入力された batchId または自動生成値 |
| `accountsScanned` | Integer | 走査した口座数 | {count} |
| `accrualsInserted` | Integer | 新規計算・挿入した利息件数 | {count} |
| `ineligibleState` | Integer | 状態不適格な口座 | status != 'A','D' |
| `ineligibleProduct` | Integer | 利息対象外商品の口座 | product.is_interest_bearing = false |
| `ineligibleBalance` | Integer | 残高 ≤ 0 の口座 | {count} |
| `ineligibleRate` | Integer | 金利参照失敗した口座 | {count} |
| `alreadyAccrued` | Integer | 既計算済の口座 | status='AC' で同日計算済 |
| `totalAccruedJpy` | BigDecimal | 当日の累積利息合計（JPY） | 保存則検証用 |
| `durationMs` | Long | 処理時間 | ミリ秒単位 |
| `checkpointId` | String | チェックポイントID | 再実行用の復帰ポイント（UUID） |

### 4.2 出力データ更新

| 種別 | テーブル | 操作 | 対象列 | 備考 |
|---|---|---|---|---|
| 利息累積 | `interest_accruals` | INSERT | `accrual_id`, `account_id`, `accrued_amount_jpy`, `status='AC'`, `accrual_date` | 新規利息レコード作成 |
| チェックポイント | `interest_accrual_checkpoints` | INSERT | `business_date`, `processed_account_count`, `checkpoint_created_at` | 再実行時の復帰ポイント |
| 監査ログ | 21-audit | INSERT（非同期） | action='INTEREST_ACCRUAL_RUN_DAILY', result_code | 実行情報の記録 |

### 4.3 後続・事後条件

- 計算された `interest_accruals` レコード（status='AC'）は翌月末の 14-interestpost で集計・計上の対象となる
- チェックポイント記録により、処理中断時の部分的な再実行が可能
- 監査ログにより、いつ・どの営業日の利息を計算したか、計算結果が追跡可能
- 統計情報は管理画面・レポートで日次監視可能

---

## 5. レコード定義

### 5.1 入力レコード（AccountSnapshot）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `account_id` | String(13) | 支店(4) + 種別(2) + 番号(7) |
| `customer_id` | String(10) | 顧客ID |
| `status` | Char(1) | A=稼働 / D=休眠 / C=解約 / S=停止 |
| `product_id` | String(5) | 商品コード |
| `opened_date` | LocalDate | 開設日 |

### 5.2 入力レコード（BalanceSnapshot）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `account_id` | String(13) | 口座ID |
| `balance_date` | LocalDate | 残高基準日（前営業日） |
| `closing_balance` | BigDecimal | 期末残高 JPY |

### 5.3 入力レコード（InterestRateRecord）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `product_id` | String(5) | 商品ID |
| `rate_effective_date` | LocalDate | 適用開始日 |
| `annual_rate_percent` | BigDecimal | 年利率（%）。例: 0.50 |

### 5.4 出力レコード（InterestAccrual）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `accrual_id` | String(36) | UUID |
| `account_id` | String(13) | 口座ID |
| `accrual_date` | LocalDate | 計算基準日 |
| `accrued_amount_jpy` | BigDecimal | 日次利息（JPY、小数点第2位） |
| `status` | Char(2) | AC=計算済 / PT=計上済 / CN=取消 |
| `created_at` | LocalDateTime | 作成日時 |

### 5.5 チェックポイント（InterestAccrualCheckpoint）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `checkpoint_id` | String(36) | UUID |
| `business_date` | LocalDate | 計算対象営業日 |
| `processed_account_count` | Integer | 処理済口座数 |
| `inserted_accrual_count` | Integer | 挿入した利息件数 |
| `checkpoint_created_at` | LocalDateTime | チェックポイント作成日時 |

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/Embedded SQL） | TO-BE（Java/Spring Boot） | 対応方針 |
|---|---|---|---|---|
| 1 | プログラム言語 | COBOL（SQB） | Java（JPA/JDBC） | Spring Data JPA で DB操作を簡潔化 |
| 2 | ファイル I/O | チェックポイント（ファイル） | DB メタデータテーブル | 永続化・問合せ容易 |
| 3 | 金利参照 | 別途 irate-api CALL | InterestRateResolver（キャッシュ戦略） | LRU キャッシュで効率化 |
| 4 | 計算精度 | COBOL COMP-3（固定小数点） | Java BigDecimal | 浮動小数点誤差を完全排除 |
| 5 | 日数計算 | COBOL カレンダー機構 | ChronoUnit.DAYS + business_calendar テーブル | Java 8 Time API で標準化 |
| 6 | リトライ | COBOL EVALUATE / 手動制御 | Spring Retry / @Retryable | 宣言的・保守性向上 |
| 7 | 統計情報 | ファイル / メモリ変数 | Response オブジェクト / DB 永続化 | 構造化・監視容易 |
| 8 | 監査ログ | 同期 CALL | Spring Event (@EventListener) / 非同期 | 疎結合・パフォーマンス向上 |
| 9 | エラーハンドリング | COBOL EVALUATE ネスト | Java Exception 階層 | スタックトレース自動ログ |
| 10 | スケーラビリティ | メモリ固定（9999 件） | 動的メモリ / ページング | バッチサイズ制御で大規模対応 |

---

## 7. 金利マスタ参照の詳細

### 7.1 キャッシュ戦略

```
InterestRateResolver:
  - LRU キャッシュ（容量: 商品数 ≈ 50 件）
  - キー: product_id + business_date
  - ヒット時: メモリから即座に返す
  - ミス時: SELECT FROM interest_rates → キャッシュに追加 → 返す
  - 参照失敗: 例外をキャッチ、ログ、スキップ、カウンタ +1

計算式（BusinessDay ベース）:
  accrued = balance × (annual_rate / 100) × days / 360

例:
  balance = 1,000,000 JPY
  annual_rate = 0.50% (= 0.0050)
  days = 30 営業日
  accrued = 1,000,000 × 0.0050 × 30 / 360 = 416.67 JPY (HALF_UP → 416円)
```

---

## 8. 並行実行・マルチテナント対応

### 8.1 同一営業日の複数バッチ実行

複数の地域・部門が並行実行される場合：

```
DB制約：
  CREATE UNIQUE INDEX uq_accrual_account_date
    ON interest_accruals(account_id, accrual_date)
    WHERE status = 'AC'

動作：
  - Batch1 が account_id=001 に INSERT → OK
  - Batch2 が同じ account_id=001 に INSERT → Unique violation → 処理継続
  - skipAlreadyAccrued='Y' の場合: スキップカウント +1
  - skipAlreadyAccrued='N' の場合: 例外で戻り値 12
```

---

## 9. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | 金利レート更新のリアルタイム反映 | 日中に金利が変更された場合の扱い。当日の利息再計算要件の有無を確認。 | 商品企画 | 2026-08-30 |
| 2 | 複数金利ティアの場合の選択 | 複数の金利が適用される場合（期間別・階層別）、どの金利を使用するか（最優先 tier か加重平均か）。 | 利息計算設計 | 2026-08-30 |
| 3 | 休眠口座への利息計算 | 休眠状態（status='D'）の口座にも利息を計算するか、停止するか。要件確認。 | 商品企画 | 2026-08-30 |
| 4 | 開設日が同一営業日の口座 | 開設日当日に利息を計算するか（days=0）、それとも翌日から（days=1）か。 | 会計基準 | 2026-08-30 |
| 5 | パフォーマンス目標値 | 100万口座時の処理時間 SLA を設定。バッチサイズ・キャッシュ戦略の見直しポイント。 | パフォーマンス検証 | 2026-09-30 |
| 6 | 金利マスタロード時刻 | 金利が変更されるタイミング（営業日開始時か前日か）。キャッシュ更新戦略を決定。 | 運用設計 | 2026-09-15 |

---

*設計書バージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, subsystem-design-template.md*
