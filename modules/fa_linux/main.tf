resource "azurerm_linux_function_app" "fa_linux" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = var.app_service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  functions_extension_version = "~4"

  site_config {
    application_stack {
      python_version = var.runtime == "python" ? var.runtime_version : null
      node_version   = var.runtime == "node" ? var.runtime_version : null
      # Add more runtimes as needed
    }
  }

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME" = var.runtime
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
    },
    var.app_settings
  )

  tags = var.tags
}
