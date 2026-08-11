locals {
  vm_scripts_release = "v1.0.1"
  vm_scripts_base    = "https://raw.githubusercontent.com/carl-guertin-laroche/terraform-vm-scripts/${local.vm_scripts_release}/Scripts"
}

resource "azurerm_network_interface" "srvprivate" {
  count               = (var.numberofpods * var.numberofserver)
  name                = "${var.rgname}-server-ip-${format("%02d", count.index + 1)}"
  location            = var.region
  resource_group_name = var.rgname
  depends_on          = [azurerm_resource_group.rg]
  tags                = var.default_tags

  ip_configuration {
    name                          = "${var.rgname}-config-wsrvip-${format("%02d", count.index + 1)}"
    subnet_id                     = element(azurerm_subnet.private_subnet.*.id, count.index)
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "win-server" {
  count               = (var.numberofpods * var.numberofserver)
  name                = "${var.rgname}-srv-${format("%02d", count.index + 1)}"
  location            = var.region
  resource_group_name = var.rgname
  network_interface_ids = [
    element(azurerm_network_interface.srvprivate.*.id, count.index)
  ]
  vm_size = var.srv-vmsize
  tags    = var.default_tags

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.rgname}-srvosdisk-${format("%02d", count.index + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "amer${var.vnetip}-server${format("%02d", count.index + 1)}"
    admin_username = var.vmadmusername
    admin_password = var.vmadmpassword
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
    timezone                  = var.timezone_id
  }
}

resource "azurerm_virtual_machine_extension" "srv-cst-script" {
  count                = (var.numberofpods * var.numberofserver)
  name                 = "${var.rgname}-csesrv-${format("%02d", count.index + 1)}"
  virtual_machine_id   = element(azurerm_virtual_machine.win-server.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = [
      "${local.vm_scripts_base}/Common.ps1",
      "${local.vm_scripts_base}/Environment.ps1",
      "${local.vm_scripts_base}/Install-Chocolatey.ps1",
      "${local.vm_scripts_base}/Install-TrainingTools.ps1",
      "${local.vm_scripts_base}/Install-TrendMicro.ps1",
      "${local.vm_scripts_base}/Configure-Windows.ps1",
      "${local.vm_scripts_base}/init.ps1"
    ]
  })

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File init.ps1 -EnvironmentType ${var.environment_type} -TimezoneId ${var.timezone_id} -TrendMicroTenantId ${var.trendmicro_tenant_id} -TrendMicroToken ${var.trendmicro_token} -TrendMicroPolicyId ${var.trendmicro_policy_id}"
  })

  depends_on = [azurerm_virtual_machine.win-server]
}

resource "azurerm_virtual_machine_extension" "join-srv-to-domain" {
  count                = (var.numberofpods * var.numberofserver)
  name                 = "${var.rgname}-joinsrv-${format("%02d", count.index + 1)}"
  virtual_machine_id   = element(azurerm_virtual_machine.win-server.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
{
  "Name": "CHROMEL.EPT",
  "OUPath": "OU=AzServers,DC=chromel,DC=ept",
  "User": "tadmin@chromel.ept",
  "Restart": "true",
  "Options": "3"
}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "Password": "${var.vmadmpassword}"
}
PROTECTED_SETTINGS

  depends_on = [azurerm_virtual_machine_extension.srv-cst-script]
}