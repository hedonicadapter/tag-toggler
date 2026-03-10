variable "resource_group_name" {
  description = "Name of the resource group to deploy into."
  type        = string
  default     = "rg-sand-sdc-automaton"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "database_password" {
  description = "Admin password used for database-like resources (PostgreSQL, MySQL, SQL MI, Synapse)."
  type        = string
  default     = "P@ssw0rd1234!"
  sensitive   = true
}

variable "enable_vm" {
  description = "Create the demo single VM."
  type        = bool
  default     = true
}

variable "vm_size" {
  description = "SKU for both the single VM and VMSS. Choose a cheap, available size."
  type        = string
  default     = "Standard_B1s"
}

variable "enable_vmss" {
  description = "Create the demo VM scale set."
  type        = bool
  default     = true
}

variable "enable_aks" {
  description = "Create the demo AKS cluster."
  type        = bool
  default     = true
}

variable "enable_webapp" {
  description = "Create the demo App Service plan and Linux web app."
  type        = bool
  default     = true
}

variable "enable_functionapp" {
  description = "Create the demo storage account, consumption plan, and Linux Function App."
  type        = bool
  default     = true
}

variable "enable_aci" {
  description = "Create the demo Azure Container Instance."
  type        = bool
  default     = true
}

variable "enable_postgres" {
  description = "Create the demo PostgreSQL flexible server."
  type        = bool
  default     = true
}

variable "enable_mysql" {
  description = "Create the demo MySQL flexible server."
  type        = bool
  default     = true
}

variable "enable_sqlmi" {
  description = "Create the demo SQL Managed Instance (long-running)."
  type        = bool
  default     = true
}

variable "enable_synapse" {
  description = "Create the demo Synapse workspace and dedicated SQL pool."
  type        = bool
  default     = false # expensive
}

variable "enable_app_gateway" {
  description = "Create the demo Application Gateway."
  type        = bool
  default     = true
}

variable "enable_spring_apps" {
  description = "Create the demo Azure Spring Apps service and app."
  type        = bool
  default     = true
}

variable "enable_stream_analytics" {
  description = "Create the demo Stream Analytics job (inputs/outputs must be added separately)."
  type        = bool
  default     = false # expensive
}
