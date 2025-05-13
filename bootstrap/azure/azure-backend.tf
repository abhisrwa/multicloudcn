provider "azurerm" {
  features {}
  use_oidc = true
}

variable "az_resource_group" {
  description = "The resource group to be used set in the secrets."
  type        = string
}

resource "azurerm_resource_group" "tf" {
  name     = "${var.az_resource_group}"
  location = "centralcanada"
}

resource "azurerm_storage_account" "tf_state" {
  name                     = "mccntfstatebucket"
  resource_group_name      = azurerm_resource_group.tf.name
  location                 = azurerm_resource_group.tf.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name = "Terraform State Storage"
  }
}

resource "azurerm_storage_account" "code_bucket" {
  name                     = "mcloudcodebucket"
  resource_group_name      = azurerm_resource_group.tf.name
  location                 = azurerm_resource_group.tf.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name = "Code bucket"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tf_state.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "codebucket" {
  name                  = "codebucket"
  storage_account_name  = azurerm_storage_account.code_bucket.name
  container_access_type = "private"
}
