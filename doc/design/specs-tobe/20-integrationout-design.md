# サブシステム設計書：20-integrationout（連携OUT — イベント発行）

> **TO-BE 設計書** — COBOL/RabbitMQ から Java/Spring Boot/RabbitMQ への移行設計書

---

## 基本情報

| 項目 | 内容 |
|---|---|
| サブシステム名 | `20-integrationout` — 連携OUT（イベント発行） |
| ディレクトリ | [subsystems/20-integrationout/](../../../subsystems/20-integrationout/) |
| 分類 | トランザクション処理系（イベント発行・外部連携） |
| API契約（AS-IS） | [copy/api/into-api.cpy](../../../subsystems/20-integrationout/copy/api/into-api.cpy) |
| API契約（TO-BE） | `EventPublishingService` インターフェース（Java） |
| 作成日 | 2026-06-30 |
| ステータス | 起草 |

---

## 1. 処理概要

### 1.1 目的

データベースに記録された取引・利息・振替・手数料・明細書生成などのイベントを JSON 形式にシリアライズし、メッセージブローカ（RabbitMQ）の専用キュー（`pb.events`）へ発行する。外部システム（金融決済網・連携先銀行・報告・分析システム）への非同期イベント連携を実現。デッドレターキューの定期的なドレインも提供。

### 1.2 位置づけ・依存関係

| 区分 | 対象 | 内容 |
|---|---|---|
| 上流（呼び出し元） | 12-txnpost、13-interestaccrual、14-interestpost、15-autodebit、16-fee、17-statement | 各処理完了時にイベント発行を要求 |
| 下流（呼び出し先） | RabbitMQ（メッセージブローカ） | イベント発行・購読のためのメッセージキュー |
| 参照データ | DB（監査ログ） | INTO-PUBLISH-EVENT の完了後、21-audit へイベント記録 |
| 監視・リトライ | systemd timer / 外部スケジューラ | INTO-DRAIN-QUEUE を定期起動（デッドレターキュー整理） |

### 1.3 構成プログラム

| 主要クラス/メソッド | パッケージ | 機能 | 主要ロジック |
|---|---|---|---|
| `EventPublishingService` | `com.practice.integrationout.service` | イベント発行の主オーケストレーション | `publish(eventRequest)` |
| `EventBuilder` | `com.practice.integrationout.builder` | イベントペイロード・エンベロープ構築 | `build(eventType, businessData)` |
| `RabbitMQPublisher` | `com.practice.integrationout.messaging` | RabbitMQ への発行・接続管理 | `send(envelope, queue)` |
| `EventValidator` | `com.practice.integrationout.validator` | イベント入力値検証・型チェック | `validate(eventRequest)` |
| `DeadLetterQueueDrain` | `com.practice.integrationout.dlq` | デッドレターキューのメッセージ回収・ロギング | `drain(dlqName)` |
| `RetryPolicy` | `com.practice.integrationout.retry` | 指数バックオフ + ジッタ リトライ FSM | `executeWithRetry(publisher)` |
| `AuditEventPublisher` | `com.practice.integrationout.audit` | 21-audit への非同期イベント記録 | `auditPublish(eventId, result)` |

### 1.4 起動方式

| 項目 | 内容 |
|---|---|
| 起動形態 | 非同期バッチ / リアルタイムイベント駆動 |
| 実行契機 | 12-txnpost 等の処理完了時、または 17-statement 処理完了時のイベント発行リクエスト / systemd timer による定期的な DLQ ドレイン |
| 多重度・冪等性 | 完全冪等。イベント ID（UUID）の重複排除機構を備え、同一イベントの再発行は同一 event_id で識別。 |
| リカバリ | RabbitMQ 接続失敗時：指数バックオフ + ジッタ リトライ（最大 5 回）。デッドレターキュー送付。DLQ ドレイン処理で手動復帰可能。 |

---

## 2. 処理詳細

