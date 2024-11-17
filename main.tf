provider "azurerm" {
  features {}
  subscription_id = "24380b0f-fd35-4966-816d-649e26aef48a"
}

terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.59.0"
    }
  }
}

# Import the Workspace RG if it alreadys exists
data "azurerm_resource_group" "dataworkspacerg" {
  count = local.var_config.WorkspaceObject.ExistingRG ? 1 : 0

  name = local.var_config.WorkspaceObject.ResourceGroupName
}

# Create the Workspace RG if it needs to be created
resource "azurerm_resource_group" "workspacerg" {
  count = local.var_config.WorkspaceObject.ExistingRG ? 0 : 1

  name      = local.var_config.WorkspaceObject.ResourceGroupName
  location  = local.var_config.Location

  tags = lookup(local.var_config.WorkspaceObject, "ResourceGroupTags", null) != null ? local.var_config.WorkspaceObject.ResourceGroupTags : {}
}

# Create the Workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = local.var_config.WorkspaceObject.Name
  location            = local.var_config.AVDResourceLocation
  resource_group_name = local.var_config.WorkspaceObject.ExistingRG ? data.azurerm_resource_group.dataworkspacerg[0].name : azurerm_resource_group.workspacerg[0].name

  friendly_name = local.var_config.WorkspaceObject.DisplayName
  description   = local.var_config.WorkspaceObject.Description
}

# Log Analytics Workspace data resource
data "azurerm_log_analytics_workspace" "la" {
  name = local.var_config.LogAnalyticsObject.Name
  resource_group_name = local.var_config.LogAnalyticsObject.ResourceGroupName
}

# Enable diag settings for workspace
resource "azurerm_monitor_diagnostic_setting" "diagsettingsworkspace" {
  name                        = "${local.var_config.WorkspaceObject.Name}-DiagSettings"
  target_resource_id          = azurerm_virtual_desktop_workspace.workspace.id
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.la.id
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
    category = "Feed"

    retention_policy {
      enabled = false
    }
  }
}

# Module to deploy the hostpool and its components
module "avd-hostpool-components" {
  for_each = {for key in local.var_config.HostpoolObjectList: key.Name => key}

  source = "./modules/avd-hostpool-components"

  hostpool_object = each.value
  domain_object = local.var_config.DomainObject
  location = local.var_config.Location
  avd_resource_location = local.var_config.AVDResourceLocation
  avd_workspace_resource_id = azurerm_virtual_desktop_workspace.workspace.id
  la_resource_id = data.azurerm_log_analytics_workspace.la.id
  la_workspace_id = data.azurerm_log_analytics_workspace.la.workspace_id
  la_primary_shared_key = data.azurerm_log_analytics_workspace.la.primary_shared_key
  dsc_artifacts_location = local.var_config.DscArtifactsLocation
  dsc_artifacts_sastoken = local.var_config.DscArtifactsSasToken
}
