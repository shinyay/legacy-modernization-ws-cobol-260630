# サブシステム設計書：17-statement（明細書生成）

> **TO-BE 設計書** — COBOL/ISAM から Java/PostgreSQL への移行設計書

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `17-statement` — 明細書生成 |
| ディレクトリ | [subsystems/17-statement/](../../../subsystems/17-statement/) |
| 分類 | トランザクション処理系（読取スライス） |
| API契約（AS-IS） | [copy/api/stmt-api.cpy](../../../subsystems/17-statement/copy/api/stmt-api.cpy) |
| API契約（TO-BE） | `StatementGenerationService` インターフェース（Java） |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

指定された期間（日次/月次）について、有効な口座に対する全取引を集計し、期首残高・取引明細・期末残高を含む口座明細書を生成・出力する。財務会計における「保存則」（期首残高 + 全取引の符号付金額の和 = 期末残高）を常に検証する読取専用処理。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|
| 上流（呼び出し元） | バッチスケジューラ（systemd timer）/ 照会サブシステム | 日次/月次のスケジュール実行、またはオンライン照会要求 |
| 下流（呼び出し先） | 21-audit（監査ログ） | 明細書生成開始・完了・エラーを記録 |
| 参照データ | `accounts` テーブル | 口座マスタ（ステータス、開設日等） |
| 参照データ | `postings` テーブル | 振替記帳明細（DR/CR、金額、日付） |
| 参照データ | `transactions` テーブル | 取引ヘッダ（txn_id、業務日、区分） |
| 参照データ | `customers` テーブル | 顧客マスタ（キャッシュ用） |
| 参照データ | `branches` テーブル | 支店マスタ（キャッシュ用） |
| 出力ファイル | 明細書出力ファイル | CSV / PDF / SPOOL形式（パラメータで指定） |

### 1.3 構成プログラム

| 主要クラス/メソッド | パッケージ | 機能 | 主要ロジック |
|---|---|---|---|
| `StatementGenerationService` | `com.practice.statement.service` | 明細書生成の主処理・オーケストレーション | `generate(mode, period)` |
| `StatementBuilder` | `com.practice.statement.builder` | 口座別の明細書構築・保存則検証 | `buildStatement(accountId, openingBalance, postings)` |
| `StatementRepository` | `com.practice.statement.repository` | DB照会（accounts, postings, transactions） | 読取専用SQL（キャッシング） |
| `CustomerCache` / `BranchCache` | `com.practice.statement.cache` | 顧客名・支店名キャッシュ（LRU 500/100） | `get(id)`, `warm(ids)` |
| `StatementWriter` | `com.practice.statement.io` | 明細書ファイル出力（CSV/PDF） | `write(statement, format, filename)` |
| `StatementValidator` | `com.practice.statement.validator` | 保存則検証・統計情報計算 | `validate(openingBalance, postings, closingBalance)` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | バッチ（systemd timer） / オンライン（REST API） |
| 実行契機 | 日次：営業日終了時 / 月次：月末営業日終了時 |
| 多重度・冪等性 | 完全冪等。同一期間・口座の再実行は同一結果を生成。スキップ判定による重複生成防止。 |
| リカバリ | 失敗時：チェックポイント記録。再実行時：前回の完了口座数を確認し続行可能。 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
1. 入力パラメータ検証
   - mode: `D`（日次） / `M`（月次） / `P`（指定期間）
   - period: YYYYMMDD 形式（月次時は月末日）
   - output_filename: ファイル出力パス（相対パスは $DATA_HOME/statements へ）
   - skip_inactive: `Y`=非稼働口座をスキップ / `N`=全口座

2. キャッシュ準備
   - customers テーブル全件をメモリに読込（LRU 500エントリ、顧客名キャッシュ）
   - branches テーブル全件を読込（LRU 100エントリ、支店名キャッシュ）

