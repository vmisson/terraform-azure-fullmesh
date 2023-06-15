#################################################################################
#
# NEU Hub
# Address Space : 10.1.0.0/23
# ASN : 65001
#
#################################################################################
resource "azurerm_resource_group" "resource_group_neu" {
  name     = "DC-NEU"
  location = "North Europe"
}

resource "azurerm_virtual_network" "virtual_network_neu" {
  name                = "neuvn001"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name
  address_space       = ["10.1.0.0/23"]
}

#################################################################################
#
# NEU Gateway
#
#################################################################################
resource "azurerm_subnet" "gateway_subet_neu" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group_neu.name
  virtual_network_name = azurerm_virtual_network.virtual_network_neu.name
  address_prefixes     = ["10.1.0.0/26"]
}

resource "azurerm_public_ip" "gateway_neu_pip" {
  name                = "neugw001-pip"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name
  sku                 = "Standard"
  allocation_method   = "Static"
    zones = [ "1", "2", "3" ]
}

resource "azurerm_public_ip" "gateway_neu_secondary_pip" {
  name                = "neugw002-pip"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name
  sku                 = "Standard"
  allocation_method   = "Static"
    zones = [ "1", "2", "3" ]
}

resource "azurerm_virtual_network_gateway" "gateway_neu" {
  name                = "neugw001"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1AZ"

  bgp_settings {
    asn = 65001
  }

  ip_configuration {
    name                          = "gw-ip1"
    public_ip_address_id          = azurerm_public_ip.gateway_neu_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_neu.id
  }
  ip_configuration {
    name                          = "gw-ip2"
    public_ip_address_id          = azurerm_public_ip.gateway_neu_secondary_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_neu.id
  }
}

#################################################################################
#
# NEU Local Network Gateway
#
#################################################################################
resource "azurerm_local_network_gateway" "local_network_gateway_neu" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_neu
  ]
  name                = "neugw001-lng"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name
  gateway_address     = azurerm_public_ip.gateway_neu_pip.ip_address

  bgp_settings {
    asn                 = 65001
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_neu.bgp_settings[0].peering_addresses[0].default_addresses[0]
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_neu_seconday" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_neu
  ]
  name                = "neugw002-lng"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name
  gateway_address     = azurerm_public_ip.gateway_neu_secondary_pip.ip_address

  bgp_settings {
    asn                 = 65001
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_neu.bgp_settings[0].peering_addresses[1].default_addresses[0]
  }
}

#################################################################################
#
# NEU Connections
#
#################################################################################
resource "azurerm_virtual_network_gateway_connection" "connection_neu-to-weu" {
  name                = "neu-to-weu"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_neu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_weu.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_neu-to-weu_seconday" {
  name                = "neu-to-weu_seconday"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_neu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_weu_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_neu-to-eus" {
  name                = "neu-to-eus"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_neu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_eus.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_neu-to-eus_seconday" {
  name                = "neu-to-eus_seconday"
  location            = azurerm_resource_group.resource_group_neu.location
  resource_group_name = azurerm_resource_group.resource_group_neu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_neu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_eus_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}