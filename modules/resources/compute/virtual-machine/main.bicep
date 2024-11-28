@description('The name of the virtual machine.')
param resourceName string
@description('The location for the Azure resource.')
param location string
@description('The VM size.')
param size string
@description('Name of the default admin user.')
param adminUserName string

@secure()
@description('The password for the default admin user.')
param adminPassword string
@description('Any public keys to trust for SSH authentication. Only applicable for Linux VMs.')
param publicKeys array?
@description('The publisher of the virtual machine image.')
param imagePublisher string?
@description('The offer of the virtual machine image.')
param imageOffer string?
@description('The SKU of the virtual machine image.')
param imageSku string?
@description('The version of the virtual machine image.')
param imageVersion string = 'latest'
@description('A reference to the resource ID of a custom virtual machine image.')
param imageResourceId string?
@description('Specifies whether or not this virtual machine uses a marketplace image.')
param includePlan bool = false

@description('The type of storage for the virtual machine.')
param storageType ('UnManaged' | 'Managed') = 'Managed'

@description('The type of storage to use if a managed disk is used.')
param storageAccountType (
  | 'Standard_LRS'
  | 'Premium_LRS'
  | 'StandardSSD_LRS'
  | 'UltraSSD_LRS'
  | 'Premium_ZRS'
  | 'StandardSSD_ZRS') = 'StandardSSD_LRS'
param dataDiskGBSizes array = []
param dataDiskNames array = []
@description('The size in GB for the OS disk.')
param osDiskGBSize int
@description('The name of the OS disk.')
param osDiskName string
@description('The subscription id of an availibity set that can be provided if the virtual machine should be part of an availability set.')
param availabilitySetSubscriptionId string?
@description('The resource group name of an availibity set that can be provided if the virtual machine should be part of an availability set.')
param availabilitySetResourceGroup string?
@description('The name of an availibity set that can be provided if the virtual machine should be part of an availability set.')
param availabilitySetName string?
@description('A list of availability zones for the virtual machine.')
param availabilityZoneList array?
@description('The name of a storage account to use for storing the virtual machine data. Only applicable if unmanaged storage is used.')
param storageAccountName string?
@description('Custom network interface object list. Every object has one mandatory property: \'Name\'. And three optional properties: [\'Primary\' (bool), \'ResourceGroupName\', \'SubscriptionId\'].\n                The primary flag should only be set on one of the provided NIC\'s. The other two optional properties are for calculating the resource id of the provided NIC. If you do not provide these values, the automation will default to the current resource group and subscription.')
param networkInterfaceObjectList networkInterfaceType[]
@description('Does the virtual machine enables managed service identity or not.')
param enableMsi bool = false
@description('Optional name of an existing storage account if you want to enable boot diagnostics on the virtual machine.')
param bootDiagnosticsStorageAccountName string?
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?
@description('The timezone for the virtual machine\'s clock.')
param timeZone string?
@description('The license type to use for the virtual machine.')
param licenseType ('None' | 'Windows_Client' | 'Windows_Server' | 'RHEL_BYOS' | 'SLES_BYOS') = 'None'
@description('Make OS disk Ephemeral or not. Pay attention to the following: if used, storage type will be set to Standard_LRS. It\'s also not possible with all the VM sizes. For more information, visit https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks')
param ephemeralOSDisk bool = false
@description('Specifies a base-64 encoded string of custom data. The base-64 encoded string is decoded to a binary array that is saved as a file on the Virtual Machine. The maximum length of the binary array is 65535 bytes. Note: Do not pass any secrets or passwords in customData property This property cannot be updated after the VM is created.')
param customData string?
@description('Specifies whether or not encryption at host should be enabled for the virtual machine.')
param encryptionAtHostEnabled bool = false

@export()
type networkInterfaceType = {
  name: string
  @description('The resource group of the NIC.')
  resourceGroupName: string?
  @description('The subscription id of the NIC.')
  subscriptionId: string?
  @description('Wether this NIC is primary or not.')
  primary: bool?
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-03-01' existing = if (availabilitySetName != null) {
  name: availabilitySetName ?? 'placeholder'
  scope: resourceGroup(
    availabilitySetSubscriptionId ?? subscription().subscriptionId,
    availabilitySetResourceGroup ?? resourceGroup().name
  )
}

