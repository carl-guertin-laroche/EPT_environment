resource "azurerm_network_interface" "srvprivate" {
  count                 = (var.numberofpods * var.numberofserver)
  name                  = "${var.rgname}-server-ip-${format("%02d", count.index + 1)}"
  location              = var.region
  resource_group_name   = var.rgname
  depends_on            = [azurerm_resource_group.rg]
  tags                  = var.default_tags

  ip_configuration {
    name                          = "${var.rgname}-config-wsrvip-${format("%02d", count.index + 1)}"
    subnet_id                     = element(azurerm_subnet.private_subnet.*.id, count.index)
    private_ip_address_allocation = "dynamic"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "win-server" {
    count                 = (var.numberofpods * var.numberofserver)
    name                  = "${var.rgname}-srv-${format("%02d", count.index + 1)}"
    location              = var.region
    resource_group_name   = var.rgname
    network_interface_ids = [element(azurerm_network_interface.srvprivate.*.id, count.index)]
    vm_size               = var.srv-vmsize
    tags                  = var.default_tags

    # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    # Uncomment this line to delete the data disks automatically when deleting the VM
    delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
   storage_os_disk {
    name              = "${var.rgname}-srvosdisk-${format("%02d", count.index  + 1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
   os_profile {
    computer_name  = "amer${var.vnetip}-server${format("%02d", count.index  + 1)}"
    admin_username = var.vmadmusername
    admin_password = var.vmadmpassword
  }
  os_profile_windows_config {
      provision_vm_agent = true
      enable_automatic_upgrades = false
      timezone = "UTC"
  }
}

resource "azurerm_virtual_machine_extension" "srv-cst-script" {
  count                 = (var.numberofpods * var.numberofserver)
  name                  = "${var.rgname}-csesrv-${format("%02d", count.index + 1)}"
  #location              = var.region
  #resource_group_name   = var.rgname
  #virtual_machine_name  = "${var.rgname}-srv-${format("%02d", count.index + 1)}"
  virtual_machine_id    = element(azurerm_virtual_machine.win-server.*.id, count.index)
  publisher             = "Microsoft.Compute"
  type                  = "CustomScriptExtension"
  type_handler_version  = "1.10"
  
  
  protected_settings = <<PROTECTED_SETTINGS
     {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command \"./init.ps1; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://gist.githubusercontent.com/stefan-haas-tfs/b59e23fb393ac3964cdc5d2da2d6cda2/raw/885028696fd0ed289dc212346a62b8be41df62e8/init.ps1"
        ]
    }
  SETTINGS
  depends_on            = [azurerm_virtual_machine.win-server]
}

resource "azurerm_virtual_machine_extension" "join-srv-to-domain" {
  count                  = (var.numberofpods * var.numberofserver)
  name                   = "${var.rgname}-joinsrv-${format("%02d", count.index + 1)}"
  #location              = var.region
  #resource_group_name   = var.rgname
  #virtual_machine_name  = "${var.rgname}-srv-${format("%02d", count.index + 1)}"
  virtual_machine_id    = element(azurerm_virtual_machine.win-server.*.id, count.index)
  publisher              = "Microsoft.Compute"
  type                   = "JsonADDomainExtension"
  type_handler_version   = "1.3"
  

  # What the settings mean: https://docs.microsoft.com/en-us/windows/desktop/api/lmjoin/nf-lmjoin-netjoindomain

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
  depends_on = [azurerm_virtual_machine.win-server]
}