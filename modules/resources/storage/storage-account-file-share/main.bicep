@description('Specifies the name of the File Share. File share names must be between 3 and 63 characters in length and use numbers, lower-case letters and dash (-) only.')
@minLength(3)
@maxLength(63)
param resourceName string

@description('Specifies the name of the Azure Storage account.')
param storageAccountName string

param accessTier ('TransactionOptimized' | 'Hot' | 'Cool' | 'Premium') = 'TransactionOptimized'

@minValue(1)
@maxValue(5120)
param shareQuotaGB int = 5120

resource storageAccountExisting 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource storageAccountFileServiceExisting 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  parent: storageAccountExisting
  name: 'default'
}

resource storageAccountFileServiceShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  parent: storageAccountFileServiceExisting
  name: resourceName
  properties: {
    accessTier: accessTier
    shareQuota: shareQuotaGB
  }
}

output resourceName string = storageAccountFileServiceShare.name
output resourceId string = storageAccountFileServiceShare.id
