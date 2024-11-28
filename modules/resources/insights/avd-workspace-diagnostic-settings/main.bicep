@description('The subscription ID of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceSubscriptionId string?
@description('The resource group of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceResourceGroup string?
@description('The name of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceName string

@description('The name of the AVD workspace')
param workspaceName string

resource workspaceExisting 'Microsoft.DesktopVirtualization/workspaces@2022-02-10-preview' existing = {
  name: workspaceName
}

resource logAnalyticsWorkspaceExisting 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(
    logAnalyticsWorkspaceSubscriptionId ?? subscription().subscriptionId,
    logAnalyticsWorkspaceResourceGroup ?? resourceGroup().name
  )
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: workspaceExisting
  name: 'toLogAnalytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceExisting.id
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

output resourceName string = diagnosticSetting.name
output resourceId string = diagnosticSetting.id
