variable "name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "os_type" {
  description = "Operating system for the plan: Linux or Windows"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "SKU name (e.g. B1, P1v2, Y1)"
  type        = string
  default     = "Y1"
}

variable "worker_count" {
  description = "Number of workers (only for Premium or higher)"
  type        = number
  default     = 1
}

variable "zone_balancing_enabled" {
  description = "Whether to enable zone balancing (Premium only)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
