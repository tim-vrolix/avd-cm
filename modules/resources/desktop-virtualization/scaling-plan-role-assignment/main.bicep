param hostPoolName string
param principalId string
param roleAssignmentName string
param roleDefinitionId string
param roleAssignmentDescription string?
resource roleDefinitionExisting 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitionId
}

resource hostPoolExisting 'Microsoft.DesktopVirtualization/hostPools@2022-02-10-preview' existing = {
  name: hostPoolName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: hostPoolExisting
  name: guid('${roleAssignmentName}-${resourceGroup().name}-${hostPoolName}-${principalId}')
  properties: {
    roleDefinitionId: roleDefinitionExisting.id
    principalId: principalId
    description: roleAssignmentDescription
  }
}

output resourceName string = roleAssignment.name
output resourceId string = roleAssignment.id