### 2.1 処理フロー

```
【PUBLISH フロー】

1. 入力パラメータ検証
   - eventType: txn.posted / interest.posted / autodebit.failed / batch.completed / statement.generated
   - businessDate: YYYYMMDD 営業日
   - primaryId: txn_id / batch_id など
   - mode: R（リアル） / M（モック）

2. イベント入力値の正当性チェック
   - eventType の enum チェック
   - businessDate の形式・営業日判定
   - 必須フィールドの null チェック

3. UUID 生成（イベント一意識別）
   - java.util.UUID.randomUUID() で生成
   - event_id として使用

4. ペイロード構築
   - event_type, business_date, primary_id, amount_jpy, category, details を JSON 化
   - ISO8601 形式のタイムスタンプ付与（発行時刻）

5. エンベロープ構築
   - {
       "event_id": "550e8400-e29b-41d4-a716-446655440000",
       "event_type": "txn.posted",
       "timestamp": "2026-06-30T15:45:30.123+09:00",
       "source": "practice-bank/12-txnpost",
       "version": "1.0",
       "payload": { ... }
     }

6. モード判定
   - mode='R'（リアル）: RabbitMQ へ送信
   - mode='M'（モック）: ログファイル `/tmp/mq-mock-out.dat` へ書込

7. RabbitMQ 発行（リトライ FSM）
   a. 接続確認（ホスト/ユーザ/パスワード）
   b. PUBLISH-WITH-RETRY（指数バックオフ + ジッタ）
      - 試行1: 即座
      - 試行2: 10ms + jitter
      - 試行3: 20ms + jitter
      - 試行4: 40ms + jitter
      - 試行5: 80ms + jitter（最大）
   c. SQLCODE/AMQ コード判定
      - 成功→ commit、event_id を返す
      - 接続失敗/タイムアウト→ DEFER（DLQ へ移動）
      - その他→ FATAL

8. 監査ログ記録（非同期）
   - 21-audit へ action='EVENT_PUBLISHED', event_id, result_code を記録

9. 返却
   - status='00' / event_id / duration_ms / retry_count


【DRAIN フロー】

1. DLQ（デッドレターキュー）接続
   - キュー名: `pb.events.dlq`

2. DLQ メッセージ読取（ACK なし）
   FOR EACH message IN dlq:
   a. メッセージヘッダ抽出（event_id, original_event_type, timestamp, error_reason）
   b. ログ記録（WARN/ERROR レベル）
      - "DLQ: event_id={id}, type={type}, reason={reason}, timestamp={ts}"
   c. メッセージ削除（確認済みとして）
   d. 監査ログへ記録（action='DLQ_DRAINED'）

3. DLQ クリア確認
   - 残りメッセージ数ログ出力
   - 空になるまで続行

4. 統計情報
   - ドレイン対象メッセージ数
   - ドレイン完了時刻
   - 処理時間

5. 返却
   - status='00' / messages_drained / duration_ms
```

### 2.2 主要ロジック・業務ルール

| # | ルール/分岐 | 内容 |
|---|---|---|
| 1 | イベント型の固定化 | eventType は enum で定義（`TXN_POSTED`, `INTEREST_POSTED`, `AUTODEBIT_FAILED`, `BATCH_COMPLETED`, `STATEMENT_GENERATED`）。無効型は即座に `08` 返却。 |
| 2 | UUID 一意性 | event_id は完全冪等の鍵。重複チェック用 DLQ から復帰時は同じ UUID を再利用。 |
| 3 | リトライ戦略 | 接続エラー・タイムアウト時のみリトライ。業務エラー（入力不正等）はリトライしない。 |
| 4 | バックオフ計算 | `MIN(base * 2^retry, cap) + jitter`（base=10ms, cap=2000ms, max_retry=5） |
| 5 | ジッタ | `random(0..1000)` ms を加算。リトライストーミングを防止。 |
| 6 | モック vs リアル | mode='M' 時はファイル出力で DB/ブローカアクセスなし。ローカルテスト用。 |
| 7 | ペイロード正規化 | 数値（金額）は `BigDecimal` で精度確保。文字列は UTF-8。日付は ISO8601。 |
| 8 | タイムスタンプ正規化 | `ZonedDateTime.now(ZoneId.of("Asia/Tokyo"))` で発行時刻を JST で統一。 |
| 9 | DLQ 手動ドレイン | RabbitMQ 관理자が手動で DLQ をドレインすることも考慮。ドレイン時刻・理由をログに記録。 |
| 10 | 非同期監査ログ | イベント発行と監査ログ記録を `@Async` で分離。監査失敗がイベント発行を阻害しない。 |

