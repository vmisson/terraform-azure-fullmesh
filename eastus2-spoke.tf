#################################################################################
#
# EUS Spoke
# Address Space : 10.2.2.0/23
#
#################################################################################
resource "azurerm_virtual_network" "virtual_network_eus_spoke" {
  name                = "eusvn002"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  address_space       = ["10.2.2.0/23"]
}

resource "azurerm_subnet" "workload_subet_eus" {
  name                 = "eusvn002sn001"
  resource_group_name  = azurerm_resource_group.resource_group_eus.name
  virtual_network_name = azurerm_virtual_network.virtual_network_eus_spoke.name
  address_prefixes     = ["10.2.2.0/24"]
}

resource "azurerm_virtual_network_peering" "virtual_network_peering_eus" {
  name                      = "eus-to-spoke"
  resource_group_name       = azurerm_resource_group.resource_group_eus.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_eus.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_eus_spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "virtual_network_peering_eus_spoke" {
  depends_on = [
    azurerm_virtual_network_peering.virtual_network_peering_eus,
    azurerm_virtual_network_gateway.gateway_eus
  ]
  name                      = "spoke-to-eus"
  resource_group_name       = azurerm_resource_group.resource_group_eus.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_eus_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_eus.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
}

#################################################################################
#
# EUS Spoke VM
#
#################################################################################
resource "azurerm_network_interface" "network_interface_spoke_eus" {
  name                = "eusvm001-nic"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  ip_configuration {
    name                          = "eusvm001-nic-configuration"
    subnet_id                     = azurerm_subnet.workload_subet_eus.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "linux_virtual_machine_spoke_eus" {
  name                  = "eusvm001"
  location              = azurerm_resource_group.resource_group_eus.location
  resource_group_name   = azurerm_resource_group.resource_group_eus.name
  network_interface_ids = [azurerm_network_interface.network_interface_spoke_eus.id]
  size                  = "Standard_B1ms"

  os_disk {
    name                 = "eusvm001-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = "azureuser"
  disable_password_authentication = false
  admin_password                  = random_password.password.result
}