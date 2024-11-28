import { scheduleType, hostPoolReferenceType } from '../resources/desktop-virtualization/scaling-plan/main.bicep'

@export()
type applicationType = {
  @description('the name of the application')
  applicationName: string
  @description('the description of the application')
  applicationDescription: string?
  @description('the friendly name of the application')
  friendlyName: string?
  @description('the full path of the application')
  filePath: string
  @description('the full path of the icon of the application')
  iconPath: string
  @description('The icon index for the application.')
  iconIndex: int?
  @description('Command Line Arguments for Application.')
  commandlineArgument: string?
  @description('Specifies whether or not the application will be shown in the Avd portal.')
  showInPortal: bool?
}

@export()
type existingLogAnalyticsWorkspaceType = {
  @description('The subscription ID of the shared log analytics workspace instance to log to')
  subscriptionId: string?
  @description('The resource group of the shared log analytics workspace instance to log to')
  resourceGroupName: string?
  @description('The name of the shared log analytics workspace instance to log to')
  name: string
}

@export()
type scalePlanType = {
  @description('The name of the scaling plan')
  name: string
  @description('Tags added to the resource.')
  tagObject: object?
  @description('The description of the scaling plan.')
  description: string?
  @description('Name of the ResourceGroup where you want to create the scaling plan, this needs to be the same name as in ResourceGroupObjectList. It can be the same as the workspace RG or hostpool RG.')
  referencedResourceGroupName: string
  @description('The friendly name of the scaling plan')
  friendlyName: string?
  @description('Timezone of the scaling plan')
  timeZone: string
  @description('contains multiple SchedulesObjectList with multiple properties/arrays.')
  scheduleObjectList: scheduleType[]
  @description('contains multiple HostpoolReferencesObject with multiple properties/arrays')
  hostPoolReferenceObjectList: hostPoolReferenceType[]?
  @description('The name of the tag associated with the VMs that will be excluded from the Scaling plan.')
  exclusionTag: string?
  @description('Application Id will always be "9cdead84-a844-4324-93f2-b2e6bb768d07" in every tenant, but Object Id will be different. Could include a pipeline pre-step which fetches this value automatically. This would require the Service Connection that is fetching this information to have the Directory Reader role in the Azure AD tenant. To manually retrieve the objectId run "az ad sp show --id 9cdead84-a844-4324-93f2-b2e6bb768d07 --query id"')
  azureVirtualDesktopApplicationObjectId: string
}

@export()
type hostPoolType = {
  @description('Name of the Hostpool')
  name: string
  @description('Tags added to the resource.')
  tagObject: object?
  @description('Displayname of the hostpool')
  displayName: string
  @description('Description of the hostpool')
  description: string
  @description('Maximum of connections to the VMs in that hostpool')
  maxSessionLimit: int
  @description('Type of Loadbalancer.')
  loadBalancerType: ('BreadthFirst' | 'DepthFirst')
  @description('Name of the ResourceGroup where you want to create the hostpool.This needs to be the same name as in ResourceGroupObjectList. It can be the same as the workspace RG.')
  referencedResourceGroupName: string
  @description('contains multiple ApplicationGroupObjects with multiple properties/arrays.')
  applicationGroupObjectList: applicationGroupType[]
  @description('Name of the availability set')
  availabilitySetObject: availabilitySetType
  @description('contains settings of the sessionhosts')
  sessionHostsObject: sessionHostsType
  @description('Custom RDP properties for the hostpool.')
  customRdpProperty: string?
}

type availabilitySetType = {
  @description('Name of the availability set')
  name: string
  @description('Tags added to the resource.')
  tagObject: object?
}

