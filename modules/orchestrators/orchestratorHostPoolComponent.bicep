import { hostPoolType, existingLogAnalyticsWorkspaceType, domainJoinIdentityType } from 'types.bicep'

@description('URI for the Session Host registration Zip package required for onboarding AVD session hosts using Desired State Configuration.')
param sessionHostRegistrationModuleUrl string
@description('Sas token for the sessionHostRegistrationModuleUrl')
@secure()
param sessionHostRegistrationModuleSasToken string
@description('Object describing an existing Log Analytics Workspace. If provided, the host pool will be configured to send diagnostic data to this workspace. If not provided, diagnostic data will not be sent to a Log Analytics Workspace.')
param existingLogAnalyticsWorkspaceObject existingLogAnalyticsWorkspaceType?
@description('General location of the deployment')
param location string
@description('The avd Bicep resources have their own resource parameter as not all Azure regions are available for the creation of these resources.')
param avdResourceLocation string
@description('Object describing the host pool to be created')
param hostPoolObject hostPoolType
@description('PW for the local admin when the avd VMs are created.This is a secure value.')
@secure()
param sessionHostPassword string
@description('Domain to join')
param domainFqdn string
@description('Add a OUPath if needed. The avd VMs will be created in that OU')
param ouPath string = ''
@description('A secure object for providing the details of the identity that will perform the domain join on the provided DomainFQDN')
param domainJoinIdentityObject domainJoinIdentityType

var namingConventionObject = {
  virtualMachineOSDiskSuffix: 'osdisk'
}
var roleDefinitionObject = {
  'Desktop Virtualization User': '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
}

module hostPool '../resources/desktop-virtualization/host-pool/main.bicep' = {
  scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
  name: take('AVD-HostPool-${hostPoolObject.name}', 64)
  params: {
    resourceName: hostPoolObject.name
    location: avdResourceLocation
    tagObject: hostPoolObject.?tagObject
    friendlyName: hostPoolObject.displayName
    hostPoolDescription: hostPoolObject.description
    type: 'Pooled'
    personalDesktopAssignmentType: 'Automatic'
    maxSessionLimit: hostPoolObject.maxSessionLimit
    loadBalancerType: hostPoolObject.loadBalancerType
    customRdpProperty: hostPoolObject.?customRdpProperty
  }
}

module hostPoolDiagnostics '../resources/insights/host-pool-diagnostic-settings/main.bicep' =
  if (existingLogAnalyticsWorkspaceObject != null) {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-HostPool-DiagnosticSettings-${hostPoolObject.name}', 64)
    dependsOn: [
      hostPool
    ]
    params: {
      hostPoolName: hostPoolObject.name
      logAnalyticsWorkspaceName: existingLogAnalyticsWorkspaceObject!.name
      logAnalyticsWorkspaceResourceGroup: existingLogAnalyticsWorkspaceObject!.?resourceGroupName
      logAnalyticsWorkspaceSubscriptionId: existingLogAnalyticsWorkspaceObject!.?subscriptionId
    }
  }

module applicationGroup '../resources/desktop-virtualization/application-group/main.bicep' = [
  for applicationGroupObject in hostPoolObject.applicationGroupObjectList: {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-ApplicationGroup-${applicationGroupObject.name}', 64)
    dependsOn: [
      hostPool
    ]
    params: {
      resourceName: applicationGroupObject.name
      location: avdResourceLocation
      tagObject: applicationGroupObject.?tagObject
      friendlyName: applicationGroupObject.?displayname
      applicationGroupDescription: applicationGroupObject.?description
      type: applicationGroupObject.type
      hostPoolName: hostPoolObject.name
    }
  }
]

module applicationGroupRoleAssignment '../resources/desktop-virtualization/application-group-role-assignment/main.bicep' = [
  for applicationGroupObject in hostPoolObject.applicationGroupObjectList: if (applicationGroupObject.assignmentList != null) {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-AppAssignment-${applicationGroupObject.name}', 64)
    dependsOn: [
      applicationGroup
    ]
    params: {
      roleAssignmentName: 'DesktopVirtualizationUser'
      principalIds: applicationGroupObject.assignmentList!
      roleDefinitionId: roleDefinitionObject['Desktop Virtualization User']
      applicationGroupName: applicationGroupObject.name
      roleAssignmentDescription: 'Allows the specified user principal to access the Azure Virtual Desktop application group.'
    }
  }
]

