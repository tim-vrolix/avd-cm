targetScope = 'subscription'

var roleName = 'Azure Virtual Desktop - AutoScale'

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid(roleName)
  properties: {
    roleName: roleName
    description: 'Role for allowing The Azure Virtual Desktop service to perform auto-scale operations on the Azure Virtual Desktop host pools.'
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}'
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Insights/eventtypes/values/read'
          'Microsoft.Compute/virtualMachines/deallocate/action'
          'Microsoft.Compute/virtualMachines/restart/action'
          'Microsoft.Compute/virtualMachines/powerOff/action'
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.DesktopVirtualization/hostpools/read'
          'Microsoft.DesktopVirtualization/hostpools/write'
          'Microsoft.DesktopVirtualization/hostpools/sessionhosts/read'
          'Microsoft.DesktopVirtualization/hostpools/sessionhosts/write'
          'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete'
          'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read'
          'Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

output resourceName string = roleDefinition.name
output resourceId string = roleDefinition.id
output roleDefinitionId string = roleDefinition.id
