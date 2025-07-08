resource "azurerm_storage_account" "uks_storage_account" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  access_tier              = var.access_tier
  account_kind                     = var.account_kind

  tags = var.tags
}