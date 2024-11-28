param resourceName string
param location string

param kind ('Storage' | 'StorageV2' | 'BlobStorage' | 'BlockBlobStorage' | 'FileStorage') = 'StorageV2'

param accessTier ('Hot' | 'Cool') = 'Hot'

param storageSku (
  | 'Standard_LRS'
  | 'Standard_GRS'
  | 'Standard_ZRS'
  | 'Standard_RAGRS'
  | 'Standard_GZRS'
  | 'Premium_LRS'
  | 'Premium_ZRS'
  | 'Standard_RAGZRS') = 'Standard_LRS'
param allowBlobPublicAccess bool = false

@description('The Data Lake Storage Gen2 hierarchical namespace accelerates big data analytics workloads and enables file-level access control lists (ACLs). Enabling this parameter will deploy the storage account as a data lake.')
param enableHierachicalNamespace bool = false

@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

@description('NetworkAclsObject, used to set the networking access to the storage account.')
param networkAclsObject networkAclsType?
param sftpEnabled bool = false
param localUserEnabled bool = false

@export()
type networkAclsType = {
  @description('Exceptions that can use the storage account')
  bypass: 'AzureServices' | 'Logging' | 'Metrics' | 'None'
  @description('Action of the acls object')
  defaultAction: 'Allow' | 'Deny'
  @description('ip\'s that can use the storage account')
  ipRules: ipRuleType[]
  @description('vnets that can use the storage account')
  virtualNetworkRules: virtualNetworkType[]
}
type ipRuleType = {
  @description('Specifies the IP or IP range in CIDR format. Only IPV4 address is allowed.')
  value: string
  action: 'Allow'
}
type virtualNetworkType = {
  @description('Resource ID of a subnet')
  id: string
  action: 'Allow'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: resourceName
  location: location
  tags: tagObject
  kind: kind
  sku: {
    name: storageSku
  }
  properties: {
    accessTier: accessTier
    isHnsEnabled: enableHierachicalNamespace
    allowBlobPublicAccess: allowBlobPublicAccess
    networkAcls: networkAclsObject
    isSftpEnabled: sftpEnabled
    isLocalUserEnabled: localUserEnabled
  }
}

output resourceName string = storageAccount.name
output resourceId string = storageAccount.id