type applicationGroupType = {
  @description('contains settings of an applicationGroup with multiple properties/arrays')
  name: string
  @description('Tags added to the resource.')
  tagObject: object?
  @description('Displayname of the applicationgroup')
  displayname: string?
  @description('Description of the applicationgroup')
  description: string
  @description('Type of the applicationgroup. 2 values are accepted: Desktop (only one) or RemoteApp')
  type: ('Desktop' | 'RemoteApp')
  @description('you can configure the desktop application name so that it is not the default SessionDesktop. Works only with Desktop type apps. This needs to be set through the API and PowerShell and is done in the deployment workflows.')
  applicationDisplayName: string?
  @description('Contains (multiple) ObjectID(s) of AAD users/groups to assign the AAD user/group to the corresponding ApplicationGroupObject. It needs to be the objectID of the AAD user/group (it cant be the userprincipalname).')
  assignmentList: string[]?
  @description('contains multiple applicationObjects with multiple properties. Is used to link installed applications on the image to the application group')
  applicationObjectList: applicationType[]?
}
type sessionHostsType = {
  @description('ResourceID of the shared image for all the VMs in the SessionHostObject. It can be overrided per VM by adding the property to the SessionHostObject in SessionHostList. It takes precedence over a marketplace image.')
  sessionHostImageResourceId: string?
  @description('The name of the image publisher if no imageresourceId is given.')
  sessionHostImagePublisher: string?
  @description('The name of the image offer if no imageresourceId is given.')
  sessionHostImageOffer: string?
  @description('The name of the image sku if no imageresourceId is given.')
  sessionHostImageSku: string?
  @description('The version of the image if no imageresourceId is given.')
  sessionHostImageVersion: string?
  @description('The version of the image if no imageresourceId is given.')
  virtualMachineImageVersion: string?
  @description('Admin account name of the VMs when created')
  sessionHostAdminUserName: string
  @description('OS Disksize of all the VMs. It can be overrided per VM by adding the property to the SessionHostObject in SessionHostList.')
  sessionHostOSDiskSize: int
  @description('Object that define the sessionhosts within the sessionHostsObject')
  sessionHostObjectList: sessionHostType[]
  @description('Sets the timezone of the VM. This will override the general TimeZone under SessionHostObject')
  timeZone: string?
  @description('License type of all the VMs. It can be overrided per VM by adding the property to the SessionHostObject in SessionHostList.')
  licenseType: ('Windows_Client' | 'Windows_Server' | 'RHEL_BYOS' | 'SLES_BYOS')?
  @description('Option to have EphemeralOSDisks for the whole SessionHostObject. Pay attention to the following: if used, storage type will be set to Standard_LRS. Its also not possible with all the VM sizes, by default you can choose the Standard_DS3_v2. For more information, visit https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks')
  ephemeralOSDisk: bool?
}

@export()
type sessionHostType = {
  @description('Name of the VM')
  virtualMachineName: string
  @description('Tags added to the resource.')
  tagObject: object?
  @description('The object for the network interface of the VMs')
  networkInterfaceObject: networkInterfaceType
  @description('ResourceID of the shared image for this VM. This will override the SessionHostImageResourceId. It takes precedence over a marketplace image.')
  virtualMachineImageResourceId: string?
  @description('The name of the image publisher if no imageresourceId is given.')
  virtualMachineImagePublisher: string?
  @description('The name of the image offer if no imageresourceId is given.')
  virtualMachineImageOffer: string?
  @description('The name of the image sku if no imageresourceId is given.')
  virtualMachineImageSku: string?
  @description('The version of the image if no imageresourceId is given.')
  virtualMachineImageVersion: string?
  @description('Size of the VM')
  virtualMachineSize: string
  @description('OS Disksize of the VM. This will override the SessionHostOSDiskSize')
  virtualMachineOSDiskSize: int?
  @description('Enable EncryptionAtHost on the VM. Default is false. The EncryptionAtHost feature needs to be enabled on the subscription.')
  encryptionAtHostEnabled: bool?
  @description('Sets the timezone of the VM. This will override the general TimeZone under SessionHostObject')
  timeZone: string?
  @description('License type of all the VMs. It can be overrided per VM by adding the property to the SessionHostObject in SessionHostList.')
  licenseType: ('Windows_Client' | 'Windows_Server' | 'RHEL_BYOS' | 'SLES_BYOS')?
}

@export()
type networkInterfaceType = {
  @description('Name of the networkinterface')
  name: string
  @description('Tags added to the resource.')
  tagObject: object?
  @description('The id of the subscription of the virtual network of the VMs')
  virtualNetworkSubscriptionId: string?
  @description('The name of the resource group of the virtual network of the VMs')
  virtualNetworkResourceGroupName: string?
  @description('The name of the virtual network of the VMs')
  virtualNetworkName: string
  @description('The name of the subnet of the VMs')
  subnetName: string
}

@export()
type domainJoinIdentityType = {
  @description('username of the admin account to join the VMs.')
  userName: string
  @description('password of the admin account to join the VMs. This is a secure value. On commandline deployments you can add this manually but do not commit this to Git. Through Azure Pipelines we use a secure variable group injection to protect the value in a Git scenario.')
  @secure()
  password: string
}
