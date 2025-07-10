resource "azurerm_virtual_network" "vnet_uks" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_uks.name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = lookup(each.value, "service_endpoints", null)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [1] : []
    content {
      name = each.value.delegation.name

      service_delegation {
        name    = each.value.delegation.service_delegation.name
        actions = each.value.delegation.service_delegation.actions
      }
    }
  }
}