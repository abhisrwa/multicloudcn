variable "project_prefix" {
  description = "Prefix used to name Azure resources"
  type        = string
  default     = "multicloudcn"
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "canadacentral"
}

variable "from_email_address" {
  description = "Sender email address for email notifications"
  type        = string
}

variable "azure_sendgrid_secret_name" {
  description = "Name of the secret in Azure Key Vault for the SendGrid API key"
  type        = string
  default     = "sendgrid/api_key"
}

variable "azure_key_vault_name" {
  description = "The name for the Azure Key Vault."
  type        = string
  default     = "kvsendgridsecrets2" # Must be globally unique
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "client_id" {
  type        = string
  description = "Azure client ID of the Federated Identity credential"
}
