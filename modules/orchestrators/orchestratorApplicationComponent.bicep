import { applicationType } from 'types.bicep'

@description('Object containing the application information')
param applicationObjectList applicationType[]
@description('The name of the application group where the application needs to be created')
param applicationGroupName string

module application '../resources/desktop-virtualization/application/main.bicep' = [
  for applicationObject in applicationObjectList: {
    name: uniqueString(applicationObject.applicationName)
    params: {
      applicationGroupName: applicationGroupName
      applicationDescription: applicationObject.?applicationDescription
      friendlyName: applicationObject.?friendlyName
      applicationName: applicationObject.applicationName
      filePath: applicationObject.filePath
      iconPath: applicationObject.iconPath
      iconIndex: applicationObject.?iconIndex
      commandlineArgument: applicationObject.?commandlineArgument ?? null
      commandLineSetting: applicationObject.?commandlineArgument != null ? 'Require' : 'DoNotAllow'
      showInPortal: applicationObject.?showInPortal
    }
  }
]
