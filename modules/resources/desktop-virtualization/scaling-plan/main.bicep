@description('The name of the Scaling plan to be created.')
param resourceName string

@description('The description of the Scaling plan to be created.')
param scalingPlanDescription string?

@description('The location where the resources will be deployed.')
param location string

@description('The friendly name of the Scaling plan to be created.')
param friendlyName string?

@description('The host pool type of the Scaling plan to be created.')
param hostPoolType 'Pooled' = 'Pooled'

@description('Scaling plan autoscaling triggers and Start/Stop actions will execute in the time zone selected.')
param timeZone string

@description('The schedules of the Scaling plan to be created.')
param scheduleObjectList scheduleType[]

@description('The array of host pool resourceId with enabled flag.')
param hostPoolReferenceObjectList hostPoolReferenceType[]?

@description('The name of the tag associated with the VMs that will be excluded from the Scaling plan.')
param exclusionTag string?

@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

@export()
type scheduleType = {
  @description('The name of the Schedule')
  name: string
  @description('Set of days of the week on which this schedule is active.')
  daysOfWeek: ('Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday')[]
  @description('Load balancing algorithm for ramp up period.')
  offPeakLoadBalancingAlgorithm: ('BreadthFirst' | 'DepthFirst')
  @description('Configuration of the off peak start time for the schedule')
  offPeakStartTime: timeType
  @description('Load balancing algorithm for ramp up period.')
  peakLoadBalancingAlgorithm: ('BreadthFirst' | 'DepthFirst')
  @description('Configuration of the peak start time for the schedule')
  peakStartTime: timeType
  @description('Capacity threshold for ramp down period')
  @minValue(1)
  @maxValue(100)
  rampDownCapacityThresholdPct: int
  @description('Should users be logged off forcefully from hosts')
  rampDownForceLogoffUsers: bool
  @description('Load balancing algorithm for ramp up period.')
  rampDownLoadBalancingAlgorithm: ('BreadthFirst' | 'DepthFirst')
  @description('Minimum host percentage for ramp down period')
  @minValue(1)
  @maxValue(100)
  rampDownMinimumHostsPct: int
  @description('Notification message for users during ramp down period')
  rampDownNotificationMessage: string
  @description('Configuration of the ramp down start time for the schedule')
  rampDownStartTime: timeType
  @description('Specifies when to stop hosts during ramp down period.')
  rampDownStopHostsWhen: ('ZeroActiveSessions' | 'ZeroSessions')
  @description('Number of minutes to wait to stop hosts during ramp down period')
  rampDownWaitTimeMinutes: int
  @description('Capacity threshold for ramp up period.')
  @minValue(1)
  @maxValue(100)
  rampUpCapacityThresholdPct: int
  @description('Load balancing algorithm for ramp up period.')
  rampUpLoadBalancingAlgorithm: ('BreadthFirst' | 'DepthFirst')
  @description('Minimum host percentage for ramp up period.')
  @minValue(1)
  @maxValue(100)
  rampUpMinimumHostsPct: int
  @description('Configuration of the ramp up start time for the schedule')
  rampUpStartTime: timeType
}
type timeType = {
  @description('the hour of the start time')
  hour: int
  @description('the minute of the start time')
  minute: int
}

@export()
type hostPoolReferenceType = {
  @description('The name of the referenced host pool')
  name: string
  @description('The name of the resource group of the referenced host pool')
  resourceGroupName: string
  @description('Is the scaling plan enabled for this hostpool')
  scalingEnabled: bool
}

resource hostPoolExisting 'Microsoft.DesktopVirtualization/hostPools@2024-01-16-preview' existing = [
  for (hostPoolReference, index) in hostPoolReferenceObjectList! ?? []: {
    name: hostPoolReference.name
    scope: resourceGroup(hostPoolReference.resourceGroupName)
  }
]

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2023-11-01-preview' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    friendlyName: friendlyName
    description: scalingPlanDescription
    hostPoolType: hostPoolType
    timeZone: timeZone
    exclusionTag: exclusionTag
    schedules: scheduleObjectList
    hostPoolReferences: [
      for (hostPoolReference, index) in hostPoolReferenceObjectList! ?? []: {
        hostPoolArmPath: hostPoolExisting[index].id
        scalingPlanEnabled: hostPoolReference.scalingEnabled
      }
    ]
  }
}

output ResourceName string = scalingPlan.name
output ResourceId string = scalingPlan.id
