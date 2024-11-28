@description('Location name of the virtual machine')
param location string = resourceGroup().location
param extensionName string = 'DscExtension'
param vmNameArray array
param modulesUrl string

@description('The name of the HostPool to be created in the RDS Tenant.')
param hostPoolName string

@description('The HostPool registration token to use to link the session hosts.')
param hostPoolToken string
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

resource extension 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [
  for virtualMachine in vmNameArray: {
    name: '${trim(virtualMachine)}/${extensionName}'
    location: location
    tags: tagObject
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.73'
      autoUpgradeMinorVersion: true
      settings: {
        modulesUrl: modulesUrl
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        properties: {
          HostpoolName: hostPoolName
          RegistrationInfoToken: hostPoolToken
        }
      }
    }
  }
]
