# サブシステム設計書 — 15-autodebit（日次自動振替）

> **記入ガイド**: Java/PostgreSQL への モダナイゼーション設計書
> テンプレート参照: [subsystem-design-template.md](../templates/subsystem-design-template.md)
> 仕様出典: [specs-asis/02-transaction-pipeline.md](../specs-asis/02-transaction-pipeline.md)

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `15-autodebit`（日次自動振替） |
| ディレクトリ | [subsystems/15-autodebit/](../../../subsystems/15-autodebit/) |
| 分類 | トランザクション処理系（取引パイプライン） |
| API契約 | [copy/api/ad-api.cpy](../../../subsystems/15-autodebit/copy/api/ad-api.cpy) |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

給与や定期家賃など、顧客が事前に指示した自動振替スケジュール（autodebit_schedules）から期日到来分を抽出し、複式簿記（category=20）で記帳実行する。失敗時は連続失敗カウントで自動停止・解約フラグを立て、結果をレポートする。リトライは毎月 15 日に systemd timer で起動。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|---|
| 上流（呼び出し元） | `22-operations / ops-batch-daily.sqb` | 日次バッチの一部として daily スケジュール実行 |
| 下流（呼び出し先） | `12-txnpost`（複式簿記記帳）/ `21-audit`（監査記録） | 振替取引を記帳、失敗履歴を監査ログ |
| 参照データ | `autodebit_schedules` / `accounts` / `account_balances` / `autodebit_history` | TO-BE: PostgreSQL |
| パイプライン上の位置 | 記帳後（12-txnpost）の後処理 | 12 完了後、日次に限定実行 |
| リトライ実行 | 毎月15日の systemd timer | FAILED または DEFERRED 状態のレコードを再処理 |

### 1.3 構成プログラム

| Program-ID | ファイル | 機能 | 主要PARAGRAPH |
|---|---|---|---|
| `AD-RUN-DAILY` | [src/ad-run-daily.sqb](../../../subsystems/15-autodebit/src/ad-run-daily.sqb) | 日次自動振替実行（メイン） | `M-START`, `LOAD-SCHEDULES-SNAPSHOT`, `POST-TRANSFERS`, `UPDATE-SCHEDULE-STATUS`, `UPDATE-FAILURE-COUNT` |
| `AD-REPORT-SUMMARY` | [src/ad-report-summary.sqb](../../../subsystems/15-autodebit/src/ad-report-summary.sqb) | 日次実績レポート | `M-START`, `GEN-REPORT` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | バッチ / systemd timer（日次 + 毎月15日） |
| 実行契機 | 日次（営業日）、記帳処理（12-txnpost）完了後 |
| リトライ契機 | 毎月15日、前月分の失敗/遅延を再処理 |
| 多重度・冪等性 | **冪等不可** — 同一ビジネス日付で重複実行すると二重振替が発生。チェックポイント記録で部分復旧可 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
【AD-RUN-DAILY】
1. 入力パラメータ検証
   - BATCH-ID（14文字）、BUSINESS-DATE（YYYYMMDD）の形式チェック
   
2. PostgreSQL 接続（--with-db）
   
3. 振替スケジュールのスナップショット取得
   - SELECT * FROM autodebit_schedules
     WHERE next_due_date ≤ BUSINESS-DATE
       AND status = 'AC'  （=active）
       AND end_date IS NULL OR end_date ≥ BUSINESS-DATE
   - メモリにロード（MAX 500件）
   - 条件：支払人/受取人口座が存在・有効、金額>0
   
4. 振替スケジュール毎に処理ループ
   a) 支払人（payer）/受取人（payee）の口座確認
      → 存在確認、ステータス確認（='A'）
      
   b) 支払人の残高確認
      - SELECT balance FROM account_balances
        WHERE account_number = payer_account
      - balance < amount ⟹ 失敗理由コード 'NF'（no fund）→ SKIPPED-NSF
      
   c) 連続失敗回数確認
      - SELECT failure_count FROM autodebit_schedules
      - NF が 3回連続 ⟹ AUTO-SUSPENDED フラグ立て、スキップ
      - CL（解約）が 2回連続 ⟹ AUTO-TERMINATED フラグ立て、スキップ
      - SU（停止）状態 ⟹ 失敗理由コード 'SU' → スキップ
      
   d) 既実行チェック
      - WHERE payer = payer_acct AND payee = payee_acct
             AND business_date = BUSINESS-DATE
       AND category = '20'
      → あれば SKIPPED-ALREADY でスキップ
      
   e) DOUBLE-ENTRY-HELPER に delegate
      - txn_id 生成（9000000001-indexed）
      - DR: 支払人（payer）DEBIT payer_account, amount
      - CR: 受取人（payee）CREDIT payee_account, amount
      - TXN-TYPE = "AUTODEBIT" (category=20)
      - 成功 → `00` / 失敗 → `04`, `12` コード
      
   f) 成功時：
      - balance 更新（支払人 -金額、受取人 +金額）
      - failure_count = 0 リセット
      - next_due_date を frequency 分進める
      - HISTORY テーブル INSERT
      - AUDIT ログ記録
      
   g) 失敗時：
      - failure_count インクリメント
      - 連続失敗が閾値超 ⟹ status を 'SU'（停止）or 'TE'（解約）に UPDATE
      - HISTORY テーブルに失敗理由記録
      - FAILED-FILE に追記
      