module applicationComponent '../orchestrators/orchestratorApplicationComponent.bicep' = [
  for applicationGroupObject in hostPoolObject.?applicationGroupObjectList! ?? []: if (applicationGroupObject.?applicationObjectList != null) {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-ApplicationComponent-${applicationGroupObject.name}', 64)
    dependsOn: [
      applicationGroup
      applicationGroupRoleAssignment
    ]
    params: {
      applicationObjectList: applicationGroupObject.applicationObjectList!
      applicationGroupName: applicationGroupObject.name
    }
  }
]

module availabilitySet '../resources/compute/availability-set/main.bicep' = {
  scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
  name: 'AVD-AvSet-${hostPoolObject.availabilitySetObject.name}'
  params: {
    resourceName: hostPoolObject.availabilitySetObject.name
    location: location
    tagObject: hostPoolObject.availabilitySetObject.?tagObject
    skuName: 'Aligned'
    faultDomainCount: 2
    updateDomainCount: 5
  }
}

module sessionHostOrchestrator '../orchestrators/orchestratorSessionHostComponent.bicep' = [
  for sessionHost in hostPoolObject.sessionHostsObject.sessionHostObjectList: {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-sessionHost-${sessionHost.virtualMachineName}', 64)
    dependsOn: [
      availabilitySet
      hostPool
    ]
    params: {
      sessionHostRegistrationModuleUrl: sessionHostRegistrationModuleUrl
      sessionHostRegistrationModuleSasToken: sessionHostRegistrationModuleSasToken
      location: location
      tagObject: sessionHost.?tagObject
      existingLogAnalyticsWorkspaceObject: existingLogAnalyticsWorkspaceObject
      linkedAvailabilitySetName: availabilitySet.outputs.resourceName
      virtualMachineName: sessionHost.virtualMachineName
      virtualMachineImageResourceId: sessionHost.?virtualMachineImageResourceId ?? hostPoolObject.sessionHostsObject.?sessionHostImageResourceId ?? null
      virtualMachineImagePublisher: sessionHost.?virtualMachineImagePublisher ?? hostPoolObject.sessionHostsObject.?sessionHostImagePublisher ?? null
      virtualMachineImageOffer: sessionHost.?virtualMachineImageOffer ?? hostPoolObject.sessionHostsObject.?sessionHostImageOffer ?? null
      virtualMachineImageSku: sessionHost.?virtualMachineImageSku ?? hostPoolObject.sessionHostsObject.?sessionHostImageSku ?? null
      virtualMachineImageVersion: sessionHost.?virtualMachineImageVersion ?? hostPoolObject.sessionHostsObject.?sessionHostImageVersion ?? null
      virtualMachineSize: sessionHost.virtualMachineSize
      storageType: hostPoolObject.sessionHostsObject.?ephemeralOSDisk != null ? 'Standard_LRS' : 'Premium_LRS'
      osDiskSize: sessionHost.?virtualMachineOSDiskSize != 0 || sessionHost.?virtualMachineOSDiskSize != null
        ? sessionHost.?virtualMachineOSDiskSize
        : hostPoolObject.sessionHostsObject.sessionHostOSDiskSize
      osDiskName: '${sessionHost.virtualMachineName}${namingConventionObject.virtualMachineOSDiskSuffix}'
      adminUserName: hostPoolObject.sessionHostsObject.sessionHostAdminUserName
      adminPassword: sessionHostPassword
      hostPoolName: hostPoolObject.name
      hostPoolToken: hostPool.outputs.registrationInfo.token
      domainJoinIdentityUserName: domainJoinIdentityObject.userName
      domainJoinIdentityPassword: domainJoinIdentityObject.password
      domainFqdn: domainFqdn
      ouPath: ouPath
      timeZone: sessionHost.?timeZone ?? hostPoolObject.sessionHostsObject.?timeZone ?? ''
      licenseType: sessionHost.?licenseType ?? hostPoolObject.sessionHostsObject.?licenseType ?? 'None'
      ephemeralOsDisk: hostPoolObject.sessionHostsObject.?ephemeralOSDisk ?? false
      encryptionAtHostEnabled: sessionHost.?encryptionAtHostEnabled ?? false
      networkInterfaceObject: sessionHost.networkInterfaceObject
    }
  }
]
