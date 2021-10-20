#################################################################################
#
# WEU Spoke
# Address Space : 10.0.2.0/23
#
#################################################################################
resource "azurerm_virtual_network" "virtual_network_weu_spoke" {
  name                = "weuvn002"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  address_space       = ["10.0.2.0/23"]
}

resource "azurerm_subnet" "workload_subet_weu" {
  name                 = "weuvn002sn001"
  resource_group_name  = azurerm_resource_group.resource_group_weu.name
  virtual_network_name = azurerm_virtual_network.virtual_network_weu_spoke.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_network_peering" "virtual_network_peering_weu" {
  name                      = "weu-to-spoke"
  resource_group_name       = azurerm_resource_group.resource_group_weu.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_weu.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_weu_spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "virtual_network_peering_weu_spoke" {
  depends_on = [
    azurerm_virtual_network_peering.virtual_network_peering_weu,
    azurerm_virtual_network_gateway.gateway_weu
  ]
  name                      = "spoke-to-weu"
  resource_group_name       = azurerm_resource_group.resource_group_weu.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_weu_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_weu.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
}

#################################################################################
#
# WEU Spoke VM
#
#################################################################################
resource "azurerm_network_interface" "network_interface_spoke_weu" {
  name                = "weuvm001-nic"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  ip_configuration {
    name                          = "weuvm001-nic-configuration"
    subnet_id                     = azurerm_subnet.workload_subet_weu.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_id" "random_id_weu" {
  keepers = {
    resource_group = azurerm_resource_group.resource_group_weu.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "storage_account_spoke_weu" {
  name                     = "weudiag${random_id.random_id_weu.hex}"
  resource_group_name      = azurerm_resource_group.resource_group_weu.name
  location                 = azurerm_resource_group.resource_group_weu.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "linux_virtual_machine_spoke_weu" {
  name                  = "weuvm001"
  location              = azurerm_resource_group.resource_group_weu.location
  resource_group_name   = azurerm_resource_group.resource_group_weu.name
  network_interface_ids = [azurerm_network_interface.network_interface_spoke_weu.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "weuvm001-os"
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
  admin_password                  = random_password.password.result

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_account_spoke_weu.primary_blob_endpoint
  }
}