5. チェックポイント記録
   - 最後に処理したスケジュール ID を CP ファイルに SENTINEL="OK"
   
6. 集計・統計
   - 対象スケジュール数（INSTRUCTIONS-DUE）
   - 振替成功数（INSTRUCTIONS-POSTED）
   - 失敗カウンタ別（FAILED-NF, FAILED-CL, FAILED-SU）
   - 自動停止/終了件数（AUTO-SUSPENDED, AUTO-TERMINATED）
   - 既実行数（SKIPPED-ALREADY）、ヘルパー判定数（SKIPPED-HELPER）
   - 合計金額（TOTAL-DEBITED-JPY）
   - 処理時間（DURATION-SEC）

【AD-REPORT-SUMMARY】
1. サマリファイルを読み込み
2. 失敗ファイルを読み込み（FAILED-FILENAME）
3. 実績集計・生成
4. レポート出力

【リトライ処理（systemd timer: 毎月15日）】
- status='SU'（停止）のみ対象
- 前月の失敗を除外ロジックで判定
- 再処理の可能性を評価
- 条件に合致するものを reprocess
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | **期日到来判定** | next_due_date ≤ business_date のみ処理対象 |
| 2 | **ステータスフロー** | `AC`（活性） → 処理成功で `AC` 継続 / 失敗で `SU`（停止）or `TE`（解約） |
| 3 | **失敗回数による自動制御** | NF: 3回連続で `SU`。CL: 2回連続で `TE`。SU: 現状のまま。超過後は自動スキップ |
| 4 | **次回期日計算** | frequency = `D`（日次）/`W`（週次）/`M`（月次）に基づき next_due_date を更新 |
| 5 | **周期末処理** | end_date に達したら status を自動で `TE`（終了）に |
| 6 | **複式簿記原則** | DR + CR ペア（支払人=借方、受取人=貸方、category=20） |
| 7 | **二重実行防止** | チェックポイント + HISTORY テーブル（UNIQUE(payer, payee, business_date, schedule_id)）で検出 |
| 8 | **冪等性なし** | 同日に 2度実行すると二重振替が発生（ビジネス仕様） |
| 9 | **金額単位** | JPY のみ。COMP-3（zoned decimal）で精度保持 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | 全振替成功、または処理対象なし（スケジュール該当0件） |
| `04` | 部分失敗 | 一部スケジュールの振替が失敗（NF/CL/SU など失敗理由記録） |
| `08` | 入力不正 | BATCH-ID / BUSINESS-DATE 形式エラー |
| `12` | I/O 失敗 | DB接続失敗、SQL エラー（SELECT/UPDATE）、ファイルオープン失敗 |
| `16` | 致命的エラー | 未復旧チェックポイント破損、制御不可な DB 状態 |

### 2.4 排他・トランザクション制御

- **DB トランザクション**: 各振替記帳は 12-txnpost（複式簿記エンジン）内の ACID トランザクション下で実行
  - リトライ可能な競合（SQLSTATE 40001/40P01）は指数バックオフで再試行
  - ロックタイムアウト（DEFER）は recon-defer ファイルに記録し後処理対応

- **行ロック**: autodebit_schedules テーブルの行は SELECT FOR UPDATE で確保、重複処理防止
  
- **チェックポイント**: CP ファイルに最後に処理したスケジュール ID を記録 → 再実行時の重複防止
  
