using './main.bicep'

param location = 'westeurope'
param sessionHostRegistrationModuleUrl = 'https://iotemplatelibraryprd01.blob.core.windows.net/templates/resources/desktopvirtualization/2021-08-10/AVDSessionHostRegistration.zip'
param sessionHostRegistrationModuleSasToken = '{{sessionHostRegistrationModuleSasToken}}'
param avdResourceLocation = 'westeurope'
param domainFqdn = 'cmavdpoc.local'
param sessionHostPassword = '{{sessionHostPassword}}'
param existingLogAnalyticsWorkspaceObject = {
  name: 'cm-la-poc-01'
  resourceGroupName: 'cm-rgp-poc-avd-workspace-01'
}

param resourceGroupObjectList = [
  {
    name: 'cm-rgp-poc-avd-workspace-01'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
  }
  {
    name: 'cm-rgp-poc-avd-hostpool-01'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
  }
  {
    name: 'cm-rgp-poc-avd-hostpool-0102'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
  }
]

param domainJoinIdentityObject = {
  userName: 'sys-wvdadmin@cmavdpoc.onmicrosoft.com'
  password: '{{domainJoinIdentityPassword}}'
}

param workspaceObject = {
  name: 'cm-avd-avdworkspace-poc-01'
  displayName: 'poc avd workspace'
  description: 'avd workspace deployed by DexBrix Bicep solution.'
  referencedResourceGroupName: 'cm-rgp-poc-avd-workspace-01'
  tagObject: {
    environment: 'poc'
    project: 'avd'
  }
}

param fileShareObject = {
  storageAccountName: 'cmstadinfravd01'
  tagObject: {
    environment: 'poc'
    project: 'avd'
  }
  kind: 'FileStorage'
  accessTierStorageAccount: 'Hot'
  storageSku: 'Premium_LRS'
  fileShareName: 'profiles'
  accessTierFileShare: 'Premium'
  shareQuota: 100
  referencedResourceGroupName: 'cm-rgp-poc-avd-workspace-01'
  networkAclsObject: {
    bypass: 'None'
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
  }
  privateEndpointObject: {
    privateDnsZoneName: 'privatelink.file.core.windows.net'
    privateDnsZoneResourceGroupName: 'cm-rgp-aadds-01'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
    privateEndpointName: 'pe-cm-poc-avd-01'
    subnetName: 'cm-snet-privateendpoints-01'
    virtualNetworkName: 'vnet-sharedservices-prod-gwc-001'
    virtualNetworkResourceGroupName: 'sn-avd'
  }
}

