param applicationGroupName string
param principalIds string[]
param roleAssignmentName string
param roleDefinitionId string
param roleAssignmentDescription string = ''
resource roleDefinitionExisting 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitionId
}

resource applicationGroupExisting 'Microsoft.DesktopVirtualization/applicationGroups@2022-02-10-preview' existing = {
  name: applicationGroupName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [
  for principalId in principalIds: {
    scope: applicationGroupExisting
    name: guid('${roleAssignmentName}-${resourceGroup().name}-${applicationGroupName}-${principalId}')
    properties: {
      roleDefinitionId: roleDefinitionExisting.id
      principalId: principalId
      description: !empty(roleAssignmentDescription) ? roleAssignmentDescription : null
    }
  }
]
