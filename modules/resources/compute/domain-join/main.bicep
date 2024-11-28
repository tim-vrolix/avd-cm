@description('The name of the virtual machine to be domain joined.')
param virtualMachineName string

@description('Location name of the virtual machine')
param location string = resourceGroup().location

@description('Domain NetBiosName plus User name of a domain user with sufficient rights to perfom domain join operation. E.g. domain\\username')
param domainJoinUserName string

@description('Domain user password for joining to the domain.')
@secure()
param domainJoinUserPassword string

@description('Domain FQDN where the virtual machine will be joined')
param domainFQDN string

@description('Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: "OU=testOU; DC=domain; DC=Domain; DC=com"')
param ouPath string?
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?
var domainJoinOptions = 3

resource virtualMachineExisting 'Microsoft.Compute/virtualMachines@2022-08-01' existing = {
  name: virtualMachineName
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'JoinDomain'
  parent: virtualMachineExisting
  location: location
  tags: tagObject
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainFQDN
      OUPath: ouPath
      User: '${domainFQDN}\\${domainJoinUserName}'
      Options: domainJoinOptions
      Restart: 'true'
    }
    protectedSettings: {
      Password: domainJoinUserPassword
    }
  }
}

output resourceName string = extension.name
output resourceId string = extension.id