3. 対象口座の抽出
   - SELECT accounts WHERE status IN ('A', 'D') [AND status != 'D' IF skip_inactive='Y']
   - ORDER BY account_id（無損失イテレーション保証）
   - 口座数が 1,000 件を超える場合、バッチサイズ 100 でスナップショット化

4. 口座ごとの処理
   FOR EACH account IN snapshot:
   a. 開始日残高を取得（balance テーブル from 前営業日）
   b. postings を JOIN transactions で期間内取引を抽出
      SELECT postings.*, transactions.posting_date, transactions.category
      FROM postings
      JOIN transactions ON postings.txn_id = transactions.txn_id
      WHERE postings.account_id = :account_id
      AND transactions.posting_date BETWEEN :period_start AND :period_end
      AND transactions.status = 'PT'（確定済のみ）
      ORDER BY postings.posting_date, postings.posting_id
   c. 取引ごとに明細行を生成
      - 日付、区分（category → 日本語名）、借方/貸方金額、摘要（相手先名キャッシュ参照）、残高
   d. 保存則検証
      - 期末残高 = 開始日残高 + Σ(DR金額) - Σ(CR金額)
      - 不一致 → ロギング・エラーカウント（続行）
   e. 出力ファイルに明細書ブロック追記

5. 統計情報・監査記録
   - 処理口座数、空白口座数、スキップ口座数、書込行数、書込ページ数、ファイルサイズ
   - 監査ログへ記録（action='STATEMENT_GENERATED'）

6. チェックポイント更新（再実行時復帰用）
   - 完了口座数、最後に完了した account_id を記録
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | ステータスフィルタ | 'A'（稼働）と 'D'（休眠）の口座のみ。'C'（解約）'S'（停止）は対象外。skip_inactive='Y' の場合は 'D' も除外。 |
| 2 | 保存則検証（必須） | 期末残高 = 期首残高 + Σ(借方) - Σ(貸方)。不一致時はログ出力し続行（エラーコード返さない）。会計整合性を確認。 |
| 3 | 取引フィルタ | status='PT'（確定）のみ。status='TD'（保留中）、'RV'（取消）は除外。 |
| 4 | キャッシュ戦略 | 顧客名・支店名は LRU キャッシュで保持。容量超過時は OldestAccessedItem を削除。DBアクセス削減。 |
| 5 | 相手先名参照 | postings に相手先 account_id があれば、キャッシュから相手先口座の顧客名を参照し「摘要」に記載。 |
| 6 | 空白口座判定 | 当期取引がない口座は「空白」カウント。出力ファイルには include/exclude でフラグ指定可能（出力パラメータ）。 |
| 7 | 区分コード変換 | category（10=入金、20=出金、30=振替、40=仕向送金、50=利息、60=手数料）→ 日本語表記 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | 全口座の明細書を生成・ファイル出力完了。保存則不一致があっても情報レベルログのみで `00` 返す。 |
| `04` | 部分完了 | スキップ対象外の口座あり、またはデータ整合性警告（保存則不一致多数）だが処理は完了。 |
| `08` | 入力不正 | 無効な mode / period 形式 / output_filename（ディレクトリ作成失敗等） |
| `10` | EOF（対象口座なし） | 指定条件に該当する口座がない（保存則検証対象なし）。 |
| `12` | I/O失敗 | ファイルオープン、DBMS接続、読取エラー。出力ディレクトリ権限不足。 |
| `16` | 致命的エラー | キャッシュ容量超過 / OUT OF MEMORY / 予期しない例外。スタックトレース出力。 |

### 2.4 排他・トランザクション制御