- **監査記録**: 各振替を 21-audit に非同期投入（RabbitMQ or 同期 CALL）

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| DB接続失敗 | 戻り値12でリターン | shared-log-api 経由、レベル ERROR |
| SQL エラー（SELECT/UPDATE）| 戻り値12 / エラー理由コード | レベル ERROR、SQLCODE/SQLSTATE 記録 |
| ファイルオープン失敗（CP） | 戻り値12 | レベル ERROR |
| 振替記帳失敗（NF/CL など） | 失敗理由記録、failure_count increment | レベル INFO（業務ロジック） |
| 自動停止/終了トリガ | status を 'SU'/'TE' に UPDATE | レベル WARN |
| チェックポイント破損 | 戻り値16、新規開始 | レベル WARN |
| リトライ FSM: CONFLICT | 指数バックオフで自動リトライ（max 5回） | レベル WARN, 最終失敗は ERROR |
| リトライ FSM: DEFER | recon-defer ファイル記録 | レベル WARN、後続ジョブ手動対応 |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: [copy/api/ad-api.cpy](../../../subsystems/15-autodebit/copy/api/ad-api.cpy)

#### AD-RUN-INPUT（日次振替実行）

| COBOLフィールド名 | PIC | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `AD-RUN-BATCH-ID` | `X(14)` | ✓ | バッチ実行ID（日時ベース） | 形式: `YYYYMMDDHHMISS`（14桁） |
| `AD-RUN-BUSINESS-DATE` | `9(8)` | ✓ | 振替対象営業日 | 形式: YYYYMMDD（8桁数字）、営業日カレンダー登録済み |
| `AD-RUN-FAILED-FILENAME` | `X(80)` | ✓ | 失敗レコード出力ファイル | 絶対PATH、既存時は追記 |
| `AD-RUN-CHECKPOINT-FILENAME` | `X(80)` | ✓ | チェックポイントファイル | 中断時復旧用、アトミック上書き |
| `AD-RUN-SUMMARY-FILENAME` | `X(80)` | ✓ | 実績サマリファイル | AD-REPORT-SUMMARY の入力ファイル |

#### AD-REPORT-INPUT（レポート生成）

| COBOLフィールド名 | PIC | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `AD-RPT-BUSINESS-DATE` | `9(8)` | ✓ | ビジネス日付 | YYYYMMDD |
| `AD-RPT-BATCH-ID` | `X(14)` | ✓ | バッチID | AD-RUN-DAILY と同一 |
| `AD-RPT-SUMMARY-FILENAME` | `X(80)` | ✓ | サマリ入力ファイル | AD-RUN-DAILY の出力 |
| `AD-RPT-REPORT-FILENAME` | `X(80)` | ✓ | レポート出力ファイル | 人間可読形式（TSV/CSV） |
| `AD-RPT-FAILED-FILENAME` | `X(80)` | ✓ | 失敗レコード入力ファイル | デバッグ用 |

### 3.2 入力データソース

| 種別 | 名称 | 形式 | キー | 備考 |
|---|---|---|---|---|
| テーブル | `autodebit_schedules` | PostgreSQL | `schedule_id` | 自動振替指示スケジュール |
| テーブル | `autodebit_history` | PostgreSQL | `history_id` (PK) / `schedule_id` (FK) | 実行履歴・失敗追跡 |
| テーブル | `accounts` | PostgreSQL | `account_number` | 支払人/受取人口座確認 |
| テーブル | `account_balances` | PostgreSQL | `account_number` | 残高チェック（リアルタイム） |
| ファイル | FAILED-FILE | 順次（追記専用） | — | 当日失敗レコード |
| ファイル | CHECKPOINT-FILE | 単行テキスト | — | `LAST-SCHEDULE-ID:<id> SENTINEL:OK` |

### 3.3 前提・事前条件

- `autodebit_schedules` テーブルが LOAD 済み（初期化/定義済み）
- 営業日カレンダー（calendar テーブル / cal-api）が操作日まで登録済み
- PostgreSQL への接続情報が環境変数設定済み
- 記帳処理（12-txnpost）が完了済み（=前提データの口座残高は最新）

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時）

#### AD-RUN-OUTPUT（日次振替実行結果）

