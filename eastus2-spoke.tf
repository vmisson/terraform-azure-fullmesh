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

resource "random_id" "random_id_eus" {
  keepers = {
    resource_group = azurerm_resource_group.resource_group_eus.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "storage_account_spoke_eus" {
  name                     = "eusdiag${random_id.random_id_eus.hex}"
  resource_group_name      = azurerm_resource_group.resource_group_eus.name
  location                 = azurerm_resource_group.resource_group_eus.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "linux_virtual_machine_spoke_eus" {
  name                  = "eusvm001"
  location              = azurerm_resource_group.resource_group_eus.location
  resource_group_name   = azurerm_resource_group.resource_group_eus.name
  network_interface_ids = [azurerm_network_interface.network_interface_spoke_eus.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "eusvm001-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username                  = "azureuser"
  disable_password_authentication = false
  admin_password = random_password.password.result

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account_spoke_eus.primary_blob_endpoint
  }
}