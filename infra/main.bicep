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

output acrLoginServer string = acr.properties.loginServer
output acaEnvId string = acaEnv.id
output pgFqdn string = pg.properties.fullyQualifiedDomainName
output fileShareName string = 'isam-data'