| COBOLフィールド名 | PIC | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `AD-RUN-STATUS` | `X(2)` | 戻り値コード | 全ケースで設定（`00`/`04`/`08`/`12`/`16`） |
| `AD-OUT-INSTRUCTIONS-DUE` | `9(7)` | 振替対象件数（next_due_date≤BD） | SELECT COUNT(*) 条件検索 |
| `AD-OUT-INSTRUCTIONS-POSTED` | `9(7)` | 振替成功件数 | トランザクション確定した件数 |
| `AD-OUT-FAILED-NF` | `9(7)` | 失敗理由 NF（no fund/口座なし）カウント | 残高不足 or 口座欠落 |
| `AD-OUT-FAILED-CL` | `9(7)` | 失敗理由 CL（closed/解約）カウント | 口座ステータス非有効 |
| `AD-OUT-FAILED-SU` | `9(7)` | 失敗理由 SU（suspended/停止）カウント | status='SU' |
| `AD-OUT-SKIPPED-ALREADY` | `9(7)` | スキップ：既に実行済み | チェックポイント検証で同一スケジュール判定 |
| `AD-OUT-SKIPPED-HELPER` | `9(7)` | スキップ：ヘルパーロジック判定 | 連続失敗フラグ など判定後 |
| `AD-OUT-AUTO-SUSPENDED` | `9(7)` | 自動停止に遷移したスケジュール件数 | `status='AC'` → `'SU'` UPDATE |
| `AD-OUT-AUTO-TERMINATED` | `9(7)` | 自動終了に遷移したスケジュール件数 | `status='AC'` → `'TE'` UPDATE |
| `AD-OUT-TOTAL-DEBITED-JPY` | `S9(15) COMP-3` | 振替成功した合計金額（JPY） | 符号付き 18桁、円単位 |
| `AD-OUT-DURATION-SEC` | `9(5)` | 処理実行時間（秒） | 開始～終了の実時間 |

#### AD-REPORT-OUTPUT（レポート生成結果）

| COBOLフィールド名 | PIC | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `AD-RPT-STATUS` | `X(2)` | 戻り値コード | `00`/`04`/`08`/`12`/`16` |
| `AD-RPT-TOTAL-INSTRUCTIONS` | `9(7)` | レポート対象の指示総数 | サマリから復元 |
| `AD-RPT-TOTAL-OK-JPY` | `S9(15) COMP-3` | 成功金額合計 | POSTED の全金額合計 |
| `AD-RPT-TOTAL-FAILED-COUNT` | `9(7)` | 失敗件数合計 | NF+CL+SU+その他 |
| `AD-RPT-SUSPENDED-COUNT` | `9(7)` | 停止状態のスケジュール件数 | status='SU' のみ |
| `AD-RPT-PG-PT-COUNT` | `9(7)` | PG/PT（ページング/部分）状態件数 | 予約フィールド |
| `AD-RPT-FILE-FAILED-COUNT` | `9(7)` | ファイル I/O エラー件数 | レポート生成時の異常 |
| `AD-RPT-CONSERVATION-PASS` | `X(1)` | 監査チェック結果 | `Y`=合格、`N`=警告 |
| `AD-RPT-DURATION-SEC` | `9(5)` | レポート生成時間（秒） | — |

### 4.2 出力データ更新（更新系の場合）

| 種別 | 名称 | 操作 | 対象項目 | 備考 |
|---|---|---|---|---|
| テーブル | `autodebit_history` | INSERT | `schedule_id`, `execution_date`, `result_code`, `amount`, `failure_reason` | 実行記録（成功/失敗） |
| テーブル | `autodebit_schedules` | UPDATE | `status` (`'AC'`→`'SU'`/`'TE'`), `next_due_date`, `failure_count`, `last_execution_date` | 自動停止/終了、次回期日、失敗回数 |
| テーブル | `postings` | INSERT | `posting_id`, `txn_id`, `account_number`, `debit_jpy`/`credit_jpy`, `category=20` | 複式簿記の明細（DR/CR ペア） |
| テーブル | `account_balances` | UPDATE | 支払人 -金額、受取人 +金額 | 各記帳後に更新 |
| ファイル | FAILED-FILE | WRITE（追記） | 100バイト フォーマット | 1レコード1失敗（schedule-id, reason-code, amount） |
| ファイル | CHECKPOINT-FILE | REWRITE（上書き） | LAST-SCHEDULE-ID, SENTINEL | 中断復旧用 |
| 監査ログ | 21-audit | INSERT | action=`AUTODEBIT-EXECUTE`, schedule_id, result | 監査記録（成功時のみ） |

### 4.3 後続・事後条件

- **ステータス遷移**: `status='AC'` → 成功は `'AC'` 継続 / 失敗で `'SU'`（停止）or `'TE'`（終了）に UPDATE
- **次回期日**: frequency に基づき next_due_date を更新（D: +1日、W: +7日、M: +30日など）
- **失敗追跡**: HISTORY テーブルに1行追加 → failure_count インクリメント
- **残高反映**: `account_balances` に即座に反映（支払人-金額、受取人+金額）
- **監査記録**: 成功振替は 21-audit へ記録（イベント キー=schedule_id）
- **チェックポイント**: 最後に成功したシーケンスを記録 → 再実行時の重複防止

---

## 5. レコード定義