param hostPoolObjectList = [
  {
    name: 'cm-avd-hostpool-poc-W10'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
    applicationGroupObjectList: [
      {
        name: 'cm-avd-appgroup-desktop-poc-01'
        tagObject: {
          environment: 'poc'
          project: 'avd'
        }
        description: 'Desktop application group deployed by DexBrix Bicep solution.'
        displayname: 'Development desktop application'
        applicationDisplayName: 'Desktop 01'
        type: 'Desktop'
        assignmentList: [
          '2d238479-80c9-4889-9d35-736531918a6f' // Jan De Laet
          '202e2da5-8aae-4c07-8045-11ab90f03e4b' // Arne Steinbach
        ]
      }
    ]
    availabilitySetObject: {
      name: 'cm-avd-avs-poc-01'
      tagObject: {
        environment: 'poc'
        project: 'avd'
      }
    }
    description: 'Hostpool deployed by DexBrix Bicep solution.'
    displayName: 'Development hostpool 1'
    loadBalancerType: 'BreadthFirst'
    maxSessionLimit: 15
    referencedResourceGroupName: 'cm-rgp-poc-avd-hostpool-01'
    sessionHostsObject: {
      sessionHostImageOffer: 'windows-10'
      sessionHostImagePublisher: 'MicrosoftWindowsDesktop'
      sessionHostImageSku: 'win10-23h2-avd'
      sessionHostImageVersion: 'latest'
      sessionHostAdminUserName: 'sysadmin'
      sessionHostObjectList: [
        {
          networkInterfaceObject: {
            name: 'cm-avd-nic-poc-01-cmvmpocvd0118'
            subnetName: 'default'
            virtualNetworkName: 'vnet-sharedservices-prod-gwc-001'
            virtualNetworkResourceGroupName: 'sn-avd'
            tagObject: {
            environment: 'poc'
            project: 'avd'
          }
          }
          virtualMachineName: 'cmvmpocvd0118'
          virtualMachineSize: 'Standard_B2s_v2'
          timeZone: 'Romance Standard Time'
          tagObject: {
            environment: 'poc'
            project: 'avd'
          }
        }
      ]
      sessionHostOSDiskSize: 128
    }
  }
  {
    name: 'cm-avd-hostpool-poc-W11'
    applicationGroupObjectList: [
      {
        name: 'cm-avd-appgroup-desktop-poc-0102'
        tagObject: {
          environment: 'poc'
          project: 'avd'
        }
        description: 'Desktop application group deployed by DexBrix Bicep solution.'
        displayname: 'Development desktop application'
        applicationDisplayName: 'Desktop 0102'
        type: 'Desktop'
        assignmentList: [
          '2d238479-80c9-4889-9d35-736531918a6f' // Jan De Laet
          '202e2da5-8aae-4c07-8045-11ab90f03e4b' // Arne Steinbach
        ]
      }
    ]
    availabilitySetObject: {
      name: 'cm-avd-avs-poc-01'
      tagObject: {
        environment: 'poc'
        project: 'avd'
      }
    }
    description: 'Hostpool deployed by DexBrix Bicep solution.'
    displayName: 'Development hostpool 1'
    loadBalancerType: 'BreadthFirst'
    maxSessionLimit: 15
    referencedResourceGroupName: 'cm-rgp-poc-avd-hostpool-0102'
    sessionHostsObject: {
      sessionHostImageOffer: 'windows-11'
      sessionHostImagePublisher: 'MicrosoftWindowsDesktop'
      sessionHostImageSku: 'win11-23h2-avd'
      sessionHostImageVersion: 'latest'
      sessionHostAdminUserName: 'sysadmin'
      sessionHostObjectList: [
        {
          networkInterfaceObject: {
            name: 'cm-avd-nic-poc-01-cmvmpocvd010218'
            subnetName: 'sn-avd'
            virtualNetworkName: 'vnet-sharedservices-prod-gwc-001'
            virtualNetworkResourceGroupName: 'rg-arne-aadds-01'
            tagObject: {
            environment: 'poc'
            project: 'avd'
          }
          }
          virtualMachineName: 'cmvmpocvd010218'
          virtualMachineSize: 'Standard_B2s_v2'
          timeZone: 'Romance Standard Time'
          tagObject: {
            environment: 'poc'
            project: 'avd'
          }
        }
      ]
      sessionHostOSDiskSize: 128
    }
  }
]

param scalePlanObjectList = [
  {
    name: 'scalingweekday'
    tagObject: {
      environment: 'poc'
      project: 'avd'
    }
    azureVirtualDesktopApplicationObjectId: 'd5bba8d0-ecef-4f65-b721-a694154c6516'
    description: 'scaleplan for hostpool 01 poc'
    friendlyName: 'scaleplan for hostpool 01 poc'
    referencedResourceGroupName: 'cm-rgp-poc-avd-hostpool-01'
    scheduleObjectList: [
      {
        name: 'weekdays_schedule'
        daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
        offPeakStartTime: {
          hour: 20
          minute: 0
        }
        peakLoadBalancingAlgorithm: 'DepthFirst'
        peakStartTime: {
          hour: 9
          minute: 0
        }
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: true
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 90
        rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
        rampDownStartTime: {
          hour: 18
          minute: 0
        }
        rampDownStopHostsWhen: 'ZeroSessions'
        rampDownWaitTimeMinutes: 30
        rampUpCapacityThresholdPct: 60
        rampUpLoadBalancingAlgorithm: 'BreadthFirst'
        rampUpMinimumHostsPct: 20
        rampUpStartTime: {
          hour: 8
          minute: 0
        }
      }
    ]
    timeZone: 'Romance Standard Time'
    hostPoolReferenceObjectList: [
      {
        name: 'cm-avd-hostpool-poc-01'
        resourceGroupName: 'cm-rgp-poc-avd-hostpool-01'
        scalingEnabled: true
      }
    ]
  }
]