### 2.3 戻り値コード

| コード | 意味 | 発生条件 |
|---|---|---|
| `00` | 正常完了 | イベントが RabbitMQ に正常に発行され、event_id が取得できた。 |
| `04` | リトライ枯渇（DLQ へ転送） | 最大リトライ回数（5回）に達し、メッセージが DLQ に移動。`retry_count=5` で返す。 |
| `08` | 入力不正 | eventType 無効 / businessDate 形式エラー / 必須フィールド null。リトライなし。 |
| `10` | DLQ 空 | INTO-DRAIN-QUEUE 実行時、DLQ にメッセージがない。 |
| `12` | ブローカ通信失敗 | RabbitMQ 接続失敗（ホスト不達 / 認証失敗）。リトライ対象。 |
| `16` | 致命的エラー | JSON シリアライズ失敗 / メモリ不足 / 予期しない例外。スタックトレース出力。 |

### 2.4 排他・トランザクション制御

- **非同期・イベント駆動**：RabbitMQ メッセージ発行は非トランザクション。失敗時は DLQ へ自動転送。
- **監査ログ**：イベント発行完了後に非同期で監査 DB に INSERT。監査失敗がイベント発行を巻き込まない。
- **冪等性**：event_id（UUID）で重複排除。同じ event_id の再発行は NOOP（ブローカキャッシュで検出可能）。
- **DLQ ポーリング**：DLQ ドレイン時は手動 ACK で確認。タイムアウト時は自動ロールバック（再投入）。
- **トランザクション隔離**：不要。イベント発行は読取・参照のみで、DB 更新なし。

### 2.5 エラー処理・ログ

| 事象 | 処理 | ログ出力 |
|---|---|---|
| RabbitMQ 接続タイムアウト | リトライ（指数バックオフ）→ DLQ へ転送 | WARN: "RabbitMQ connection timeout, retrying... retry={count}" |
| 認証失敗（user/password） | 即座に `12` 返却 | ERROR: "RabbitMQ authentication failed: {reason}" |
| ペイロード構築失敗 | 即座に `16` 返却 | ERROR: "Event serialization failed: {exception}, event_type={type}" |
| eventType 無効 | 即座に `08` 返却 | ERROR: "Invalid event type: {type}" |
| DLQ メッセージ処理失敗 | ACK なしで続行（スキップ） | WARN: "DLQ message processing failed, skipping: {msg_id}" |
| 監査ログ記録失敗 | ログのみ出力（イベント発行には影響なし） | WARN: "Audit log insertion failed: {exception}" |
| OUT OF MEMORY | イベント生成スキップ。メモリダンプ試行。 | ERROR: "Out of memory during event publishing: {heap_status}" |

---

## 3. 入力インターフェース

### 3.1 入力パラメータ（呼び出し時）

API契約: `com.practice.integrationout.api.EventPublishingRequest`

