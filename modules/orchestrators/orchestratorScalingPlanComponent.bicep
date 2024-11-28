import { scalePlanType } from 'types.bicep'

@description('The location of the scaling plan')
param location string
@description('The scaling plan object')
param scalePlanObject scalePlanType
@description('The principal id of the user or group to assign the role to')
param principalId string
@description('The role definition name to assign to the user or group')
param roleDefinitionName string
@description('The name of the role assignment')
param roleAssignmentName string
@description('The description of the role assignment')
param roleAssignmentDescription string?

module scalingPlanRoleAssignment '../resources/desktop-virtualization/scaling-plan-role-assignment/main.bicep' = [
  for hostPoolReferencesObject in scalePlanObject.hostPoolReferenceObjectList! ?? []: {
    scope: resourceGroup(hostPoolReferencesObject.resourceGroupName)
    name: take('AVD-ScalePlan-RoleAssignment-${hostPoolReferencesObject.name}', 64)
    params: {
      hostPoolName: hostPoolReferencesObject.name
      roleAssignmentName: roleAssignmentName
      principalId: principalId
      roleDefinitionId: roleDefinitionName
      roleAssignmentDescription: roleAssignmentDescription
    }
  }
]

module scalingPlan '../resources/desktop-virtualization/scaling-plan/main.bicep' = {
  name: take('AVD-ScalePlan-${scalePlanObject.name}', 64)
  dependsOn: [
    scalingPlanRoleAssignment
  ]
  params: {
    resourceName: scalePlanObject.name
    scalingPlanDescription: scalePlanObject.?description
    location: location
    friendlyName: scalePlanObject.?friendlyName
    timeZone: scalePlanObject.timeZone
    scheduleObjectList: scalePlanObject.scheduleObjectList
    hostPoolReferenceObjectList: scalePlanObject.?hostPoolReferenceObjectList
    exclusionTag: scalePlanObject.?exclusionTag
    tagObject: scalePlanObject.?tagObject
  }
}