- **読取のみ**：排他制御不要。全 SELECT は `READ COMMITTED` 分離レベルで実行。
- **タイムスタンプ**：処理開始時の現在時刻を記録し、明細書ヘッダに「集計基準日時」として記載。
- **ロック**：不要。キャッシュは read-only copy のため同時性なし。
- **トランザクション**：各 SELECT を自動コミット（AC）で実行。明細書ファイル出力は DB と無関係（ローカルファイル）。
- **チェックポイント**：口座処理完了ごとに メタデータテーブル `statement_generation_checkpoints` に (`batch_id`, `account_id`, `completed_at`) を INSERT。再実行時に確認。

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| 顧客キャッシュ読取失敗 | ログ警告。該当顧客の摘要を「不明」で記載。続行。 | WARN: "Customer cache miss for customer_id={id}" |
| 保存則不一致 | 当該口座の差分（期末残高 - 計算値）を記録。監査対象。続行。 | WARN: "Balance mismatch account={id}, diff={diff_amount} JPY" |
| DB接続タイムアウト | 即座に `12` 返却。スタックトレース出力。 | ERROR: "Database connection timeout after {sec}s" |
| ファイル出力失敗 | 部分的に出力されたファイルは削除（rollback）。`12` 返却。 | ERROR: "Output file write failed: {filename}, cause={exception}" |
| OUT OF MEMORY | JVM GC 失敗時。メモリダンプ生成試行。`16` 返却。 | ERROR: "Out of memory. Java heap size={heap}, GC={gc_status}" |
| チェックポイント書込失敗 | 処理自体は続行（チェックポイントなしで再実行可能）。警告ログ。 | WARN: "Checkpoint write failed, recovery may restart from beginning" |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: `com.practice.statement.api.StatementGenerationRequest`

| パラメータ名 | 型 | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `mode` | String | ✓ | 集計モード | `D`=日次 / `M`=月次 / `P`=指定期間。デフォルト `D`。 |
| `businessDate` | LocalDate (YYYYMMDD) | ✓ | 業務日（日次時）または月末営業日（月次時） | 営業日のみ有効。カレンダーマスタで検証。 |
| `periodStart` | LocalDate | ○ | 集計開始日（mode=`P` 時のみ必須） | `periodStart <= businessDate` |
| `periodEnd` | LocalDate | ○ | 集計終了日（mode=`P` 時のみ必須） | `periodEnd >= periodStart && <= businessDate` |
| `outputFilename` | String | ✓ | 出力ファイルパス（相対 / 絶対） | 相対時は `$DATA_HOME/statements/` を基点。拡張子で形式判定（.csv/.pdf/.txt）。 |
| `outputFormat` | String | — | 出力形式 | `CSV` / `PDF` / `TEXT`。filename拡張子がなければこれを使用。デフォルト `CSV`。 |
| `skipInactive` | String | — | 非稼働口座をスキップするか | `Y`=スキップ / `N`=含める。デフォルト `Y`。 |
| `batchId` | String | — | バッチID（監査・チェックポイント用） | UUID または `YYYYMMDDHHMMSS` 形式。デフォルト自動生成。 |
| `operatorId` | String | — | オペレータID（オンライン実行時） | {X(32)}。バッチ実行時は `BATCH_JOB` 固定。 |

### 3.2 入力データソース

| 種別 | テーブル | 形式 | キー | 備考 |
|---|---|---|---|---|
| マスタ | `accounts` | PostgreSQL | `account_id` (pk) | ステータス A/D/C/S でフィルタ |
| マスタ | `customers` | PostgreSQL | `customer_id` (pk) | キャッシュ対象（500件） |
| マスタ | `branches` | PostgreSQL | `branch_id` (pk) | キャッシュ対象（100件） |
| トランザクション | `transactions` | PostgreSQL | `txn_id` (pk) | status='PT' に限定 |
| 振替記帳 | `postings` | PostgreSQL | `posting_id` (pk), `account_id` (fk) | txns JOIN で期間フィルタ |
| 残高 | `balances` | PostgreSQL | `account_id` (pk) | period_start 前営業日の closing_balance を参照 |
| カレンダー | `business_calendar` | PostgreSQL | `calendar_date` (pk) | 営業日/非営業日判定 |

### 3.3 前提・事前条件