var availabilitySetProperty = {
  id: availabilitySet.id
}
var linuxConfigProperty = {
  ssh: {
    publicKeys: publicKeys
  }
}
var managedDiskProperty = {
  storageAccountType: storageAccountType
}
var vhdOsDiskProperty = {
  uri: 'http://${storageAccountName}.${environment().suffixes.storage}/${resourceName}/${resourceName}-osdisk.vhd'
}
var identityProperty = {
  type: 'SystemAssigned'
}
var timeZoneProperty = {
  timeZone: timeZone
}
var planProperty = {
  publisher: imagePublisher
  product: imageOffer
  name: imageSku
}
var imageReferenceWithManagedImage = {
  id: imageResourceId
}
var imageReferenceWithOffer = {
  publisher: imagePublisher
  offer: imageOffer
  sku: imageSku
  version: imageVersion
}
var diagnosticsProfileProperty = {
  bootDiagnostics: {
    enabled: true
    storageUri: 'https://${bootDiagnosticsStorageAccountName}.${environment().suffixes.storage}/'
  }
}
var diffDiskSettingsProperty = {
  option: 'Local'
}
var nicDetailsLoop = [
  for item in networkInterfaceObjectList: {
    Name: item.name
    ResourceGroupName: item.?resourceGroupName == null ? resourceGroup().name : item.resourceGroupName
    SubscriptionId: item.?subscriptionId == null ? subscription().subscriptionId : item.subscriptionId
    Primary: length(networkInterfaceObjectList) == 1 ? true : item.?primary ?? false
  }
]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: resourceName
  location: location
  zones: availabilityZoneList
  tags: tagObject
  identity: enableMsi ? identityProperty : null
  plan: includePlan == false ? null : planProperty
  properties: {
    availabilitySet: availabilitySetName == null ? null : availabilitySetProperty
    securityProfile: {
      encryptionAtHost: encryptionAtHostEnabled
    }
    hardwareProfile: {
      vmSize: size
    }
    osProfile: {
      computerName: resourceName
      adminUsername: adminUserName
      adminPassword: adminPassword
      linuxConfiguration: publicKeys == null ? null : linuxConfigProperty
      windowsConfiguration: timeZone == null ? null : timeZoneProperty
      customData: customData
    }
    storageProfile: {
      imageReference: imageResourceId == null ? imageReferenceWithOffer : imageReferenceWithManagedImage
      osDisk: {
        name: osDiskName
        managedDisk: storageType == 'Managed' ? managedDiskProperty : null
        vhd: storageType == 'UnManaged' ? vhdOsDiskProperty : null
        diskSizeGB: osDiskGBSize
        diffDiskSettings: ephemeralOSDisk ? diffDiskSettingsProperty : null
        caching: ephemeralOSDisk ? 'ReadOnly' : 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        for (item, i) in dataDiskGBSizes: {
          caching: 'ReadWrite'
          diskSizeGB: item
          lun: i
          name: dataDiskNames[i]
          vhd: storageType == 'Managed'
            ? null
            : {
                uri: 'http://${storageAccountName}.${environment().suffixes.storage}/${resourceName}/${resourceName}-datadisk${i}.vhd'
              }
          createOption: 'Empty'
          managedDisk: storageType == 'Managed' ? managedDiskProperty : null
        }
      ]
    }

    networkProfile: {
      networkInterfaces: [
        for (networkInterfaceObject, index) in networkInterfaceObjectList: {
          id: resourceId('Microsoft.Network/networkInterfaces', nicDetailsLoop[index].Name)
          properties: {
            primary: nicDetailsLoop[index].Primary
          }
        }
      ]
    }
    licenseType: licenseType
    diagnosticsProfile: bootDiagnosticsStorageAccountName == null ? null : diagnosticsProfileProperty
  }
}
output resourceName string = virtualMachine.name
output resourceId string = virtualMachine.id
