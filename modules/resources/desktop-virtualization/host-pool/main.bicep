@description('The name of the HostPool to be created.')
param resourceName string

@description('The friendly name of the HostPool to be created.')
param friendlyName string?

@description('The description of the HostPool to be created.')
param hostPoolDescription string = 'HostPool created through DexMach template automation.'

@description('The location where the resources will be deployed.')
param location string = resourceGroup().location

@description('Set this parameter to Personal if you would like to enable Persistent Desktop experience. Defaults to false.')
param type ('Personal' | 'Pooled')

@description('Set the type of assignment for a Personal HostPool type')
param personalDesktopAssignmentType ('Automatic' | 'Direct') = 'Automatic'

@description('Maximum number of sessions.')
param maxSessionLimit int = 99999

@description('Type of load balancer algorithm.')
param loadBalancerType ('BreadthFirst' | 'DepthFirst' | 'Persistent') = 'BreadthFirst'

@description('HostPool rdp properties')
param customRdpProperty string?

@description('The necessary information for adding more VMs to this HostPool')
param vmTemplate string?

@description('Whether to use validation enviroment. A validation environment is HostPool configuration to signal Microsoft to introduce new WVD updates first on these types of environments so you can catch issues before that update is rolled out to non-validation environments (aka production).')
param validationEnvironment bool = false

@description('Current time that will be used to set the HostPool token expiration')
param currentTime string = utcNow('yyyy-MM-ddTHH:mm:00Z')
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?
var tokenExpirationTime = dateTimeAdd(currentTime, 'PT12H')

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2019-12-10-preview' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    friendlyName: friendlyName
    description: hostPoolDescription
    hostPoolType: type
    customRdpProperty: customRdpProperty
    personalDesktopAssignmentType: personalDesktopAssignmentType
    maxSessionLimit: maxSessionLimit
    loadBalancerType: loadBalancerType
    validationEnvironment: validationEnvironment
    ring: null
    registrationInfo: {
      expirationTime: tokenExpirationTime
      token: null
      registrationTokenOperation: 'Update'
    }
    vmTemplate: vmTemplate
    preferredAppGroupType: 'Desktop'
  }
}

output resourceName string = hostPool.name
output resourceId string = hostPool.id
@description('You can retrieve the registration token by accessing the "registrationToken" property of this object.')
output registrationInfo object = hostPool.properties.registrationInfo