- データベース（PostgreSQL）が稼働し、全テーブルに読取権限があること
- 指定された `businessDate` は営業日であること（カレンダーマスタで検証）
- キャッシュサイズ（顧客500件・支店100件）がメモリ内に収まること
- `$DATA_HOME` 環境変数が設定されており、出力ディレクトリが存在または作成可能であること

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時）

API契約: `com.practice.statement.api.StatementGenerationResponse`

| パラメータ名 | 型 | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `status` | String | 戻り値コード | 全ケースで設定（`00`/`04`/`08`/`10`/`12`/`16`） |
| `batchId` | String | バッチID（監査トレーサビリティ） | 入力された batchId または自動生成値 |
| `businessDate` | LocalDate | 集計基準日 | リクエストの businessDate をエコーバック |
| `accountsProcessed` | Integer | 処理済口座数 | {count} |
| `accountsEmpty` | Integer | 取引なし口座数 | {count} |
| `accountsSkipped` | Integer | スキップ口座数 | {count}（skip_inactive=Y で 'D' 状態） |
| `linesWritten` | Long | 出力行数 | ファイルの明細行数（ヘッダ・フッタ含まず） |
| `pagesWritten` | Integer | 出力ページ数 | PDF形式時のみ有意。CSV/TEXT は 1。 |
| `bytesWritten` | Long | ファイルサイズ | バイト単位 |
| `outputFilename` | String | 生成されたファイルのフルパス | 絶対パス |
| `balanceMismatches` | Integer | 保存則不一致件数 | 警告レベル（コード `00` でも返す） |
| `durationMs` | Long | 処理時間 | ミリ秒単位 |
| `checkpointId` | String | チェックポイントID | 再実行用の復帰ポイント（UUID） |

### 4.2 出力データ更新（更新系の場合）

本サブシステムは **読取専用** のため、データベースへの更新なし。

| 種別 | 対象 | 操作 | 目的 | 備考 |
|---|---|---|---|---|
| メタデータ | `statement_generation_checkpoints` | INSERT | チェックポイント記録 | 再実行時の復帰ポイント（`batch_id`, `completed_account_id` など） |
| 監査ログ | 21-audit | INSERT（監査API経由） | 明細書生成イベント記録 | action='STATEMENT_GENERATED', result_code |
| — | — | — | — | ファイル出力は DB外（ローカルファイルシステム）|

### 4.3 後続・事後条件

- 生成された明細書ファイルは `$DATA_HOME/statements/` に格納され、顧客・オペレータによるダウンロード/印刷が可能
- チェックポイント記録により、処理中断時の部分的な再実行が可能
- 監査ログにより、いつ・だれが・どの期間の明細書を生成したかが追跡可能
- ファイル内容（期首残高・取引明細・期末残高）は会計監査の証跡として保存される

---

## 5. レコード定義

### 5.1 入力レコード（AccountSnapshot）

| フィールド名 | PIC / 型 | キー区分 | 説明 |
|---|---|---|---|
| `account_id` | String(13) | 主キー | 支店番号(4) + 口座種別(2) + 番号(7) |
| `customer_id` | String(10) | — | 顧客ID（キャッシュ参照用） |
| `status` | Char(1) | — | A=稼働 / D=休眠 / C=解約 / S=停止 |
| `product_id` | String(5) | — | 商品コード（利息・手数料の適用判定用） |
| `opened_date` | LocalDate | — | 口座開設日 |

### 5.2 出力レコード（StatementDetail）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `posting_date` | LocalDate | 記帳日（YYYY-MM-DD） |
| `category` | String(2) | 区分コード（10=入金 etc） |
| `category_name` | String(20) | 区分日本語名（「入金」「振替」等） |
| `counterparty_account` | String(13) | 相手先口座ID |
| `counterparty_name` | String(60) | 相手先顧客名（キャッシュから） |
| `debit_amount` | BigDecimal | 借方金額 JPY（負数の場合は 0） |
| `credit_amount` | BigDecimal | 貸方金額 JPY（負数の場合は 0） |
| `running_balance` | BigDecimal | 残高（期首 + Σ(DR-CR)） |
| `txn_id` | String(16) | 取引ID（トレーサビリティ） |
| `memo` | String(60) | 備考・摘要 |

