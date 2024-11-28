targetScope = 'subscription'

metadata name = 'iac-bicep-component-avd'
metadata description = 'Solution that deploys the avd.'
metadata version = '1.0.2-rc.1'

import { domainJoinIdentityType, hostPoolType, scalePlanType, existingLogAnalyticsWorkspaceType } from './modules/orchestrators/types.bicep'
import { networkAclsType } from './modules/resources/storage/storage-account/main.bicep'
import { privateLinkServiceConnectionType } from './modules/resources/network/private-endpoint/main.bicep'

@description('URI for the Session Host registration Zip package required for onboarding AVD session hosts using Desired State Configuration.')
param sessionHostRegistrationModuleUrl string
@description('SAS token to the Location. This is a secure value. On commandline deployments you can add this manually but do not commit this to Git. Through Azure Pipelines we use a secure variable group injection to protect the value in a Git scenario.')
param sessionHostRegistrationModuleSasToken string
@description('PW for the local admin when the avd VMs are created.This is a secure value. On commandline deployments you can add this manually but do not commit this to Git. Through Azure Pipelines we use a secure variable group injection to protect the value in a Git scenario')
@secure()
param sessionHostPassword string
@description('Object describing an existing Log Analytics Workspace. If provided, the host pool will be configured to send diagnostic data to this workspace. If not provided, diagnostic data will not be sent to a Log Analytics Workspace.')
param existingLogAnalyticsWorkspaceObject existingLogAnalyticsWorkspaceType?
@description('General location of the deployment')
param location string
@description('The avd Bicep resources have their own resource parameter as not all Azure regions are available for the creation of these resources.')
param avdResourceLocation string
@description('Domain to join')
param domainFqdn string
@description('If needed, you can add a OUPath. The avd VMs will be created in that OU')
param ouPath string?
@description('A secure object for providing the details of the identity that will perform the domain join on the provided DomainFQDN')
param domainJoinIdentityObject domainJoinIdentityType
@description('WorkspaceObject that contains multiple properties/arrays')
param workspaceObject workspaceType
@description('ResourceGroupObjectList contains multiple ResourceGroupObjects with multiple properties/arrays')
param resourceGroupObjectList resourceGroupType[]
@description('HostPoolObjectList contains multiple HostpoolObjects with multiple properties/arrays.')
param hostPoolObjectList hostPoolType[]
@description('ScalePlanObjectList contains multiple ScalePlanObject with multiple properties/arrays.')
param scalePlanObjectList scalePlanType[]?
@description('contains multiple properties: It will create the storage account and the fileshare in it.')
param fileShareObject fileShareType?

type resourceGroupType = {
  @description('Name of the resource group.')
  name: string
  @description('Tags added to the resource')
  tagObject: object?
}

type fileShareType = {
  @description('name of the storage account')
  storageAccountName: string
  @description('Tags added to the resource')
  tagObject: object?
  @description('kind of storage account')
  kind: ('Storage' | 'StorageV2' | 'BlobStorage' | 'BlockBlobStorage' | 'FileStorage')
  @description('access tier of the storage account')
  accessTierStorageAccount: ('Hot' | 'Cool')?
  @description('Sku of the storage account')
  storageSku: (
    | 'Standard_LRS'
    | 'Standard_GRS'
    | 'Standard_ZRS'
    | 'Standard_RAGRS'
    | 'Standard_GZRS'
    | 'Premium_LRS'
    | 'Premium_ZRS'
    | 'Standard_RAGZRS')?
  @description('name of the file share')
  fileShareName: string
  @description('share quota in ShareQuotaGB')
  shareQuota: int?
  @description('name of the resoucegroup for the storage account')
  referencedResourceGroupName: string
  @description('access tier of the file shared')
  accessTierFileShare: ('TransactionOptimized' | 'Hot' | 'Cool' | 'Premium')?
  @description('NetworkAclsObject, used to set the networking access to the storage account.')
  networkAclsObject: networkAclsType?
  @description('Contains multiple properties: will link the storage account to an existing private dns zone')
  privateEndpointObject: privateEndpointType
}

