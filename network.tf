resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.rgname}"
  address_space       = ["10.${format("%0d", var.vnetip)}.0.0/16"]
  location            = var.region
  resource_group_name = var.rgname
  tags                = var.default_tags
  dns_servers         = ["10.101.1.4"]
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "private_subnet" {
  count                = var.numberofpods
  name                 = "${var.rgname}-private-${format("%02d", count.index + 1)}"
  resource_group_name  = var.rgname
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.${format("%0d", var.vnetip)}.${format("%0d", count.index + 10)}.0/24"]
  #network_security_group_id = azurerm_network_security_group.pod_nsg.id
  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc-pod_nsg" {
  count                     = var.numberofpods
  subnet_id                 = element(azurerm_subnet.private_subnet.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.pod_nsg.id
}

resource "azurerm_network_security_group" "pod_nsg" {
  name                = "${var.rgname}-pod"
  location            = var.region
  resource_group_name = var.rgname
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_network_security_rule" "allow_rdp" {
  name                        = "Allow_RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.friendlyports
  source_address_prefixes     = ["10.${format("%0d", var.vnetip)}.0.0/16"]
  destination_address_prefix  = "*"
  resource_group_name         = var.rgname
  network_security_group_name = azurerm_network_security_group.pod_nsg.name
}

data "azurerm_virtual_network" "remoteVN" {
  name                = "vnet-permanent-resources"
  resource_group_name = "rg-permanent-resources"
}

output "virtual_network_id" {
  value = data.azurerm_virtual_network.remoteVN.id
}

data "azurerm_resource_group" "remoteRG" {
  name = "rg-permanent-resources"
}

resource "azurerm_virtual_network_peering" "spoke" {
  name                         = "${var.rgname}-spoke2hub"
  resource_group_name          = var.rgname
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.remoteVN.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  # allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "hub" {
  name                         = "${var.rgname}-hub2spoke"
  resource_group_name          = data.azurerm_resource_group.remoteRG.name
  virtual_network_name         = data.azurerm_virtual_network.remoteVN.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
}

/*----------------------------------------------------------------------------------

resource "azurerm_subnet" "public_subnet" {
  name                      = "${var.rgname}-public-01"
  resource_group_name       = var.rgname
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefix            = "10.${format("%0d", var.vnetip)}.1.0/24"
  network_security_group_id = azurerm_network_security_group.public_nsg.id
  service_endpoints         = ["Microsoft.Storage"]

}

resource "azurerm_subnet" "shared_private_subnet" {
  name                      = "${var.rgname}-shared-01"
  resource_group_name       = var.rgname
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefix            = "10.${format("%0d", var.vnetip)}.3.0/24"
  network_security_group_id = azurerm_network_security_group.pod_nsg.id
  service_endpoints         = ["Microsoft.Sql", "Microsoft.Storage"]

}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc-public_nsg" {
 subnet_id                 = azurerm_subnet.public_subnet.id
 network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_network_security_group" "public_nsg" {
  name                = "${var.rgname}-public"
  location            = var.region
  resource_group_name = var.rgname
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_network_security_rule" "allow_public" {
  name                          = "allow_tfs_internal"
  priority                      = 100
  direction                     = "Inbound"
  access                        = "Allow"
  protocol                      = "Tcp"
  source_port_range             = "*"
  destination_port_range        = "3389"
  source_address_prefixes       = ["10.${format("%0d", var.vnetip)}.1.0/24"]
  destination_address_prefix    = "*"
  resource_group_name           = var.rgname
  network_security_group_name   = azurerm_network_security_group.pod_nsg.name
}

-------------------------
resource "azurerm_network_security_rule" "AllowInternet" {
  name                          = "AllowInternet"
  priority                      = 110
  direction                     = "Outbound"
  access                        = "Allow"
  protocol                      = "Tcp"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = "Internet"
  destination_address_prefix    = "Internet"
  resource_group_name           = var.rgname
  network_security_group_name   = azurerm_network_security_group.pod_nsg.name
}

resource "azurerm_network_security_rule" "AllowSubnetInBound" {
  count                         = var.numberofpods
  name                          = "AllowSubnetInBound"
  priority                      = (var.numberofpods + 400)
  direction                     = "Inbound"
  access                        = "Allow"
  protocol                      = "*"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = azurerm_subnet.private_subnet[count.index].address_prefix
  destination_address_prefix    = azurerm_subnet.private_subnet[count.index].address_prefix
  resource_group_name           = var.rgname
  network_security_group_name   = azurerm_network_security_group.pod_nsg.name
}

resource "azurerm_network_security_rule" "AllowSubnetOutBound" {
  count                         = var.numberofpods
  name                          = "AllowSubnetOutBound"
  priority                      = (var.numberofpods + 300)
  direction                     = "Outbound"
  access                        = "Allow"
  protocol                      = "*"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = azurerm_subnet.private_subnet[count.index].address_prefix
  destination_address_prefix    = azurerm_subnet.private_subnet[count.index].address_prefix
  resource_group_name           = var.rgname
  network_security_group_name   = azurerm_network_security_group.pod_nsg.name
}

resource "azurerm_network_security_rule" "DenyVnetOutBound" {
  name                          = "DenyVnetOutBound"
  priority                      = 500
  direction                     = "Outbound"
  access                        = "Deny"
  protocol                      = "*"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = "VirtualNetwork"
  destination_address_prefix    = "VirtualNetwork"
  resource_group_name           = var.rgname
  network_security_group_name   = azurerm_network_security_group.pod_nsg.name
} 
-----------------------------------------------------------------------------------*/