| パラメータ名 | 型 | 必須 | 説明 | 制約・取り得る値 |
|---|---|---|---|---|
| `eventType` | String | ✓ | イベント種別 | `TXN_POSTED` / `INTEREST_POSTED` / `AUTODEBIT_FAILED` / `BATCH_COMPLETED` / `STATEMENT_GENERATED` |
| `businessDate` | LocalDate (YYYYMMDD) | ✓ | 業務日 | 営業日である必要がある。カレンダーマスタで検証。 |
| `primaryId` | String | ✓ | 一次識別子 | txn_id (16文字) / batch_id / statement_id 等。eventType に応じて形式可変。 |
| `secondaryId` | String | — | 二次識別子 | account_id / customer_id 等。eventType により異なる。 |
| `amountJpy` | BigDecimal | — | 金額（JPY） | 取引・利息・手数料のみ。负数可（返戻・取消）。 |
| `category` | String | — | 区分コード | 10=入金 / 20=出金 / 30=振替 / 40=仕向送金 / 50=利息 / 60=手数料 |
| `details` | Map<String, Object> | — | 詳細情報 | イベント種別ごとの追加情報（JSON オブジェクト）。例: `{ "reversal_reason": "顧客要望" }` |
| `mode` | String | — | 発行モード | `R`（リアル/RabbitMQ）/ `M`（モック/ファイル）。デフォルト `R`。 |
| `operatorId` | String | — | オペレータID | 手動発行時のトレーサビリティ。自動発行は null。 |

### 3.2 入力データソース

| 種別 | 対象 | 形式 | キー | 備考 |
|---|---|---|---|---|
| メッセージング | RabbitMQ | AMQP 0.9.1 | キュー `pb.events` | 発行先キュー |
| メッセージング | RabbitMQ | AMQP 0.9.1 | キュー `pb.events.dlq` | デッドレターキュー（リトライ枯渇メッセージ） |
| マスタ | `business_calendar` (DB) | PostgreSQL | calendar_date | 営業日判定用 |
| 参照 | イベント情報（呼び出し元より） | 引数 | — | 12-txnpost、17-statement 等からの API 呼び出し |

### 3.3 前提・事前条件

- RabbitMQ サーバ（`rabbitmq` ホスト、port 5672）が稼働していること
- ユーザ `cobol` が RabbitMQ に認証済みであること
- キュー `pb.events` と `pb.events.dlq` が事前に作成されていること
- 交換機 `pb.exchange`（type=topic）が存在し、キューがバインドされていること
- `$DATA_HOME` 環境変数が設定されていること（モック時）

---

## 4. 出力インターフェース

### 4.1 出力パラメータ（リターン時 - PUBLISH）

API契約: `com.practice.integrationout.api.EventPublishingResponse`

| パラメータ名 | 型 | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `status` | String | 戻り値コード | `00`/`04`/`08`/`12`/`16` の 5 パターン |
| `eventId` | UUID (String) | 発行されたイベントの一意識別子 | UUID フォーマット 36 文字（8-4-4-4-12）。status=`00` の場合のみ有意。 |
| `timestamp` | LocalDateTime | イベント発行時刻（JST） | ISO8601 形式で記録。ブローカへの送信時刻。 |
| `durationMs` | Long | 処理時間 | ミリ秒単位。リトライを含む総時間。 |
| `retryCount` | Integer | リトライ回数 | 0〜5。status=`04` の場合は 5。 |
| `errorMessage` | String | エラーメッセージ（失敗時） | status != `00` の場合のみ。 |
| `brokerResponse` | String | ブローカからの応答メッセージ | 技術詳細（デバッグ用）。status=`12` の場合に有意。 |

### 4.2 出力パラメータ（リターン時 - DRAIN）

API契約: `com.practice.integrationout.api.DeadLetterQueueDrainResponse`