type privateEndpointType = {
  @description('The id of the subscription of the virtual network of the VMs')
  virtualNetworkSubscriptionId: string?
  @description('Tags added to the resource')
  tagObject: object?
  @description('The name of the resource group of the virtual network of the VMs')
  virtualNetworkResourceGroupName: string?
  @description('The name of the virtual network of the VMs')
  virtualNetworkName: string
  @description('The name of the subnet of the VMs')
  subnetName: string
  @description('The name of the private endpoint')
  privateEndpointName: string
  @description('The name of the private dns zone that the storage account will be linked to')
  privateDnsZoneName: string
  @description('The id of the subscription of the private dns zone that the storage account will be linked to')
  privateDnsZoneSubscriptionId: string?
  @description('The name of the resource group of the private dns zone that the storage account will be linked to')
  privateDnsZoneResourceGroupName: string?
}

type workspaceType = {
  @description('Name of the workspace within avd')
  name: string
  @description('Tags added to the resource')
  tagObject: object?
  @description('Displayname of the workspace within avd')
  displayName: string
  @description('Description of the workspace within avd')
  description: string
  @description('Name of the ResourceGroup where you want to create the Workspace. This needs to be the same name as in ResourceGroupObjectList. It can be the same as a hostpool RG.')
  referencedResourceGroupName: string
}

resource resourceGroups 'Microsoft.Resources/resourceGroups@2019-10-01' = [
  for resourceGroupObject in resourceGroupObjectList: {
    name: resourceGroupObject.name
    location: location
    tags: resourceGroupObject.?tagObject
  }
]

module storageAccount './modules/resources/storage/storage-account/main.bicep' =
  if (fileShareObject != null) {
    scope: resourceGroup(fileShareObject!.referencedResourceGroupName)
    name: take('AVD-SA-${fileShareObject!.referencedResourceGroupName}', 64)
    dependsOn: [
      resourceGroups
    ]
    params: {
      location: location
      tagObject: fileShareObject!.?tagObject
      resourceName: fileShareObject!.storageAccountName
      kind: fileShareObject!.?kind
      accessTier: fileShareObject!.?accessTierStorageAccount
      storageSku: fileShareObject!.?storageSku
    }
  }
module fileShare './modules/resources/storage/storage-account-file-share/main.bicep' =
  if (fileShareObject != null) {
    scope: resourceGroup(fileShareObject!.referencedResourceGroupName)
    name: take('AVD-FileShare-${fileShareObject!.referencedResourceGroupName}', 64)
    dependsOn: [
      resourceGroups
      storageAccount
    ]
    params: {
      resourceName: fileShareObject!.fileShareName
      accessTier: fileShareObject.?accessTierFileShare
      shareQuotaGB: fileShareObject!.shareQuota
      storageAccountName: fileShareObject!.storageAccountName
    }
  }

module privateEndpointStorageAccount 'modules/resources/network/private-endpoint/main.bicep' =
  if (fileShareObject != null) {
    scope: resourceGroup(fileShareObject!.referencedResourceGroupName)
    name: take('AVD-PE-${fileShareObject!.privateEndpointObject.privateEndpointName}', 64)
    dependsOn: [
      resourceGroups
      storageAccount
      fileShare
    ]
    params: {
      location: location
      tagObject: fileShareObject!.privateEndpointObject.?tagObject
      privateLinkServiceConnectionObjectList: [
        {
          name: fileShareObject!.privateEndpointObject.privateEndpointName
          privateLinkServiceId: storageAccount.outputs.resourceId
          groupIdList: [
            'File'
          ]
        }
      ]
      resourceName: fileShareObject!.privateEndpointObject.privateEndpointName
      subnetName: fileShareObject!.privateEndpointObject.subnetName
      virtualNetworkName: fileShareObject!.privateEndpointObject.virtualNetworkName
      virtualNetworkResourceGroupName: fileShareObject!.privateEndpointObject.?virtualNetworkResourceGroupName
      virtualNetworkSubscriptionId: fileShareObject!.privateEndpointObject.?virtualNetworkSubscriptionId
    }
  }
module storageAccountPrivateDnsZoneGroup './modules/resources/network/private-dns-zone-group/main.bicep' =
  if (fileShareObject != null) {
    name: take('AVD-PrivDnsZoneGroup-${fileShareObject!.storageAccountName}', 64)
    scope: resourceGroup(fileShareObject!.referencedResourceGroupName)
    dependsOn: [
      storageAccount
      privateEndpointStorageAccount
    ]
    params: {
      resourceName: fileShareObject!.privateEndpointObject.privateEndpointName
      privateEndpointName: fileShareObject!.privateEndpointObject.privateEndpointName
      privateDnsZoneObjectList: [
        {
          name: fileShareObject!.privateEndpointObject.privateDnsZoneName
          resourceId: resourceId(
            fileShareObject!.privateEndpointObject.?privateDnsZoneSubscriptionId ?? subscription().subscriptionId,
            fileShareObject!.privateEndpointObject.?privateDnsZoneResourceGroupName ?? fileShareObject!.referencedResourceGroupName,
            'Microsoft.Network/privateDnsZones',
            fileShareObject!.privateEndpointObject.privateDnsZoneName
          )
        }
      ]
    }
  }

