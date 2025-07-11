resource "azurerm_application_insights" "app_insights" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  workspace_id        = var.workspace_id
  tags                = var.tags
}
