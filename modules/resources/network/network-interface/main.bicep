param resourceName string
param location string
param virtualNetworkName string?
param subnetName string?

@description('As a second option to provide networking information, instead of providing the \'VirtualNetworkName\' and \'SubnetName\' parameters you can also provide the exact resource id to the subnet in which you want to create the NIC. If you provide this value this parameter will always take precedence over the naming parameters.')
param subnetResourceId string?

@description('Optional parameter. Provide this address (without subnet mask) if you want a static allocation of a chosen private IP address and make sure to adjust the \'AllocationMethod\' parameter.')
param ipAddress string?

param allocationMethod ('Dynamic' | 'Static') = 'Dynamic'

@description('The name of the public IP resource if you want to connect this resource. If you\'re using the naming parameter, the resource is expected to exist within the currently targetted resource group and subscription.')
param publicIPName string?

@description('As a second option to provide public ip information, instead of providing the \'PublicIPName\' parameter you can also provide the exact resource id to the public IP address resource. If you provide this value this parameter will always take precedence over the naming parameter.')
param publicIPResourceId string?

@description('An optional list of custom backend pool objects.')
param backendPoolObjectList backendPoolType[]?
param networkSecurityGroupName string?

@description('As a second option to provide network security group information, instead of providing the \'NetworkSecurityGroupName\' parameter you can also provide the exact resource id to the network security group resource. If you provide this value this parameter will always take precedence over the naming parameter.')
param networkSecurityGroupResourceId string?
param enableAcceleratedNetworking bool = false
param enableIPForwarding bool = false
param primaryInterface bool = true

@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

@export()
@description('''
Properties \'LoadBalancerName\' and \'BackendPoolName\' if the backend pool exists within the targetted resource group and subscription.
Property \'BackendPoolResourceId\' if you want to provide the entire resource id. The resource id property will always take precedence if it is found to be provided in one of the objects.
''')
type backendPoolType = {
  @description('The name of the load balancer resource.')
  loadBalancerName: string
  backendPoolName: string
  backendPoolResourceId: string?
}

var publicIPProperty = {
  id: publicIPResourceId != null
    ? publicIPName != null ? resourceId('Microsoft.Network/publicIPAddresses', publicIPName!) : publicIPResourceId
    : 'NoValidPublicIpResourceId'
}
var nsgProperty = {
  id: networkSecurityGroupResourceId != null
    ? networkSecurityGroupName != null
        ? resourceId('Microsoft.Network/networkSecurityGroups', networkSecurityGroupName!)
        : networkSecurityGroupResourceId
    : 'NoValidNSGResourceId'
}
var subnetProperty = {
  id: subnetResourceId != null
    ? virtualNetworkName != null && subnetName != null
        ? resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName!, subnetName!)
        : subnetResourceId
    : 'NoValidSubnetResourceId'
}
var backendPoolLoop = [
  for backendPoolObject in backendPoolObjectList! ?? []: {
    id: contains(backendPoolObject, 'BackendPoolResourceId')
      ? backendPoolObject.backendPoolResourceId
      : resourceId(
          'Microsoft.Network/loadBalancers/backendAddressPools',
          backendPoolObject.loadBalancerName,
          backendPoolObject.backendPoolName
        )
  }
]

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    ipConfigurations: [
      {
        name: '${resourceName}-ipconfig'
        properties: {
          primary: primaryInterface
          privateIPAllocationMethod: allocationMethod
          privateIPAddress: ipAddress
          subnet: subnetProperty
          publicIPAddress: empty(publicIPName) ? null : publicIPProperty
          // loadBalancerBackendAddressPools: [for j in range(0, length(BackendPoolObjectList)): BackendPoolLoop[j]]
          loadBalancerBackendAddressPools: [
            for (backendPoolObject, index) in backendPoolObjectList ?? []: backendPoolLoop[index]
          ]
        }
      }
    ]
    networkSecurityGroup: (empty(networkSecurityGroupName) ? null : nsgProperty)
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIPForwarding
  }
}

output resourceName string = networkInterface.name
output resourceId string = networkInterface.id
