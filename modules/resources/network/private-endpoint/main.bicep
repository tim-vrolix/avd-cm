@description('The name of the private endpoint.')
param resourceName string
param location string = resourceGroup().location
@description('The subscription ID of the virtual network of the subnet')
param virtualNetworkSubscriptionId string?
@description('The resourcegroup of the virtual network of the subnet')
param virtualNetworkResourceGroupName string?
@description('The name of the virtual network of the subnet')
param virtualNetworkName string
@description('The name of the subnet')
param subnetName string
@description('List of private link service connection objects. Each object has a required \'Name\', \'PrivateLinkServiceId\' (=The resource id of private link service.) and \'GroupIdList\' (=The ID(s) of the group(s) obtained from the remote resource that this private endpoint should connect to).')
param privateLinkServiceConnectionObjectList privateLinkServiceConnectionType[]
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

@export()
type privateLinkServiceConnectionType = {
  @description('The name of the private link service connection object')
  name: string
  @description('The resource id of private link service')
  privateLinkServiceId: string
  @description('The ID(s) of the group(s) obtained from the remote resource that this private endpoint should connect to.')
  groupIdList: string[]
}

resource virtualNetworkExisting 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(
    virtualNetworkSubscriptionId ?? subscription().subscriptionId,
    virtualNetworkResourceGroupName ?? resourceGroup().name
  )
}

resource subnetExisting 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: subnetName
  parent: virtualNetworkExisting
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: resourceName
  tags: tagObject
  location: location
  properties: {
    subnet: {
      id: subnetExisting.id
    }
    privateLinkServiceConnections: [
      for privateLinkServiceConnectionObject in privateLinkServiceConnectionObjectList: {
        name: privateLinkServiceConnectionObject.name
        properties: {
          #disable-next-line use-resource-id-functions
          privateLinkServiceId: privateLinkServiceConnectionObject.privateLinkServiceId
          groupIds: privateLinkServiceConnectionObject.groupIdList
        }
      }
    ]
  }
}

output resourceName string = privateEndpoint.name
output resourceId string = privateEndpoint.id
