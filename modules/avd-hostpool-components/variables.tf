variable "hostpool_object" {
  description = "Hostpool object with all the config."
  type        = any
}

variable "domain_object" {
  description = "Domain object with all the config."
  type        = any
}

variable "avd_resource_location" {
  description = "Location for the AVD resources."
  type        = string
}

variable "location" {
  description = "Location for the resources."
  type        = string
}

variable "avd_workspace_resource_id" {
  description = "AVD Workspace resource id."
  type        = string
}

variable "la_resource_id" {
  description = "Log Analytics resource id."
  type        = string
}

variable "la_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
}

variable "la_primary_shared_key" {
  description = "Log Analytics primary key."
  type        = string
  sensitive   = true
}

variable "dsc_artifacts_location" {
  description = "Dsc artifacts location."
  type        = string
}

variable "dsc_artifacts_sastoken" {
  description = "Dsc artifacts token."
  type        = string
}