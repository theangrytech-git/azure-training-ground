output "vnet_id" {
  value = azurerm_virtual_network.vnet_uks.id
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet_uks.name
}