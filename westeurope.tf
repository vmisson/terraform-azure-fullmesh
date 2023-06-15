#################################################################################
#
# WEU Hub
# Address Space : 10.0.0.0/23
# ASN : 65000
#
#################################################################################
resource "azurerm_resource_group" "resource_group_weu" {
  name     = "DC-WEU"
  location = "West Europe"
}

resource "azurerm_virtual_network" "virtual_network_weu" {
  name                = "weuvn001"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  address_space       = ["10.0.0.0/23"]
}

#################################################################################
#
# WEU Gateway
#
#################################################################################
resource "azurerm_subnet" "gateway_subet_weu" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group_weu.name
  virtual_network_name = azurerm_virtual_network.virtual_network_weu.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_public_ip" "gateway_weu_pip" {
  name                = "weugw001-pip"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  sku                 = "Standard"
  allocation_method   = "Static"
  zones = [ "1", "2", "3" ]
}

resource "azurerm_public_ip" "gateway_weu_secondary_pip" {
  name                = "weugw002-pip"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  sku                 = "Standard"
  allocation_method   = "Static"
  zones = [ "1", "2", "3" ]
}

resource "azurerm_virtual_network_gateway" "gateway_weu" {
  name                = "weugw001"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1AZ"

  bgp_settings {
    asn = 65000
  }

  ip_configuration {
    name                          = "gw-ip1"
    public_ip_address_id          = azurerm_public_ip.gateway_weu_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_weu.id
  }
  ip_configuration {
    name                          = "gw-ip2"
    public_ip_address_id          = azurerm_public_ip.gateway_weu_secondary_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_weu.id
  }
}

#################################################################################
#
# WEU Local Network Gateway
#
#################################################################################
resource "azurerm_local_network_gateway" "local_network_gateway_weu" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_weu
  ]
  name                = "weugw001-lng"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  gateway_address     = azurerm_public_ip.gateway_weu_pip.ip_address

  bgp_settings {
    asn                 = 65000
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_weu.bgp_settings[0].peering_addresses[0].default_addresses[0]
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_weu_seconday" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_weu
  ]
  name                = "weugw002-lng"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name
  gateway_address     = azurerm_public_ip.gateway_weu_secondary_pip.ip_address

  bgp_settings {
    asn                 = 65000
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_weu.bgp_settings[0].peering_addresses[1].default_addresses[0]
  }
}

#################################################################################
#
# WEU Connections
#
#################################################################################
resource "azurerm_virtual_network_gateway_connection" "connection_weu-to-neu" {
  name                = "weu-to-neu"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_weu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_neu.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_weu-to-neu_seconday" {
  name                = "weu-to-neu_seconday"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_weu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_neu_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_weu-to-eus" {
  name                = "weu-to-eus"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_weu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_eus.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_weu-to-eus_seconday" {
  name                = "weu-to-eus_seconday"
  location            = azurerm_resource_group.resource_group_weu.location
  resource_group_name = azurerm_resource_group.resource_group_weu.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_weu.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_eus_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}