レコードレイアウト: `autodebit_schedules` / `autodebit_history` / スナップショット: `WS-SNAPSHOT` / `WS-CUR`

### autodebit_schedules テーブル（PostgreSQL）

| フィールド名 | 型 | キー区分 | 説明 |
|---|---|---|---|
| `schedule_id` | BIGINT | 主キー | 振替スケジュール ID |
| `payer_account_number` | VARCHAR(13) | 副キー | 支払人口座番号 |
| `payee_account_number` | VARCHAR(13) | — | 受取人口座番号 |
| `amount_jpy` | NUMERIC(15,0) | — | 振替金額（JPY） |
| `frequency` | CHAR(1) | — | 周期（D/W/M） |
| `start_date` | DATE | — | 開始日 |
| `end_date` | DATE | — | 終了日（NULL=無期限） |
| `next_due_date` | DATE | — | 次回実行日 |
| `status` | CHAR(2) | — | ステータス（AC/SU/TE） |
| `failure_count` | SMALLINT | — | 連続失敗回数 |
| `last_execution_date` | DATE | — | 最後実行日 |
| `created_at` | TIMESTAMP | — | 作成日時 |
| `updated_at` | TIMESTAMP | — | 更新日時 |

### autodebit_history テーブル（PostgreSQL）

| フィールド名 | 型 | キー区分 | 説明 |
|---|---|---|---|
| `history_id` | BIGINT | 主キー | 履歴ID（自動採番） |
| `schedule_id` | BIGINT | 副キー (FK) | スケジュール ID |
| `execution_date` | DATE | — | 実行日 |
| `batch_id` | VARCHAR(14) | — | バッチID |
| `result_code` | CHAR(2) | — | 結果コード（00/04/08等） |
| `amount_jpy` | NUMERIC(15,0) | — | 実行金額 |
| `failure_reason` | CHAR(2) | — | 失敗理由（NF/CL/SU など） |
| `created_at` | TIMESTAMP | — | 記録日時 |

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/ISAM） | TO-BE（Java/PostgreSQL） | 対応方針 |
|---|---|---|---|---|
| 1 | スケジュールマスタ | ISAM 索引ファイル（*.idx） | `autodebit_schedules` テーブル | DB テーブルマッピング |
| 2 | 実行履歴 | FAILED-FILE（テキスト順次ファイル） | `autodebit_history` テーブル | 履歴管理を DB に統一 |
| 3 | チェックポイント | 単行テキストファイル | DB トランザクション + version control | トランザクション分離度を活用 |
| 4 | 複式簿記記帳 | AD-RUN-DAILY 内に直接埋め込み | 12-txnpost への delegate / API CALL | サービス化、再利用性向上 |
| 5 | 周期計算 | cal-api（COBOL） | 同じロジック移植 or Quartz Scheduler | スケジューラで管理可能 |
| 6 | 監査記録 | 別個のログファイル | `audit_logs` テーブル + イベントキュー | 監査ログ一元化 |
| 7 | 失敗回数管理 | プログラム内ロジック | DB テーブル（failure_count 列） | DB で永続化 |
| 8 | リトライ実行 | systemd timer（毎月15日） | Spring Scheduler or Quartz | タスク スケジューリング統一 |
| 9 | マルチテナント対応 | 非対応 | tenant_id 列追加の検討 | 将来拡張性 |

---

## 7. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | 失敗回数の正確な閾値 | NF: 3回、CL: 2回、SU: 即スキップの仕様を確定 | — | — |
| 2 | リトライ実行の詳細 | systemd timer 毎月15日の実装、条件判定、スコープを確認 | — | — |
| 3 | 周期計算ロジック | frequency='M' で月末/月初の取り扱い、年末処理を確認 | — | — |
| 4 | 複式簿記 API の詳細 | txnpost への delegate 仕様、リターンコード、エラー処理を確認 | — | — |
| 5 | 記帳されない失敗の扱い | NF/CL/SU で記帳できず、かつ failure_count を increment する場合の トランザクション境界 | — | — |
| 6 | メモリ効率化 | スナップショット 500件上限、大規模スケジュール層への対応（ページング等） | — | — |
| 7 | パフォーマンス要件 | 日次に 1000件/分以上の振替要件確認、DB インデックス戦略 | — | — |
| 8 | マルチ通貨対応 | 現在 JPY のみ、将来の通貨追加時の アーキテクチャ設計 | — | — |
| 9 | リトライ FSM の詳細 | SQLSTATE 分類・バックオフ戦略を Java で実装する方針 | — | — |

---

*テンプレートバージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, doc/work/modernization-brief.md*
