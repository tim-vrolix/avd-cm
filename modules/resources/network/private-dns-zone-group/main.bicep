param resourceName string
param privateEndpointName string

@description('A custom object list for the private dns zones of the new group. Required properties are: \'Name\' and \'ResourceId\'.')
param privateDnsZoneObjectList privateDnsZoneType[]?

@export()
type privateDnsZoneType = {
  name: string
  resourceId: string
}
resource privateEndpointExisting 'Microsoft.Network/privateEndpoints@2022-05-01' existing = {
  name: privateEndpointName
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpointExisting
  name: resourceName
  properties: {
    privateDnsZoneConfigs: [
      for privateDnsZoneObject in privateDnsZoneObjectList! ?? []: {
        name: privateDnsZoneObject.name
        properties: {
          #disable-next-line use-resource-id-functions
          privateDnsZoneId: privateDnsZoneObject.resourceId
        }
      }
    ]
  }
}

output ResourceName string = privateDnsZoneGroup.name
output ResourceId string = privateDnsZoneGroup.id
