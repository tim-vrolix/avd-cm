@description('The name of the Application Group to be created.')
param resourceName string

@description('The friendly name of the Application Group to be created.')
param friendlyName string?

@description('The description of the Application Group to be created.')
param applicationGroupDescription string = 'Application Group created through DexMach template automation.'

@description('The location where the resources will be deployed.')
param location string = resourceGroup().location

@description('The type of the Application Group. Either desktop or remoteApp depending on what needs to be exposed to the user.')
param type ('Desktop' | 'RemoteApp')

@description('The name of the hostpool to which the Application Group will be linked.')
param hostPoolName string

@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools/', hostPoolName)
    friendlyName: friendlyName
    description: applicationGroupDescription
    applicationGroupType: type
  }
}

output resourceName string = applicationGroup.name
output resourceId string = applicationGroup.id
