# AS-IS 機能仕様書 — マスタ参照系（サブシステム 01〜09）

> ISAM索引ファイルを一次データとするマスタ参照・更新機能群。各機能は独立した COBOL プログラム（`PROGRAM-ID`）として実装され、コピーブックの API 契約（`copy/api/*.cpy`）経由で呼び出される。
> 共通規約・戻り値コードは [00-overview.md](00-overview.md) を参照。

## 目次

| # | サブシステム | ディレクトリ | 主機能 |
|---|---|---|---|
| 01 | calendar | [subsystems/01-calendar/](../../../subsystems/01-calendar/) | 営業日/祝日判定・翌前営業日 |
| 02 | branch | [subsystems/02-branch/](../../../subsystems/02-branch/) | 支店参照・一覧 |
| 03 | customer | [subsystems/03-customer/](../../../subsystems/03-customer/) | 顧客参照・検索・状態変更 |
| 04 | customersearch | [subsystems/04-customersearch/](../../../subsystems/04-customersearch/) | 顧客複合検索 |
| 05 | product | [subsystems/05-product/](../../../subsystems/05-product/) | 商品参照 |
| 06 | interestrate | [subsystems/06-interestrate/](../../../subsystems/06-interestrate/) | 金利参照（適用日別） |
| 07 | feeschedule | [subsystems/07-feeschedule/](../../../subsystems/07-feeschedule/) | 手数料体系参照 |
| 08 | account | [subsystems/08-account/](../../../subsystems/08-account/) | 口座参照・存在確認・休眠日更新 |
| 09 | accountlifecycle | [subsystems/09-accountlifecycle/](../../../subsystems/09-accountlifecycle/) | 口座開設・状態遷移・休眠スキャン |

各サブシステムは共通して `LOAD` プログラム（`.dat`→`.idx` ロード）と `LOOKUP`/`SEARCH` プログラムを持つ。

---

## 01-calendar — 営業日カレンダー

