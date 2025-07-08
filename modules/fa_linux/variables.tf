variable "name" {
  type        = string
  description = "Name of the Linux Function App"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "app_service_plan_id" {
  type        = string
  description = "ID of the App Service Plan"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "storage_account_access_key" {
  type        = string
  description = "Primary access key of the storage account"
  sensitive   = true
}

variable "runtime" {
  type        = string
  description = "Runtime stack (e.g. python, node)"
  default     = "python"
}

variable "runtime_version" {
  type        = string
  description = "Version of the runtime (e.g. 3.10, 18)"
  default     = "3.10"
}

variable "app_settings" {
  type        = map(string)
  description = "Additional app settings"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the function app"
  default     = {}
}
