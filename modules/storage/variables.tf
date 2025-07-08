variable "name" {
  description = "Globally unique name for the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, ZRS, RAGRS)"
  type        = string
  default     = "LRS"
}

variable "access_tier" {
  description = "Access tier (Hot or Cool) — only for Blob storage"
  type        = string
  default     = "Hot"
}

variable "account_kind" {
  description = "The kind of storage account to create"
  type        = string
  default     = "StorageV2"
}

variable "tags" {
  description = "A map of tags to apply to the storage account"
  type        = map(string)
  default     = {}
}
