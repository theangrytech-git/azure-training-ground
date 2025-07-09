variable "name" {
  description = "Name of the App Configuration store"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where App Configuration is created"
  type        = string
}

variable "sku" {
  description = "SKU (e.g., 'standard')"
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

variable "key_values" {
  description = "Map of key-value settings to store"
  type = map(object({
    value       = string
    value_label = optional(string)
    value_type  = optional(string)
  }))
  default = {}
}