| パラメータ名 | 型 | 説明 | 設定条件・変換ルール |
|---|---|---|---|
| `status` | String | 戻り値コード | `00`/`10`/`12`/`16` |
| `messagesDrained` | Integer | DLQ からドレインしたメッセージ数 | 0 以上。status=`10` の場合は 0。 |
| `durationMs` | Long | 処理時間 | ミリ秒単位 |
| `drainStartTime` | LocalDateTime | ドレイン開始時刻 | ISO8601 形式（JST） |
| `drainEndTime` | LocalDateTime | ドレイン完了時刻 | ISO8601 形式（JST） |
| `dlqRemainingCount` | Integer | ドレイン後の DLQ 残メッセージ数 | 正常完了なら 0 となるべき |

### 4.3 出力データ更新（副作用）

本サブシステムは **メッセージ発行のみ** で、DB への更新なし。

| 種別 | 対象 | 操作 | 目的 | 備考 |
|---|---|---|---|---|
| メッセージブローカ | `pb.events` キュー | PUBLISH | イベント発行 | RabbitMQ へメッセージ送信。確認応答で成功判定。 |
| メッセージブローカ | `pb.events.dlq` キュー | CONSUME / ACK | DLQ ドレイン | 失敗メッセージを回収・削除。 |
| 監査ログ（非同期） | 21-audit テーブル | INSERT | イベント発行記録 | action='EVENT_PUBLISHED', event_id を記録。監査失敗は無視。 |
| ローカルファイル | `/tmp/mq-mock-out.dat` | APPEND | モック出力 | mode='M' 時のみ。本番環境では使用しない。 |

### 4.3 後続・事後条件

- 正常発行されたイベント（status=`00`）は RabbitMQ の `pb.events` キューに配置され、外部購読者に即座に配信される
- リトライ枯渇のイベント（status=`04`）は `pb.events.dlq` に転送され、管理者による手動処理を待つ
- イベント ID は全システムで一意であり、重複排除・トレーサビリティの鍵として機能
- 監査ログにより、いつ・だれが・どのイベントを発行したかが追跡可能

---

## 5. レコード定義

### 5.1 入力レコード（EventPublishingRequest）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `eventType` | Enum | `TXN_POSTED` / `INTEREST_POSTED` / `AUTODEBIT_FAILED` / `BATCH_COMPLETED` / `STATEMENT_GENERATED` |
| `businessDate` | LocalDate | YYYY-MM-DD 形式 |
| `primaryId` | String | txn_id(16) / batch_id(32) |
| `secondaryId` | String | account_id(13) / customer_id(10) etc |
| `amountJpy` | BigDecimal | JPY 単位、小数点以下 2 桁 |
| `category` | String | 10/20/30/40/50/60 |
| `details` | Map | JSON シリアライズ用 |

### 5.2 出力レコード（EventEnvelope）

| フィールド名 | 型 | 説明 |
|---|---|---|
| `eventId` | UUID | イベント一意識別子 |
| `eventType` | String | イベント種別コード |
| `timestamp` | ZonedDateTime | ISO8601（JST） |
| `source` | String | 発行元システム（`practice-bank/20-integrationout`） |
| `version` | String | イベント形式バージョン（`1.0`） |
| `payload` | JSON Object | ビジネス データ |

