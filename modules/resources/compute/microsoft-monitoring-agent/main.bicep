@description('The location for the Azure resource.')
param location string = resourceGroup().location
@description('The subscription ID of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceSubscriptionId string?
@description('The resource group of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceResourceGroup string?
@description('The name of the shared log analytics workspace instance to log to')
param logAnalyticsWorkspaceName string
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?
@description('The name of the virtual machine to install the extension on')
param virtualMachineName string

resource workspaceExisting 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(
    logAnalyticsWorkspaceSubscriptionId ?? subscription().subscriptionId,
    logAnalyticsWorkspaceResourceGroup ?? resourceGroup().name
  )
}

resource virtualMachineExisting 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: virtualMachineName
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: virtualMachineExisting
  name: 'MicrosoftMonitoringAgent'
  location: location
  tags: tagObject
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: workspaceExisting.properties.customerId
      azureResourceId: virtualMachineExisting.id
      stopOnMultipleConnections: 'true'
    }
    protectedSettings: {
      workspaceKey: listKeys(workspaceExisting.id, '2020-03-01-preview').primarySharedKey
    }
  }
}

output resourceName string = extension.name
output resourceId string = extension.id
