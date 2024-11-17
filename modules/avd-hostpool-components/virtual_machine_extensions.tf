resource "azurerm_virtual_machine_extension" "LogAnalytics" {
  for_each = azurerm_virtual_machine.vms

  name                       = "${each.value.name}-LogAnalytics"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
	{
	    "workspaceId": "${var.la_workspace_id}"
	}
SETTINGS

  protected_settings = <<protectedsettings
  {
      "workspaceKey": "${var.la_primary_shared_key}"
  }
protectedsettings
}

resource "azurerm_virtual_machine_extension" "domainJoin" {
  for_each = azurerm_virtual_machine.vms

   name                       = "${each.value.name}-domainJoin"
   virtual_machine_id         = each.value.id
   publisher                  = "Microsoft.Compute"
   type                       = "JsonADDomainExtension"
   type_handler_version       = "1.3"
   auto_upgrade_minor_version = true
   depends_on                 = [azurerm_virtual_machine_extension.LogAnalytics]

   lifecycle {
     ignore_changes = [
       settings,
       protected_settings,
     ]
   }

   settings = <<SETTINGS
     {
         "Name": "${var.domain_object.DomainFQDN}",
         "OUPath": "${var.domain_object.OuPath}",
         "User": "${var.domain_object.DomainJoinIdentity}",
         "Restart": "true",
         "Options": "3"
     }
 SETTINGS

   protected_settings = <<PROTECTED_SETTINGS
   {
          "Password": "${var.domain_object.DomainJoinPassword}"
   }
 PROTECTED_SETTINGS
 }

resource "azurerm_virtual_machine_extension" "additional_session_host_dscextension" {
  for_each = azurerm_virtual_machine.vms

  name                       = "${each.value.name}-avd_dsc"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  #depends_on                 = ["azurerm_virtual_machine_extension.domainJoin", "azurerm_virtual_machine_extension.custom_script_extensions"]
  depends_on                 = [azurerm_virtual_machine_extension.domainJoin]

  lifecycle {
    ignore_changes = [ settings ]
  }

  settings = <<SETTINGS
    {
        "modulesUrl": "${var.dsc_artifacts_location}/AVDSessionHostRegistration.zip",
        "configurationFunction": "Configuration.ps1\\AddSessionHost",
        "SasToken": "${var.dsc_artifacts_sastoken}",
        "properties": {
            "hostPoolName": "${azurerm_virtual_desktop_host_pool.hostpool.name}",
            "registrationInfoToken": "${try(lookup(azurerm_virtual_desktop_host_pool.hostpool.registration_info[0],"token"),null) == null ? "" : azurerm_virtual_desktop_host_pool.hostpool.registration_info[0].token}"
        }
    }
  SETTINGS

}

# extra extension if needed
// resource "azurerm_virtual_machine_extension" "custom_script_extensions" {
//   for_each = {for k,v in var.hostpool_object.SessionHostObject.SessionHostList : k => v}

//   name                 = "${each.value.VirtualMachineName}-custom_script_extensions"
//   location             = azurerm_resource_group.rg.location
//   resource_group_name  = azurerm_resource_group.rg.name
//   virtual_machine_name = each.value.VirtualMachineName
//   publisher            = "Microsoft.Compute"
//   type                 = "CustomScriptExtension"
//   depends_on           = ["azurerm_virtual_machine_extension.domainJoin"]
//   type_handler_version = "1.9"

//   lifecycle {
//     ignore_changes = [
//       "settings",
//     ]
//   }

//   settings = <<SETTINGS
//     {
//       "fileUris": ["${join("\",\"", var.extensions_custom_script_fileuris)}"],
//       "commandToExecute": "${var.extensions_custom_command}"
//     }
// SETTINGS
// }