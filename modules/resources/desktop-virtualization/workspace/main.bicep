@description('The name of the workspace to be created.')
param resourceName string

@description('The friendly name of the workspace to be created.')
param friendlyName string?

@description('The description of the workspace to be created.')
param workspaceDescription string = 'Workspace created through DexMach template automation.'

@description('A list of objects of application groups that need to be linked to this workspace.')
param applicationGroupReferencesObjectList applicationGroupReferenceType[]?

@description('The location where the resources will be deployed.')
param location string = resourceGroup().location

@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

type applicationGroupReferenceType = {
  name: string
  resourceGroupName: string?
  subscriptionId: string?
}

resource applicationGroupExisting 'Microsoft.DesktopVirtualization/applicationGroups@2024-01-16-preview' existing = [
  for applicationGroup in applicationGroupReferencesObjectList! ?? []: if (applicationGroupReferencesObjectList != null) {
    name: applicationGroup.name
    scope: resourceGroup(
      applicationGroup.?subscriptionId ?? subscription().subscriptionId,
      applicationGroup.?resourceGroupName ?? resourceGroup().name
    )
  }
]

var applicationGroupReferences = [
  for (applicationGroup, index) in applicationGroupReferencesObjectList ?? []: applicationGroupExisting[index].id
]

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    friendlyName: friendlyName
    description: workspaceDescription
    applicationGroupReferences: applicationGroupReferencesObjectList != null ? applicationGroupReferences : null
  }
}

output resourceName string = workspace.name
output resourceId string = workspace.id