### 5.3 RabbitMQ メッセージ形式

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "txn.posted",
  "timestamp": "2026-06-30T15:45:30.123+09:00",
  "source": "practice-bank/12-txnpost",
  "version": "1.0",
  "payload": {
    "txn_id": "2026063000000001",
    "business_date": "2026-06-30",
    "account_id": "0010020000001",
    "amount_jpy": "10000.00",
    "category": "10",
    "category_name": "入金",
    "posted_timestamp": "2026-06-30T15:45:00.000+09:00"
  }
}
```

---

## 6. モダナイゼーション差異メモ

| # | 項目 | AS-IS（COBOL/AMQP） | TO-BE（Java/Spring Boot） | 対応方針 |
|---|---|---|---|---|
| 1 | プログラム言語 | COBOL（Embedded AMQP） | Java（Spring AMQP ライブラリ） | ライブラリ活用で複雑度低減 |
| 2 | メッセージング | RabbitMQ ネイティブ（固定フォーマット） | Spring Boot RabbitTemplate（ビルダーパターン） | JSON シリアライズ自動化 |
| 3 | UUID 生成 | `/proc/sys/kernel/random/uuid` 読取 | `java.util.UUID.randomUUID()` | 標準機構で確実 |
| 4 | リトライロジック | COBOL EVALUATE / 計算 | Spring Retry + `@Retryable` アノテーション | 宣言的・保守性向上 |
| 5 | ジッタ実装 | COBOL `ACCEPT` + 計算 | `Random` クラス / `ThreadLocalRandom` | 効率的・スレッドセーフ |
| 6 | 日時処理 | COBOL FUNCTION CURRENT-DATE | `ZonedDateTime.now(JST)` | JST 明示・精度向上 |
| 7 | JSON ペイロード | 固定フォーマット文字列構築 | Jackson / Gson での自動シリアライズ | 型安全・バージョニング対応 |
| 8 | 監査ログ | 同期 CALL | Spring Event (@Async) | 非同期・分離・疎結合 |
| 9 | エラーハンドリング | COBOL EVALUATE ネスト | Java Exception 階層（EventPublishingException 等） | 構造化・スタックトレース自動ログ |
| 10 | モック実装 | `CHECK-MOCK-MODE` → ファイル書込 | Spring Profile（`test` / `dev`）+ Mock Bean | 統合テスト容易 |

---

## 7. イベント種別の詳細

### 7.1 txn.posted — 取引記帳

| フィールド | 型 | 説明 |
|---|---|---|
| `txn_id` | String(16) | 取引ID |
| `business_date` | LocalDate | 業務日 |
| `account_id` | String(13) | 口座番号 |
| `amount_jpy` | BigDecimal | 金額（借方正、貸方負） |
| `category` | String(2) | 区分コード |
| `counterparty_account` | String(13) | 相手先口座（振替時） |
| `posting_date` | LocalDateTime | 記帳日時 |

### 7.2 interest.posted — 利息計上

| フィールド | 型 | 説明 |
|---|---|---|
| `batch_id` | String(32) | バッチID |
| `business_date` | LocalDate | 月末日 |
| `account_id` | String(13) | 口座番号 |
| `accrued_amount_jpy` | BigDecimal | 累積利息 |
| `posted_amount_jpy` | BigDecimal | 今月計上額 |

### 7.3 autodebit.failed — 振替失敗

| フィールド | 型 | 説明 |
|---|---|---|
| `schedule_id` | String(32) | 振替指図ID |
| `business_date` | LocalDate | 業務日 |
| `account_id` | String(13) | 振替元口座 |
| `scheduled_amount_jpy` | BigDecimal | 予定額 |
| `failure_reason` | String(50) | 失敗理由（NF/CL/SU） |
| `failure_count` | Integer | 累積失敗回数 |

### 7.4 batch.completed — バッチ完了

| フィールド | 型 | 説明 |
|---|---|---|
| `batch_id` | String(32) | バッチID |
| `batch_type` | String(30) | バッチ種別（VALIDATE / SORT / POST / INTEREST / AUTODEBIT / FEE） |
| `business_date` | LocalDate | 業務日 |
| `status` | String(2) | 00/04/08/12/16 |
| `records_processed` | Integer | 処理件数 |
| `duration_sec` | Integer | 処理時間 |

### 7.5 statement.generated — 明細書生成

| フィールド | 型 | 説明 |
|---|---|---|
| `statement_id` | String(36) | 明細書ID（UUID） |
| `batch_id` | String(32) | 生成元バッチID |
| `business_date` | LocalDate | 明細基準日 |
| `statement_period` | String(17) | 集計期間（YYYY-MM-DD - YYYY-MM-DD） |
| `accounts_processed` | Integer | 処理口座数 |
| `output_filename` | String(256) | 出力ファイルパス |

---

## 8. 未解決事項

| # | 項目 | 対応方針 | 担当 | 期限 |
|---|---|---|---|---|
| 1 | RabbitMQ HA 構成 | クラスタ構成時の接続フェイルオーバー仕様。`spring.rabbitmq.addresses` に複数ホストを指定し、ライブラリの自動切り替えに依存。 | インフラ設計 | 2026-08-30 |
| 2 | メッセージ永続性・型付き DLQ | DLQ 内のメッセージの永続性保証・再投入仕様。TTL（Time To Live）の設定値決定。 | RabbitMQ 管理者 | 2026-08-30 |
| 3 | イベント版付け・後方互換性 | 新しいイベント形式への移行時の version フィールド活用。購読者側の互換性確保。 | API 設計 | 2026-09-15 |
| 4 | 最大リトライ回数の SLA | 5回が適切か。ビジネス要件（最大何ミリ秒まで許容するか）に基づき調整。 | SLA 設計 | 2026-08-30 |
| 5 | DLQ ドレイン後の復帰フロー | 管理者が DLQ メッセージを確認後、手動で再投入する手順。スクリプト化が必要か。 | 運用設計 | 2026-09-30 |
| 6 | イベント圧縮・バッチ発行 | 大量のイベント同時発行時の性能最適化。バッチパブリッシュ化の是非。 | パフォーマンス検証 | 2026-09-30 |
| 7 | 外部システムの購読者登録 | RabbitMQ の exchange/queue バインディング設定。購読者側の setup 方針。 | 連携設計 | 2026-09-15 |

---

## 9. リトライ FSM の詳細

### 9.1 状態遷移図

```
[INIT]
  ↓
