resource "azurerm_app_configuration" "appconfig" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_app_configuration_key" "appconfig_key" {
  for_each = var.key_values

  configuration_store_id = azurerm_app_configuration.appconfig.id
  key                    = each.key
  value                  = each.value.value
  label                  = each.value.value
  content_type           = each.value.value
}