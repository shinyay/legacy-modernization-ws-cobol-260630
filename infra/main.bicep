// infra/main.bicep — Practice Bank Azure 雛形（ADR-0007/0026/0027）
// ACA env + PostgreSQL Flexible + Storage(Files for ISAM) + ACR + RabbitMQ コンテナ。
// provisioning は azd/Bicep（確実）、確認は Azure MCP。本番ランタイムは rehost コンテナ。
targetScope = 'resourceGroup'

@description('リソース名プレフィックス')
param namePrefix string = 'practicebank'
@description('リージョン')
param location string = resourceGroup().location
@description('PostgreSQL 管理者ユーザー')
param pgAdmin string = 'cobol'
@description('PostgreSQL 管理者パスワード')
@secure()
param pgPassword string

var laName = '${namePrefix}-logs'
var acaEnvName = '${namePrefix}-aca-env'
var acrName = toLower('${namePrefix}acr${uniqueString(resourceGroup().id)}')
var pgName = '${namePrefix}-pg'
var saName = toLower('${namePrefix}sa${uniqueString(resourceGroup().id)}')

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: laName
  location: location
  properties: { sku: { name: 'PerGB2018' }, retentionInDays: 30 }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: { name: 'Basic' }
  properties: { adminUserEnabled: true }
}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}
// ISAM(.idx) 用 Azure Files。ACA から SMB マウント。
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: '${saName}/default/isam-data'
}

resource pg 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01-preview' = {
  name: pgName
  location: location
  sku: { name: 'Standard_B1ms', tier: 'Burstable' }
  properties: {
    version: '15'
    administratorLogin: pgAdmin
    administratorLoginPassword: pgPassword
    storage: { storageSizeGB: 32 }
    backup: { backupRetentionDays: 7 }
  }
}

resource acaEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

// MQ: 当面 RabbitMQ コンテナ（stretch=Service Bus に置換）。
resource rabbit 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${namePrefix}-rabbitmq'
  location: location
  properties: {
    managedEnvironmentId: acaEnv.id
    configuration: { ingress: { external: false, targetPort: 5672 } }
    template: {
      containers: [ { name: 'rabbitmq', image: 'rabbitmq:3-management-alpine', resources: { cpu: 1, memory: '2Gi' } } ]
      scale: { minReplicas: 1, maxReplicas: 1 }
    }
  }
}

// 接続情報は Key Vault に集約（secretless: ACA は managed identity で参照）。
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${namePrefix}-kv${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

// ISAM .idx を ACA env へ Azure Files マウント。
resource acaStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: acaEnv
  name: 'isam'
  properties: {
    azureFile: {
      accountName: sa.name
      accountKey: sa.listKeys().keys[0].value
      shareName: 'isam-data'
      accessMode: 'ReadWrite'
    }
  }
}

// 初期ロード: 01-calendar（init_job, Manual/once）。
// ローカル疎通済み: make build → ops-master-load.sh calendar で calendar.idx を生成。
// ISAM 索引を Azure Files(isam) にマウントして永続化し、下流(09/13)が CAL-LOOKUP を共有。
resource jobCalendarInit 'Microsoft.App/jobs@2024-03-01' = {
  name: '${namePrefix}-init-calendar'
  location: location
  properties: {
    environmentId: acaEnv.id
    configuration: {
      triggerType: 'Manual'
      manualTriggerConfig: { parallelism: 1, replicaCompletionCount: 1 }
      replicaTimeout: 1800
      replicaRetryLimit: 1
    }
    template: {
      containers: [
        {
          name: 'calendar-init'
          image: '${acr.properties.loginServer}/practice-bank:latest'
          command: [
            'bash'
            '-lc'
            'make -C subsystems/01-calendar build && bash subsystems/22-operations/src/ops-master-load.sh calendar'
          ]
          resources: { cpu: json('0.5'), memory: '1Gi' }
          volumeMounts: [ { volumeName: 'isam', mountPath: '/workspace/subsystems/01-calendar/data' } ]
        }
      ]
      volumes: [ { name: 'isam', storageType: 'AzureFile', storageName: acaStorage.name } ]
    }
  }
}

// 日次バッチ: 23:00 JST(=14:00 UTC) 19→13→15→16→17→20。
resource jobDaily 'Microsoft.App/jobs@2024-03-01' = {
  name: '${namePrefix}-batch-daily'
  location: location
  properties: {
    environmentId: acaEnv.id
    configuration: { triggerType: 'Schedule', scheduleTriggerConfig: { cronExpression: '0 14 * * *', parallelism: 1 }, replicaTimeout: 14400 }
    template: { containers: [ { name: 'daily', image: '${acr.properties.loginServer}/practice-bank:latest', command: ['bash','subsystems/22-operations/bin/run-batch-daily-wrapper.sh','daily'], resources: { cpu: 1, memory: '2Gi' } } ] }
  }
}

// 月次バッチ: 1日02:00 JST(=前日17:00 UTC) 14→21。
resource jobMonthly 'Microsoft.App/jobs@2024-03-01' = {
  name: '${namePrefix}-batch-monthly'
  location: location
  properties: {
    environmentId: acaEnv.id
    configuration: { triggerType: 'Schedule', scheduleTriggerConfig: { cronExpression: '0 17 L * *', parallelism: 1 }, replicaTimeout: 14400 }
    template: { containers: [ { name: 'monthly', image: '${acr.properties.loginServer}/practice-bank:latest', command: ['bash','subsystems/22-operations/bin/run-batch-daily-wrapper.sh','monthly'], resources: { cpu: 1, memory: '2Gi' } } ] }
  }
}

output acrLoginServer string = acr.properties.loginServer
output acaEnvId string = acaEnv.id
output pgFqdn string = pg.properties.fullyQualifiedDomainName
output fileShareName string = 'isam-data'
output keyVaultName string = kv.name
output calendarInitJobName string = jobCalendarInit.name