[VALIDATE_INPUT]
  ├→ [ERROR_08: 入力不正] → RETURN 08
  └→ [BUILD_PAYLOAD]
     ↓
     [PUBLISH_ATTEMPT: 試行1]
     ├→ [SUCCESS] → [AUDIT_LOG] → RETURN 00
     ├→ [CONNECTION_ERROR] → [RETRY_LOOP]
     │  ├→ [RETRY_1: 10ms+jitter]
     │  │  ├→ [SUCCESS] → RETURN 00
     │  │  └→ [RETRY_2: 20ms+jitter]
     │  │     ├→ [SUCCESS] → RETURN 00
     │  │     └→ [RETRY_3: 40ms+jitter]
     │  │        ├→ [SUCCESS] → RETURN 00
     │  │        └→ [RETRY_4: 80ms+jitter]
     │  │           ├→ [SUCCESS] → RETURN 00
     │  │           └→ [RETRY_5_MAX: 160ms+jitter]
     │  │              ├→ [SUCCESS] → RETURN 00
     │  │              └→ [RETRY_EXHAUSTED] → [SEND_TO_DLQ] → RETURN 04
     │  └→ [AUTH_ERROR] → RETURN 12
     └→ [FATAL_ERROR] → RETURN 16
```

### 9.2 リトライ計算式

```
wait_time_ms = MIN(base_ms * 2^(retry_count), cap_ms) + jitter_ms

where:
  base_ms = 10
  cap_ms = 2000
  jitter_ms = random(0..1000)
  retry_count = 0, 1, 2, 3, 4

example:
  retry_0: 10 * 2^0 = 10 + jitter = 10..1010 ms
  retry_1: 10 * 2^1 = 20 + jitter = 20..1020 ms
  retry_2: 10 * 2^2 = 40 + jitter = 40..1040 ms
  retry_3: 10 * 2^3 = 80 + jitter = 80..1080 ms
  retry_4: 10 * 2^4 = 160 + jitter = 160..1160 ms （最大）
```

---

*設計書バージョン: 1.0 / 参照: doc/design/specs-asis/02-transaction-pipeline.md, subsystem-design-template.md, Spring Boot RabbitMQ Documentation*
