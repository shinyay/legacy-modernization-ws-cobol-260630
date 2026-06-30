# Azure デプロイ Runbook（MVP / rehost）

> MVP は Azure 構築先行（az/MCP）、安定後に Bicep+azd へ写経（ADR-0029）。本書は**実デプロイ済みリソースの停止/削除手順**と**既知リスク**を記録する（deployer 原則: 課金リソースは runbook に停止/削除を残す）。

## 1. デプロイ済みリソース（rg-practicebank / japaneast）

| 種別 | 名前 | 備考 |
|---|---|---|
| Resource Group | `rg-practicebank` | 既存を再利用（新規作成せず） |
| ACA env | `cae-practicebank` | Consumption（VNet なし）。staticIp `48.218.101.216` |
| ACR | `acrpracticebank45261` | Basic, adminEnabled。image `practice-bank:app-latest` ほか |
| PostgreSQL Flexible | `pg-practicebank-5901` | v15, admin `cobol`, publicNetworkAccess Enabled, DB `banking` |
| ACA Jobs (Manual) | `pb-init-{calendar,branch,customer,product,interestrate,feeschedule,account}` | 7 master ロード |
| ACA Jobs (Manual) | `pb-batch-daily-rt` | 日次パイプライン real-mode 検証 job |
| ACA Jobs (Schedule) | `pb-batch-daily` | 日次パイプライン本番 job。cron `0 17 * * *`(UTC)=JST 02:00, real-mode |
| ACA Jobs (Schedule) | `pb-dormancy-scan` | 週次 dormancy/reactivation scan（9-ALC）。cron `0 18 * * 0`(UTC)=JST Mon 03:00, real-mode |
| ACA Jobs (Schedule) | `pb-batch-monthly` | 月次バッチ（ops-driver M）。cron `0 17 1 * *`(UTC)≈JST 2日 02:00, real-mode |
| ACA Jobs (Schedule) | `pb-partition-rollover` | 監査 partition rollover（ops-driver R / 21-audit）。cron `0 17 24 * *`(UTC)=JST 25日 02:00, real-mode |
| ACA Jobs (Manual) | `pb-batch`, `pb-dbcheck` | 既存 |

全 job は単一リポイメージを共有し、job 実行時に `make` でビルドする（Dockerfile が /workspace に全コピー）。

## 2. 既知リスク（A-1 採択：MVP 妥協）

**現状の構成**: PG firewall = `AllowAzureServices`(0.0.0.0) + `devbox-schema-apply`、PG admin パスワード = `cobol`（弱）。

- **根本原因**: COBOL orchestrator `ops-batch-daily.sqb` の `DB-CONNECT` が資格情報（user/pass=`cobol`/`cobol`, db=`banking`）を**ハードコード**。`PGPASSWORD` env を無視するため、Azure PG 側パスワードをアプリ期待値 `cobol` に合わせる必要がある。
- **ネットワーク閉域化の制約**: ACA Consumption（VNet なし）は**安定した outbound IP を持たない（SNAT プール）**。firewall を env staticIp に絞ると job から PG へ到達不可（A/B テストで確認済み）。そのため `AllowAzureServices` を許可せざるを得ない。
- **リスク**: 他テナント含む Azure 内部から、弱パスワード `cobol` で `banking` DB に到達試行が可能（インターネット公開ではない）。dev サブスク・MVP 限定として許容。

**ハードニング（本番移行フェーズ / フォローアップ）**:
- (B) アプリ `DB-CONNECT` を `PGUSER`/`PGPASSWORD` env 参照化し強パスワード維持（executor スコープ・要 ADR）。**本筋**。
- (A-2) ACA env を VNet 統合（env 再作成要）+ PG private endpoint で firewall を閉じる。

## 3. real-mode 実行（手動）

```bash
az containerapp job start -g rg-practicebank -n pb-batch-daily-rt
# 結果確認
az containerapp job execution list -g rg-practicebank -n pb-batch-daily-rt \
  --query "sort_by([],&properties.startTime)[-1].{name:name,status:properties.status}" -o json
```

現状、日次 6 step（19→13→15→16→17→20）は real-mode で **SOFT-SKIP (rc=11, v1.1 backlog)** され、orchestrator は STATUS=00 で完了する。RabbitMQ は step20 が soft-skip するため現時点で**不要**。

## 4. 停止 / 削除（teardown）

### 個別 job 削除
```bash
for j in pb-init-calendar pb-init-branch pb-init-customer pb-init-product \
         pb-init-interestrate pb-init-feeschedule pb-init-account pb-batch-daily-rt \
         pb-batch-daily pb-dormancy-scan pb-batch-monthly pb-partition-rollover; do
  az containerapp job delete -g rg-practicebank -n "$j" --yes
done
```

### firewall ルール削除
```bash
az postgres flexible-server firewall-rule delete -g rg-practicebank \
  -s pg-practicebank-5901 -n devbox-schema-apply --yes
az postgres flexible-server firewall-rule delete -g rg-practicebank \
  -s pg-practicebank-5901 -n AllowAzureServices --yes
```

### PG 停止（課金停止・データ保持）
```bash
az postgres flexible-server stop -g rg-practicebank -n pg-practicebank-5901
```

### 全削除（既存スタックも消える・要注意）
```bash
az group delete -n rg-practicebank --yes --no-wait
```

> 注意: `rg-practicebank` には本セッション以前から存在するリソース（ACA env / ACR / PG / pb-batch / pb-dbcheck）も含まれる。RG 全削除はそれらも消す。

## 5. 課金注意

- ACA Jobs（Manual）は**実行時のみ課金**（アイドル時ゼロ）。
- PG Flexible は**常時課金**。未使用時は `stop`（上記）。
- ACR Basic は少額の常時課金。
- RabbitMQ は未デプロイ（必要になれば常時課金 → 要 runbook 追記）。
