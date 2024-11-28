@description('The name of the Availability Set.')
param resourceName string
@description('The location for the Azure resource.')
param location string
@description('The name of the chosen SKU.')
param skuName ('Classic' | 'Aligned') = 'Classic'
@description('The fault domain count.')
param faultDomainCount int = 3
@description('The update domain count.')
param updateDomainCount int = 20
@description('The tag object is optional. Every property key provided will be a new tag with the associated value as tag value.')
param tagObject object?

resource availabilitySet 'Microsoft.Compute/availabilitySets@2017-03-30' = {
  name: resourceName
  location: location
  tags: tagObject
  properties: {
    platformFaultDomainCount: faultDomainCount
    platformUpdateDomainCount: updateDomainCount
  }
  sku: {
    name: skuName
  }
}

output resourceName string = availabilitySet.name
output resourceId string = availabilitySet.id
