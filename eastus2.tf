#################################################################################
#
# EUS Hub
# Address Space : 10.2.0.0/23
# ASN : 65002
#
#################################################################################
resource "azurerm_resource_group" "resource_group_eus" {
  name     = "DC-EUS"
  location = "East US2"
}

resource "azurerm_virtual_network" "virtual_network_eus" {
  name                = "eusvn001"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  address_space       = ["10.2.0.0/23"]
}

#################################################################################
#
# EUS Gateway
#
#################################################################################
resource "azurerm_subnet" "gateway_subet_eus" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group_eus.name
  virtual_network_name = azurerm_virtual_network.virtual_network_eus.name
  address_prefixes     = ["10.2.0.0/26"]
}

resource "azurerm_public_ip" "gateway_eus_pip" {
  name                = "eusgw001-pip"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  sku                 = "Standard"
  allocation_method   = "Static"
    zones = [ "1", "2", "3" ]
}

resource "azurerm_public_ip" "gateway_eus_secondary_pip" {
  name                = "eusgw002-pip"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  sku                 = "Standard"
  allocation_method   = "Static"
    zones = [ "1", "2", "3" ]
}

resource "azurerm_virtual_network_gateway" "gateway_eus" {
  name                = "eusgw001"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1AZ"

  bgp_settings {
    asn = 65002
  }

  ip_configuration {
    name                          = "gw-ip1"
    public_ip_address_id          = azurerm_public_ip.gateway_eus_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_eus.id
  }
  ip_configuration {
    name                          = "gw-ip2"
    public_ip_address_id          = azurerm_public_ip.gateway_eus_secondary_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subet_eus.id
  }
}

#################################################################################
#
# EUS Local Network Gateway
#
#################################################################################
resource "azurerm_local_network_gateway" "local_network_gateway_eus" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_eus
  ]
  name                = "eusgw001-lng"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  gateway_address     = azurerm_public_ip.gateway_eus_pip.ip_address

  bgp_settings {
    asn                 = 65002
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_eus.bgp_settings[0].peering_addresses[0].default_addresses[0]
  }
}

resource "azurerm_local_network_gateway" "local_network_gateway_eus_seconday" {
  depends_on = [
    azurerm_virtual_network_gateway.gateway_eus
  ]
  name                = "eusgw002-lng"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name
  gateway_address     = azurerm_public_ip.gateway_eus_secondary_pip.ip_address

  bgp_settings {
    asn                 = 65002
    bgp_peering_address = azurerm_virtual_network_gateway.gateway_eus.bgp_settings[0].peering_addresses[1].default_addresses[0]
  }
}

#################################################################################
#
# EUS Connections
#
#################################################################################
resource "azurerm_virtual_network_gateway_connection" "connection_eus-to-weu" {
  name                = "eus-to-weu"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_eus.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_weu.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_eus-to-weu_seconday" {
  name                = "eus-to-weu_seconday"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_eus.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_weu_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_eus-to-neu" {
  name                = "eus-to-neu"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_eus.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_neu.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}

resource "azurerm_virtual_network_gateway_connection" "connection_eus-to-neu_seconday" {
  name                = "eus-to-neu_seconday"
  location            = azurerm_resource_group.resource_group_eus.location
  resource_group_name = azurerm_resource_group.resource_group_eus.name

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gateway_eus.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway_neu_seconday.id
  dpd_timeout_seconds        = 15

  shared_key = random_password.psk.result
}