module hostPoolComponent 'modules/orchestrators/orchestratorHostPoolComponent.bicep' = [
  for hostPoolObject in hostPoolObjectList: {
    scope: resourceGroup(hostPoolObject.referencedResourceGroupName)
    name: take('AVD-HostPool-${hostPoolObject.name}-Orchestrator', 64)
    dependsOn: [
      resourceGroups
    ]
    params: {
      sessionHostRegistrationModuleUrl: sessionHostRegistrationModuleUrl
      sessionHostRegistrationModuleSasToken: sessionHostRegistrationModuleSasToken
      location: location
      avdResourceLocation: avdResourceLocation
      hostPoolObject: hostPoolObject
      sessionHostPassword: sessionHostPassword
      domainFqdn: domainFqdn
      ouPath: ouPath
      existingLogAnalyticsWorkspaceObject: existingLogAnalyticsWorkspaceObject
      domainJoinIdentityObject: domainJoinIdentityObject
    }
  }
]

module workspace './modules/resources/desktop-virtualization/workspace/main.bicep' = {
  scope: resourceGroup(workspaceObject.referencedResourceGroupName)
  name: take('AVD-Workspace-${workspaceObject.name}', 64)
  dependsOn: [
    resourceGroups
    hostPoolComponent
  ]
  params: {
    resourceName: workspaceObject.name
    location: avdResourceLocation
    tagObject: workspaceObject.?tagObject
    friendlyName: workspaceObject.displayName
    workspaceDescription: workspaceObject.description
    applicationGroupReferencesObjectList: flatten(map(
      hostPoolObjectList,
      hostpoolObject =>
        map(
          hostpoolObject.applicationGroupObjectList,
          applictionGroupObject => {
            name: applictionGroupObject.name
            resourceGroupName: hostpoolObject.referencedResourceGroupName
          }
        )
    ))
  }
}
module workspaceDiagnostics './modules/resources/insights/avd-workspace-diagnostic-settings/main.bicep' =
  if (existingLogAnalyticsWorkspaceObject != null) {
    scope: resourceGroup(workspaceObject.referencedResourceGroupName)
    name: take('AVD-Workspace-DiagnosticSettings-${workspaceObject.name}', 64)
    dependsOn: [
      workspace
    ]
    params: {
      workspaceName: workspaceObject.name
      logAnalyticsWorkspaceName: existingLogAnalyticsWorkspaceObject!.name
      logAnalyticsWorkspaceResourceGroup: existingLogAnalyticsWorkspaceObject!.?resourceGroupName
      logAnalyticsWorkspaceSubscriptionId: existingLogAnalyticsWorkspaceObject!.?subscriptionId
    }
  }

module scalingPlanRoleDefinition './modules/resources/desktop-virtualization/scaling-plan-role-definition/main.bicep' =
  if (scalePlanObjectList != null) {
    name: 'AVD-ScalePlan-RoleDefinition'
  }

module scalingPlanComponent 'modules/orchestrators/orchestratorScalingPlanComponent.bicep' = [
  for scalePlanObject in scalePlanObjectList! ?? []: {
    scope: resourceGroup(scalePlanObject.referencedResourceGroupName)
    name: take('AVD-ScalePlan-${scalePlanObject.name}-Orchestrator', 64)
    dependsOn: [
      resourceGroups
      hostPoolComponent
      workspace
      scalingPlanRoleDefinition
    ]
    params: {
      location: avdResourceLocation
      scalePlanObject: scalePlanObject
      principalId: scalePlanObject.azureVirtualDesktopApplicationObjectId
      roleDefinitionName: scalingPlanRoleDefinition.outputs.resourceName
      roleAssignmentName: 'Azure Virtual Desktop - AutoScale'
      roleAssignmentDescription: 'This role assignment allows the Azure Virtual Desktop service to perform auto-scaling operations on the Azure Virtual Desktop host pools.'
    }
  }
]
