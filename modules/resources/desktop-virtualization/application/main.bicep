@description('The name of the application group in which the application will be created.')
param applicationGroupName string

@description('The name of the application which will be created.')
param applicationName string

@description('A description of the application which will be created.')
param applicationDescription string?

@description('The friendly name of the application which will be created.')
param friendlyName string?

@description('The file path of the application.')
param filePath string

@description('Command Line Arguments for Application.')
param commandlineArgument string?

@description('The command line setting of the application.')
param commandLineSetting ('DoNotAllow' | 'Allow' | 'Require') = 'DoNotAllow'

@description('The path to the icon file for the application.')
param iconPath string

@description('The icon index for the application.')
param iconIndex int = 0

@description('Specifies whether or not the application will be shown in the Avd portal.')
param showInPortal bool = true

resource applicationGroupExisting 'Microsoft.DesktopVirtualization/applicationGroups@2022-02-10-preview' existing = {
  name: applicationGroupName
}

resource applicationGroupApplication 'Microsoft.DesktopVirtualization/applicationgroups/applications@2019-12-10-preview' = {
  name: applicationName
  parent: applicationGroupExisting
  properties: {
    description: applicationDescription
    friendlyName: friendlyName
    filePath: filePath
    commandLineArguments: commandlineArgument
    commandLineSetting: commandLineSetting
    showInPortal: showInPortal
    iconPath: iconPath
    iconIndex: iconIndex
  }
}

output resourceId string = applicationGroupApplication.id