### 5.3 チェックポイント（StatementGenerationCheckpoint）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `checkpoint_id` | String(36) | UUID |
| `batch_id` | String(32) | バッチID |
| `statement_period` | String(8) | YYYYMMDD |
| `completed_account_id` | String(13) | 最後に完了した口座ID |
| `completed_count` | Integer | 完了した口座数 |
| `created_at` | LocalDateTime | 作成日時 |

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/ISAM） | TO-BE（Java/PostgreSQL） | 対応方針 |
|---|---|---|---|---|
| 1 | プログラム言語 | COBOL（Embedded SQL） | Java（Spring Boot / JDBC） | クラス分割・DI活用で保守性向上 |
| 2 | ファイル I/O | ISAM / 順次ファイル | PostgreSQL テーブル | SQL JOIN で効率化、インデックス活用 |
| 3 | キャッシュ | 固定領域（顧客500・支店100） | Java HashMap（LRU策略）または Spring Cache | 動的サイジング対応。容量制御は @Cacheable で自動化可能。 |
| 4 | 出力形式 | コボル REPORT WRITER（固定行長） | CSV / PDF / JSON（ライブラリ活用） | Apache POI / iText / Jackson で複数形式サポート |
| 5 | 保存則検証 | 単純ロジック（足し算） | 同じロジック、ただし BigDecimal 使用で精度確保 | 浮動小数点誤差を排除 |
| 6 | エラーハンドリング | COBOL EVALUATE ネスト | Java Exception 体系（StatementException 等） | 構造化例外処理、スタックトレース自動ログ出力 |
| 7 | スケーラビリティ | 固定メモリ（9999 件スナップショット）| 動的メモリ or ページング | バッチサイズ制御で大規模口座数対応 |
| 8 | リカバリ | チェックポイント（ファイル） | DB メタデータテーブル | 永続化・問合せ容易 |
| 9 | 監査ログ | 21-audit 呼び出し（COBOL API） | AuditLogEvent ドメインイベント（Spring Event） | 非同期 or 同期で柔軟対応 |
| 10 | カレンダー検証 | インメモリキャッシュ | キャッシュ + DB参照（必要に応じて） | 営業日判定の妥当性確保 |

---

## 7. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | 月末営業日の判定ロジック | calendar マスタの "is_business_day" フラグと "is_month_end" フラグの組み合わせで実装。ただし金融機関カレンダーの詳細（例：振替休日扱い）は 03-calendar と連携。 | 設計WG | 2026-08-30 |
| 2 | CSV/PDF 出力仕様の詳細 | 顧客向け PDF（美装版・ロゴ含）と監査用 CSV（全フィールド）の 2パターンを設計。テンプレート（Thymeleaf など）で統一。 | UI/UX設計 | 2026-08-30 |
| 3 | パフォーマンス目標値 | 口座数 100万件時の処理時間 SLA を設定。バッチサイズ・キャッシュ戦略の見直しポイント明確化。 | パフォーマンス検証 | 2026-09-30 |
| 4 | キャッシュ容量超過時の挙動 | LRU削除時の顧客名参照の仕様（再読込 or 「不明」） | キャッシュ戦略設計 | 2026-08-30 |
| 5 | 並行実行制御（複数バッチの同時実行） | batchId 単位での分離。同一口座・同一期間の重複実行防止（DB constraint） | 並行処理設計 | 2026-09-15 |
| 6 | REST API 仕様 | エンドポイント、認証・認可、レート制限 | API 設計 | 2026-08-30 |

---

*設計書バージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, subsystem-design-template.md*
