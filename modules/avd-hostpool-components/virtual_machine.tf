resource "azurerm_availability_set" "availabilityset" {
  name                         = var.hostpool_object.AvailabilitySetName
  location                     = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].location : azurerm_resource_group.rg[0].location
  resource_group_name          = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name
}

resource "azurerm_network_interface" "nics" {
  for_each = {for key in var.hostpool_object.SessionHostObject.SessionHostList : key.VirtualMachineName => key}

  name                      = each.value.NetworkInterfaceName
  location                  = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].location : azurerm_resource_group.rg[0].location
  resource_group_name       = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.hostpool_object.SessionHostObject.SubnetResourceId
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "nicsasg" {
  for_each = azurerm_network_interface.nics

  network_interface_id          = each.value.id
  application_security_group_id = azurerm_application_security_group.asg.id
}

resource "azurerm_virtual_machine" "vms" {
  for_each = {for key in var.hostpool_object.SessionHostObject.SessionHostList : key.VirtualMachineName => key}

  name                  = each.value.VirtualMachineName
  location              = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].location : azurerm_resource_group.rg[0].location
  resource_group_name   = var.hostpool_object.ExistingRG ? data.azurerm_resource_group.datarg[0].name : azurerm_resource_group.rg[0].name
  network_interface_ids = [azurerm_network_interface.nics[each.key].id]
  vm_size               = each.value.VirtualMachineSize
  availability_set_id   = azurerm_availability_set.availabilityset.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = each.value.VirtualMachineImagePublisher
    offer     = each.value.VirtualMachineImageOffer
    sku       = each.value.VirtualMachineImageSku
    version   = "latest"
  }

  storage_os_disk {
    name              = "${each.value.VirtualMachineName}-OS-Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = lookup(each.value, "VirtualMachineOSDiskSize", null) == null ? var.hostpool_object.SessionHostObject.SessionHostOSDiskSize : each.value.VirtualMachineOSDiskSize
  }

  os_profile {
    computer_name  = each.value.VirtualMachineName
    admin_username = lookup(each.value, "AdminUserName", null) == null ? var.hostpool_object.SessionHostObject.SessionHostAdminUserName : each.value.AdminUserName
    admin_password = lookup(each.value, "AdminPassword", null) == null ? var.hostpool_object.SessionHostObject.SessionHostAdminPassword : each.value.AdminPassword
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
}
