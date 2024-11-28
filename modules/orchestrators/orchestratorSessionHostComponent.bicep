import { sessionHostType, existingLogAnalyticsWorkspaceType, networkInterfaceType } from 'types.bicep'

@description('Object describing an existing Log Analytics Workspace. If provided, the host pool will be configured to send diagnostic data to this workspace. If not provided, diagnostic data will not be sent to a Log Analytics Workspace.')
param existingLogAnalyticsWorkspaceObject existingLogAnalyticsWorkspaceType?
@description('URI for the Session Host registration Zip package required for onboarding AVD session hosts using Desired State Configuration.')
param sessionHostRegistrationModuleUrl string
@secure()
@description('SAS token to the Location. This is a secure value. On commandline deployments you can add this manually but do not commit this to Git. Through Azure Pipelines we use a secure variable group injection to protect the value in a Git scenario.')
param sessionHostRegistrationModuleSasToken string
@description('Name of the availability set')
param linkedAvailabilitySetName string
@description('Location of the resources')
param location string = resourceGroup().location
@description('Name of the virtual machine')
param virtualMachineName string
@description('Object containing the network interface settings')
param networkInterfaceObject networkInterfaceType
@description('Resource ID of the virtual machine image')
param virtualMachineImageResourceId string?
@description('Publisher of the virtual machine image')
param virtualMachineImagePublisher string?
@description('Offer of the virtual machine image')
param virtualMachineImageOffer string?
@description('Sku of the virtual machine image')
param virtualMachineImageSku string?
@description('Version of the virtual machine image')
param virtualMachineImageVersion string?
@description('Size of the virtual machine')
param virtualMachineSize string
@description('Type of storage account to use for the OS disk')
param storageType (
  | 'Standard_LRS'
  | 'Premium_LRS'
  | 'StandardSSD_LRS'
  | 'UltraSSD_LRS'
  | 'Premium_ZRS'
  | 'StandardSSD_ZRS') = 'Standard_LRS'
@description('Size of the OS disk in GB')
param osDiskSize int = 128
@description('Name of the OS disk')
param osDiskName string
@description('Name of the admin user')
param adminUserName string = 'sysadmin'
@description('Password of the admin user')
@secure()
param adminPassword string
@description('Name of the host pool')
param hostPoolName string
@description('URL of the host pool token')
@secure()
param hostPoolToken string
@description('Name of the domain join identity')
param domainJoinIdentityUserName string
@description('Password of the domain join identity')
@secure()
param domainJoinIdentityPassword string
@description('Fully qualified domain name of the domain to join')
param domainFqdn string
@description('Organizational Unit path to join the domain')
param ouPath string = ''
@description('Time zone of the virtual machine')
param timeZone string = ''
@description('License type of the virtual machine')
param licenseType ('None' | 'Windows_Client' | 'Windows_Server' | 'RHEL_BYOS' | 'SLES_BYOS') = 'None'
@description('Flag to enable ephemeral OS disk')
param ephemeralOsDisk bool = false
@description('Flag to enable encryption at host')
param encryptionAtHostEnabled bool = false
param tagObject object?

resource virtualNetworkExisting 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: networkInterfaceObject.virtualNetworkName
  scope: resourceGroup(
    networkInterfaceObject.?virtualNetworkSubscriptionId ?? subscription().subscriptionId,
    networkInterfaceObject.?virtualNetworkResourceGroupName ?? resourceGroup().name
  )
}
resource subnetExisting 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: networkInterfaceObject.subnetName
  parent: virtualNetworkExisting
}

module networkInterface '../resources/network/network-interface/main.bicep' = {
  name: 'AVD-NIC-${networkInterfaceObject.name}'
  params: {
    resourceName: networkInterfaceObject.name
    tagObject: networkInterfaceObject.?tagObject
    location: location
    subnetResourceId: subnetExisting.id
  }
}

module virtualMachine '../resources/compute/virtual-machine/main.bicep' = {
  name: 'AVD-VM-${virtualMachineName}'
  dependsOn: [
    networkInterface
  ]
  params: {
    resourceName: virtualMachineName
    location: location
    size: virtualMachineSize
    adminUserName: adminUserName
    adminPassword: adminPassword
    imageResourceId: virtualMachineImageResourceId
    imagePublisher: virtualMachineImagePublisher
    imageOffer: virtualMachineImageOffer
    imageSku: virtualMachineImageSku
    imageVersion: virtualMachineImageVersion
    storageAccountType: storageType
    osDiskGBSize: osDiskSize
    osDiskName: osDiskName
    availabilitySetName: linkedAvailabilitySetName
    encryptionAtHostEnabled: encryptionAtHostEnabled
    networkInterfaceObjectList: [
      {
        name: networkInterfaceObject.name
        primary: true
      }
    ]
    tagObject: tagObject
    timeZone: !empty(timeZone) ? timeZone : ''
    licenseType: licenseType
    ephemeralOSDisk: ephemeralOsDisk
  }
}

module omsExtension '../resources/compute/microsoft-monitoring-agent/main.bicep' = if (existingLogAnalyticsWorkspaceObject != null) {
  name: 'AVD-OMSExtension-${virtualMachineName}'
  dependsOn: [
    virtualMachine
  ]
  params: {
    location: location
    virtualMachineName: virtualMachineName
    logAnalyticsWorkspaceName: existingLogAnalyticsWorkspaceObject!.name
    logAnalyticsWorkspaceResourceGroup: existingLogAnalyticsWorkspaceObject!.?resourceGroupName
    logAnalyticsWorkspaceSubscriptionId: existingLogAnalyticsWorkspaceObject!.?subscriptionId
  }
}

module domainJoin '../resources/compute/domain-join/main.bicep' = {
  name: 'AVD-SessionDomainJoin-${virtualMachineName}'
  dependsOn: [
    virtualMachine
  ]
  params: {
    virtualMachineName: virtualMachineName
    location: location
    domainJoinUserName: domainJoinIdentityUserName
    domainJoinUserPassword: domainJoinIdentityPassword
    domainFQDN: domainFqdn
    ouPath: ouPath
  }
}

module dscExtension '../resources/desktop-virtualization/avd-dsc-extension/main.bicep' = {
  name: 'AVD-SessionHostDscExtension-${virtualMachineName}'
  dependsOn: [
    virtualMachine
    domainJoin
  ]
  params: {
    extensionName: 'AVDSessionHostRegistration'
    location: location
    vmNameArray: [
      virtualMachineName
    ]
    modulesUrl: '${sessionHostRegistrationModuleUrl}${sessionHostRegistrationModuleSasToken}'
    hostPoolName: hostPoolName
    hostPoolToken: hostPoolToken
  }
}