API契約: [copy/api/cal-api.cpy](../../../subsystems/01-calendar/copy/api/cal-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 | 主要PARAGRAPH |
|---|---|---|---|
| `CAL-LOAD` | [src/cal-load.cob](../../../subsystems/01-calendar/src/cal-load.cob) | シードを索引へロード | `MAIN-LOGIC`, `WRITE-CAL-RECORD`, `LOG-COMPLETE` |
| `CAL-LOOKUP` | [src/cal-lookup.cob](../../../subsystems/01-calendar/src/cal-lookup.cob) | 日付で区分照会（メモリキャッシュ最大1826件=5年） | `MAIN-LOGIC`, `LOAD-CACHE` |
| `CAL-NEXT-BD` | [src/cal-next-bd.cob](../../../subsystems/01-calendar/src/cal-next-bd.cob) | 翌営業日（最大10日先まで探索） | `MAIN-LOGIC` |
| `CAL-PREV-BD` | [src/cal-prev-bd.cob](../../../subsystems/01-calendar/src/cal-prev-bd.cob) | 前営業日 | `MAIN-LOGIC` |

### 入出力（cal-api.cpy）

- 入力 `CAL-INPUT`: `CAL-INPUT-DATE PIC 9(8)`（YYYYMMDD、範囲 20260101–20301231）
- 出力 `CAL-OUTPUT`: `CAL-STATUS PIC 9(2)`、`CAL-OUTPUT-DAY-TYPE PIC X(1)`（`B`=営業/`H`=祝日/`W`=週末）、`CAL-OUTPUT-HOLIDAY-NAME PIC X(40)`、`CAL-OUTPUT-NEXT-DATE PIC 9(8)`

### 戻り値

`00`=OK / `04`=該当なし / `08`=日付不正 / `12`=キャッシュ失敗 / `16`=致命的

### データ

[data/calendar-seed.dat](../../../subsystems/01-calendar/data/) → calendar.idx（60バイト固定、キー=日付8桁）。日本の祝日を含む。

---

## 02-branch — 支店マスタ

API契約: [copy/api/br-api.cpy](../../../subsystems/02-branch/copy/api/br-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `BR-LOAD` | [src/br-load.cob](../../../subsystems/02-branch/src/br-load.cob) | シードを索引へロード |
| `BR-LOOKUP` | [src/br-lookup.cob](../../../subsystems/02-branch/src/br-lookup.cob) | 支店コードで参照（ファイル永続オープン） |
| `BR-LIST-ALL` | [src/br-list-all.cob](../../../subsystems/02-branch/src/br-list-all.cob) | 全件順次（START LOW-VALUES→READ NEXT） |
| `BR-LIST-BY-REGION` | [src/br-list-by-region.cob](../../../subsystems/02-branch/src/br-list-by-region.cob) | 地域別（副キー `BR-REC-REGION`） |

### 入出力

- 入力 `BR-INPUT`: `BR-IN-CODE PIC X(3)`、`BR-IN-REGION PIC X(20)`、`BR-IN-OP PIC X(1)`（`L`=参照/`R`=地域一覧/`A`=全件）
- 出力 `BR-OUTPUT`: `BR-OUT-STATUS`、`BR-OUT-CODE`、`BR-OUT-NAME-KANJI PIC X(40)`、`BR-OUT-NAME-KANA PIC X(40)`、`BR-OUT-REGION`、`BR-OUT-STATUS-CODE`

### レコード定義（[copy/private/fd-branch.cpy](../../../subsystems/02-branch/copy/private/fd-branch.cpy)）

`BR-REC-CODE`(3, 主キー) / `BR-REC-NAME-KANJI`(40) / `BR-REC-NAME-KANA`(40) / `BR-REC-REGION`(20, 副キー) / `BR-REC-OPENED-DATE`(9(8)) / `BR-REC-STATUS`(1) / `BR-REC-FILLER`(20, 予約・未使用) ＝ レコード長132バイト固定

### 戻り値

`00`/`04`/`10`(EOF)/`16`（注: `08`=`BR-STATUS-INVALID` は API に定義されているが、いずれのプログラムも返さない）

---

## 03-customer — 顧客マスタ

API契約: [copy/api/cust-api.cpy](../../../subsystems/03-customer/copy/api/cust-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `CUST-LOAD` | [src/cust-load.cob](../../../subsystems/03-customer/src/cust-load.cob) | 3キー索引へロード |
| `CUST-LOOKUP` | [src/cust-lookup.cob](../../../subsystems/03-customer/src/cust-lookup.cob) | 顧客IDで参照 |
| `CUST-LIST-ALL` | [src/cust-list-all.cob](../../../subsystems/03-customer/src/cust-list-all.cob) | 全件順次 |
| `CUST-SEARCH-BY-KANA` | [src/cust-search-by-kana.cob](../../../subsystems/03-customer/src/cust-search-by-kana.cob) | カナ前方一致（副キー `CR-KANA`） |
| `CUST-SEARCH-BY-PHONE` | [src/cust-search-by-phone.cob](../../../subsystems/03-customer/src/cust-search-by-phone.cob) | 電話完全一致（副キー `CR-PHONE` を `START KEY =` で照会。前方一致ではない点に注意） |
| `CUST-STATUS-CHANGE` | [src/cust-status-change.cob](../../../subsystems/03-customer/src/cust-status-change.cob) | 状態変更＋監査記録（action=`CUST_STATUS_CHANGED`） |

### 入出力

- 入力 `CUST-INPUT`: `CUST-IN-ID PIC 9(10)`、`CUST-IN-KANA PIC X(50)`、`CUST-IN-PHONE PIC X(15)`、`CUST-IN-OP PIC X(1)`（`L`/`K`/`P`/`A`/` `=継続）
- 出力 `CUST-OUTPUT`: `CUST-OUT-STATUS`、`CUST-OUT-ID`、`CUST-OUT-KANA`、`CUST-OUT-KANJI PIC X(60)`、`CUST-OUT-PHONE`、`CUST-OUT-ADDRESS PIC X(200)`、`CUST-OUT-OPENED PIC 9(8)`（`CUST-LOOKUP` のみ設定。一覧/検索系では未設定）、`CUST-OUT-STATUS-CODE`

### レコード定義（[copy/private/fd-customer.cpy](../../../subsystems/03-customer/copy/private/fd-customer.cpy)）

`CR-ID`(9(10), 主キー) / `CR-KANA`(50, 副キー) / `CR-KANJI`(60) / `CR-PHONE`(15, 副キー) / `CR-ADDRESS`(200) / `CR-OPENED-DATE`(9(8)) / `CR-STATUS`(1) / `CR-CREATED-TS`/`CR-UPDATED-TS`(9(14)) / `CR-TIER`(1)

### 戻り値

`00`/`04`/`08`/`10`/`16`

> **モダナイゼーション注記**: PG `customers` テーブルには ISAM の `CR-OPENED-DATE` 相当列が無く、`tier`/`address`/`phone` の桁数が異なる（[04-shared-infrastructure.md](04-shared-infrastructure.md) § DBスキーマ参照）。

---

## 04-customersearch — 顧客複合検索

API契約: [copy/api/csrch-api.cpy](../../../subsystems/04-customersearch/copy/api/csrch-api.cpy)
データは 03-customer の索引を利用（自前データなし）。

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `CSRCH-AND` | [src/csrch-and.cob](../../../subsystems/04-customersearch/src/csrch-and.cob) | カナ前方一致 AND 電話前方一致の積集合（各最大200件→INTERSECT） |
| `CSRCH-BY-ADDRESS` | [src/csrch-by-address.cob](../../../subsystems/04-customersearch/src/csrch-by-address.cob) | 住所部分一致（全件走査 INSPECT） |
| `CSRCH-LIST-PAGED` | [src/csrch-list-paged.cob](../../../subsystems/04-customersearch/src/csrch-list-paged.cob) | ページング一覧 |

### 入出力

- 入力 `CSRCH-INPUT`: `CSRCH-KANA-PREFIX PIC X(50)`、`CSRCH-PHONE-PREFIX PIC X(15)`、`CSRCH-ADDR-SUBSTR PIC X(50)`、`CSRCH-PAGE-SIZE PIC 9(3)`、`CSRCH-START-AFTER PIC 9(10)`、`CSRCH-OP PIC X(1)`（`A`/`D`/`P`/` `）
- 出力 `CSRCH-OUTPUT`: `CSRCH-STATUS`、`CSRCH-MATCH-ID`、`CSRCH-MATCH-KANA/KANJI/PHONE/ADDR`、`CSRCH-LAST-ID`（カーソル）

### 戻り値

`00`/`10`(EOF)/`16`

---

## 05-product — 商品マスタ

API契約: [copy/api/prod-api.cpy](../../../subsystems/05-product/copy/api/prod-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `PROD-LOAD` | [src/prod-load.cob](../../../subsystems/05-product/src/prod-load.cob) | シードを索引へロード |
| `PROD-LOOKUP` | [src/prod-lookup.cob](../../../subsystems/05-product/src/prod-lookup.cob) | 商品コードで参照 |

### 入出力

- 入力 `PROD-INPUT`: `PRD-IN-CODE PIC X(3)`
- 出力 `PROD-OUTPUT`: `PRD-OUT-STATUS`、`PRD-OUT-CODE`、`PRD-OUT-NAME PIC X(40)`、`PRD-OUT-TYPE PIC X(1)`（`S`=普通/`C`=当座/`T`=定期）、`PRD-OUT-INTEREST-TYPE`、`PRD-OUT-ALLOW-OVD`、`PRD-OUT-TERM-DAYS PIC 9(4)`、`PRD-OUT-EFF-FROM/TO PIC 9(8)`

### レコード定義（[copy/private/fd-product.cpy](../../../subsystems/05-product/copy/private/fd-product.cpy)）

`PRD-REC-CODE`(3, 主キー) / `PRD-REC-NAME-KANJI`(40) / `PRD-REC-NAME-KANA`(40) / `PRD-REC-TYPE`(1) / `PRD-REC-INTEREST`(1) / `PRD-REC-OVD`(1) / `PRD-REC-MIN-BAL`(S9(15) COMP-3) / `PRD-REC-TERM-DAYS`(9(4)) / `PRD-REC-EFF-FROM/TO`

### 戻り値

`00`/`04`/`16`（注: `08` 入力不正は定義されていない）

---

## 06-interestrate — 金利マスタ

API契約: [copy/api/irate-api.cpy](../../../subsystems/06-interestrate/copy/api/irate-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `IRATE-LOAD` | [src/irate-load.cob](../../../subsystems/06-interestrate/src/irate-load.cob) | シードを索引へロード |
| `IRATE-LOOKUP` | [src/irate-lookup.cob](../../../subsystems/06-interestrate/src/irate-lookup.cob) | 商品+tier+適用日で参照。レートはマイクロ単位（×1,000,000）で返す |

### 入出力

- 入力 `IRATE-INPUT`: `IR-IN-PRODUCT PIC X(3)`、`IR-IN-TIER PIC 9(2)`、`IR-IN-EFFECTIVE PIC 9(8)`
- 出力 `IRATE-OUTPUT`: `IR-OUT-STATUS`、`IR-OUT-RATE-MICRO PIC 9(7)`（レート×1,000,000）、`IR-OUT-EFF-FROM/TO`

### レコード定義（[copy/private/fd-irate.cpy](../../../subsystems/06-interestrate/copy/private/fd-irate.cpy)）

複合キー `IR-REC-KEY`（`IR-REC-PRODUCT`(3) + `IR-REC-TIER`(9(2)) + `IR-REC-EFF-FROM`(9(8))）、`IR-REC-TIER-MIN/MAX`(S9(15) COMP-3)、`IR-REC-RATE`(S9(3)V9(4) COMP-3)、`IR-REC-EFF-TO`

### 戻り値

`00`/`04`/`16`

---

## 07-feeschedule — 手数料体系

API契約: [copy/api/fs-api.cpy](../../../subsystems/07-feeschedule/copy/api/fs-api.cpy)

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `FEE-LOAD` | [src/fee-load.cob](../../../subsystems/07-feeschedule/src/fee-load.cob) | シードを索引へロード（重複は無視） |
| `FEE-LOOKUP-BY-TIER` | [src/fee-lookup-by-tier.cob](../../../subsystems/07-feeschedule/src/fee-lookup-by-tier.cob) | 区分+tier+適用日で手数料額（JPY）参照 |

### 入出力

- 入力 `FS-INPUT`: `FS-IN-CATEGORY PIC 9(2)`（10/20/30/40）、`FS-IN-TIER PIC 9(2)`、`FS-IN-EFFECTIVE PIC 9(8)`
- 出力 `FS-OUTPUT`: `FS-OUT-STATUS`、`FS-OUT-FEE-JPY PIC S9(9)`、`FS-OUT-EFF-TO`

### レコード定義（[copy/private/fd-fs.cpy](../../../subsystems/07-feeschedule/copy/private/fd-fs.cpy)）

`RECORD CONTAINS 41 CHARACTERS`。複合キー `FS-REC-KEY`（`FS-REC-CATEGORY`(9(2)) + `FS-REC-TIER`(9(2)) + `FS-REC-EFF-FROM`(9(8))）、`FS-REC-TIER-MIN`(S9(15) COMP-3)、`FS-REC-TIER-MAX`(S9(15) COMP-3)、`FS-REC-AMOUNT`(S9(9) COMP-3)、`FS-REC-EFF-TO`(9(8)、`FS-OUT-EFF-TO` へ転記）

### 戻り値

`00`/`04`/`16`

---

## 08-account — 口座マスタ

API契約: [copy/api/acct-api.cpy](../../../subsystems/08-account/copy/api/acct-api.cpy)（4つのインターフェースを定義）

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `ACCT-LOAD` | [src/acct-load.cob](../../../subsystems/08-account/src/acct-load.cob) | シードを索引へロード（`COPY-FIELDS`でマッピング） |
| `ACCT-LOOKUP` | [src/acct-lookup.cob](../../../subsystems/08-account/src/acct-lookup.cob) | 口座番号で1件参照 |
| `ACCT-EXISTS` | [src/acct-exists.cob](../../../subsystems/08-account/src/acct-exists.cob) | 存在確認＋状態/商品コード/有効フラグ |
| `ACCT-LOOKUP-BY-CUSTOMER` | [src/acct-lookup-by-customer.cob](../../../subsystems/08-account/src/acct-lookup-by-customer.cob) | 顧客の全口座（副キー、最大50走査、挿入ソート、ページング） |
| `ACCT-UPDATE-DORMANCY-DATE` | [src/acct-update-dormancy-date.cob](../../../subsystems/08-account/src/acct-update-dormancy-date.cob) | 休眠日更新（状態A/D、新日≥旧日を検証） |

### インターフェース別 入出力・戻り値

#### LOOKUP

- 入力 `ACCT-LOOKUP-INPUT.ACCT-LOOKUP-NUMBER PIC 9(13)`
- 出力 `ACCT-LOOKUP-OUTPUT`: `ACCT-LO-NUMBER`(9(13))、`ACCT-LO-CUST-ID`(9(10))、`ACCT-LO-PRODUCT-CODE`(9(3))、`ACCT-LO-BRANCH-CODE`(9(3))、`ACCT-LO-OPENED-DATE`(9(8))、`ACCT-LO-CLOSED-DATE`(9(8))、`ACCT-LO-STATUS`(X(1) 88条件 `ACCT-ST-*`)、`ACCT-LO-OVERDRAFT-LIMIT`(S9(15) COMP-3)、`ACCT-LO-TERM-DAYS`(9(4))、`ACCT-LO-DORMANCY-DATE`(9(8))、`ACCT-LO-CREATED-TS`/`UPDATED-TS`(9(14))
- 戻り値 `ACCT-LOOKUP-STATUS`: `00`/`04`/`08`/`12`/`16`

#### EXISTS

- 入力 `ACCT-EXISTS-NUMBER PIC 9(13)`
- 出力: `ACCT-EXISTS-FOUND`(`Y`/`N`)、`ACCT-EXISTS-STATUS-CODE`、`ACCT-EXISTS-PRODUCT-CODE`、`ACCT-EXISTS-ACTIVE-FLAG`（状態=`A`なら`Y`）
- 戻り値 `ACCT-EXISTS-API-STATUS`: `00`/`04`/`08`/`12`/`16`

#### LOOKUP-BY-CUSTOMER

- 入力: `LOOKUP-BY-CUST-CUST-ID`(9(10))、`LOOKUP-BY-CUST-MAX`(9(2) COMP-3)、`LOOKUP-BY-CUST-START-AFTER`(9(13))
- 出力: `LOOKUP-BY-CUST-COUNT`、`LOOKUP-BY-CUST-MORE`(`Y`/`N`)、`LOOKUP-BY-CUST-LAST-ACCT`、`LOOKUP-BY-CUST-RECORDS OCCURS 20`
- 戻り値: `00`/`02`(重複警告)/`04`/`08`/`12`/`16`

#### UPDATE-DORMANCY

- 入力: `UPDATE-DORMANCY-ACCT-NUMBER`、`UPDATE-DORMANCY-NEW-DATE`
- 出力: `UPDATE-DORMANCY-PREV-DATE`、`UPDATE-DORMANCY-WAS-NOOP`(`Y`/`N`)
- 戻り値: `00`/`04`/`08`/`12`/`16`

### レコード定義（[copy/private/fd-account.cpy](../../../subsystems/08-account/copy/private/fd-account.cpy)）

`ACCT-REC-NUMBER`(9(13), 主キー) / `ACCT-REC-CUST-ID`(9(10), 副キー) / `ACCT-REC-PRODUCT-CODE`(9(3)) / `ACCT-REC-BRANCH-CODE`(9(3)) / `ACCT-REC-OPENED-DATE` / `ACCT-REC-CLOSED-DATE` / `ACCT-REC-STATUS`(1) / `ACCT-REC-OVERDRAFT`(S9(15) COMP-3) / `ACCT-REC-TERM-DAYS`(9(4)) / `ACCT-REC-DORMANCY-DATE` / `ACCT-REC-CREATED-TS`/`UPDATED-TS`

> **モダナイゼーション注記**: ISAM には `OVERDRAFT`（当座貸越枠）と `TERM-DAYS` があるが、PG `accounts` テーブルには対応列が無い。読み取りスライスでは「PGにある項目のみ返す」と割り切る（modernization-brief § 7）。

---

## 09-accountlifecycle — 口座ライフサイクル

API契約: [copy/api/alc-api.cpy](../../../subsystems/09-accountlifecycle/copy/api/alc-api.cpy)
レコード定義は 08-account の `fd-account.cpy` を共用。

### プログラム

| Program-ID | ファイル | 機能 |
|---|---|---|
| `ALC-OPEN` | [src/alc-open.cob](../../../subsystems/09-accountlifecycle/src/alc-open.cob) | 新規開設（番号採番=支店+商品+連番、初期状態`P`、監査記録） |
| `ALC-CHANGE-STATE` | [src/alc-change-state.cob](../../../subsystems/09-accountlifecycle/src/alc-change-state.cob) | 状態遷移（状態機械、監査記録） |
| `ALC-DORMANCY-SCAN` | [src/alc-dormancy-scan.cob](../../../subsystems/09-accountlifecycle/src/alc-dormancy-scan.cob) | 休眠化バッチ（基準日=業務日-730日、`TRANSITION-TO-D`） |
| `ALC-REACTIVATION-SCAN` | [src/alc-reactivation-scan.cob](../../../subsystems/09-accountlifecycle/src/alc-reactivation-scan.cob) | 再活性スキャン（現状スタブ、常に`04`を返す） |

### 状態遷移ルール（ALC-CHANGE-STATE）

| アクション | コード | 遷移 | 備考 |
|---|---|---|---|
| 有効化 | `AC` | P→A | |
| 取消 | `CN` | P→C | |
| 停止 | `SU` | A/D→S | 理由テキスト必須 |
| 停止解除 | `LS` | S→A | |
| 解約 | `CL` | A/D→C | |
| 強制解約 | `FC` | 非C→C | 理由テキスト必須 |

### 入出力・戻り値

- OPEN 入力: `ALC-OPEN-CUST-ID`(9(10))、`ALC-OPEN-PRODUCT-CODE`、`ALC-OPEN-BRANCH-CODE`、`ALC-OPEN-OPENED-DATE`、`ALC-OPEN-OVERDRAFT-LIMIT`(S9(15) COMP-3)、`ALC-OPEN-TERM-DAYS`。出力 `ALC-OPEN-ACCT-NUMBER`。戻り値 `00`/`04`/`08`/`12`/`16`
- CHANGE 入力: `ALC-CHANGE-ACCT-NUMBER`、`ALC-CHANGE-ACTION-CODE`(88条件 `ALC-ACT-*`)、`ALC-CHANGE-REASON-TEXT PIC X(80)`、`ALC-CHANGE-BUSINESS-DATE`。出力 `ALC-CHANGE-FROM-STATUS`/`TARGET-STATUS`
- DORMANCY-SCAN 入力: `ALC-DORMANCY-BUSINESS-DATE`。出力 `ALC-DORMANCY-TRANSITIONED`/`SKIPPED`(9(6))。戻り値 `00`/`04`(候補なし)/`12`/`16`
- REACTIVATION-SCAN: 同形（スタブ）

---

## 共通連携ポイント

| 連携先 | 用途 | コピーブック |
|---|---|---|
| 21-audit（AUD-WRITE） | 状態変更・開設の監査記録 | [shared/copy/aud-write-api.cpy](../../../shared/copy/aud-write-api.cpy) |
| 共有ログ（SHARED-LOG） | ロード処理等の構造化ログ | [shared/copy/shared-log-api.cpy](../../../shared/copy/shared-log-api.cpy) |
| 01-calendar | 休眠日計算・営業日判定 | [shared/copy/ws-date-validate.cpy](../../../shared/copy/ws-date-validate.cpy) |
