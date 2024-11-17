# Import Hostpool RG if it alreadys exists
data "azurerm_resource_group" "datarg" {
  count = var.hostpool_object.ExistingRG ? 1 : 0

  name = var.hostpool_object.ResourceGroupName
}

# Create Hostpool RG if it needs to be created
resource "azurerm_resource_group" "rg" {
  count = var.hostpool_object.ExistingRG ? 0 : 1

  name      = var.hostpool_object.ResourceGroupName
  location  = var.location

  tags = lookup(var.hostpool_object, "ResourceGroupTags", null) != null ? var.hostpool_object.ResourceGroupTags : {}
}

# Rotating token for avd registration token
resource "time_rotating" "avd_token" {
  rotation_days = 30
}

# Create Host Pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  location                 = var.avd_resource_location
  resource_group_name      = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name

  name                     = var.hostpool_object.Name
  friendly_name            = var.hostpool_object.DisplayName
  description              = var.hostpool_object.Description
  type                     = "Pooled"
  maximum_sessions_allowed = var.hostpool_object.MaxSessionLimit
  load_balancer_type       = var.hostpool_object.LoadBalancerType

  # If the 30 days have expired, BEFORE you try to add an extra session host, the lifecycle part must be commented and then do a push to dev,
  # followed up by a PR to main - this will trigger the validation pipeline and the release pipeline which will create a new token
  # Afterwards, uncomment the lifecycle part again and add your extra session host
  lifecycle {
    ignore_changes = [
      registration_info,
    ]
  }

  registration_info {
    expiration_date = time_rotating.avd_token.rotation_rfc3339
  }
}

# Enable diag settings for hostpool
resource "azurerm_monitor_diagnostic_setting" "diagsettingshostpool" {
  name                        = "${azurerm_virtual_desktop_host_pool.hostpool.name}-DiagSettings"
  target_resource_id          = azurerm_virtual_desktop_host_pool.hostpool.id
  log_analytics_workspace_id  = var.la_resource_id
  //log_analytics_destination_type = "Dedicated" // When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table.

  log {
    category = "Checkpoint"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Error"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Connection"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "HostRegistration"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AgentHealthStatus"

    retention_policy {
      enabled = false
    }
  }
}

# Create Application Security Group
resource "azurerm_application_security_group" "asg" {
  name                = var.hostpool_object.ApplicationSecurityGroupName
  location            = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].location : azurerm_resource_group.rg[0].location
  resource_group_name = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name
}

# Create Application Groups
resource "azurerm_virtual_desktop_application_group" "applicationgroups" {
  for_each = {for key in var.hostpool_object.ApplicationGroupList : key.Name => key}

  name                = each.value.Name
  location            = var.avd_resource_location
  resource_group_name = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name

  type          = each.value.Type
  host_pool_id  = azurerm_virtual_desktop_host_pool.hostpool.id
  friendly_name = each.value.DisplayName
  description   = each.value.Description
}

# Associate Application Groups with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "associations" {
  for_each = azurerm_virtual_desktop_application_group.applicationgroups

  workspace_id         = var.avd_workspace_resource_id
  application_group_id = each.value.id
}

# Module to perform the Role assignments for the required application groups
module "avd-appgroups-role-assignments" {
  for_each = {for k,v in var.hostpool_object.ApplicationGroupList : k => v if lookup(v, "AssignmentList", null) != null}

  source = "./modules/avd-appgroups-role-assignments"

  appgroup_resource_id = azurerm_virtual_desktop_application_group.applicationgroups[each.value.Name].id
  assignment_list = each.value.AssignmentList

  depends_on = [
    azurerm_virtual_desktop_application_group.applicationgroups
  ]
}