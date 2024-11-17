resource "azurerm_role_assignment" "appgroups-roleassignment" {
  for_each             = toset(var.assignment_list)
  
  scope                = var.appgroup_resource_id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = each.value
}