resource "azurerm_service_plan" "consumption_plan" {
  name                = "${var.project_prefix}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_storage_account" "func_storage" {
  name                     = "${var.project_prefix}funcstore"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# --- Azure Key Vault ---
# This assumes you have already created the secret named 'SendGridApiKey'
# in Azure Key Vault manually or via another process.
resource "azurerm_key_vault" "kv" {
  name                = var.azure_key_vault_name # Must be globally unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Required for Azure Functions to reference secrets
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    Environment = "Development"
  }
}


# --- Azure Key Vault Secret Access Policy for the Function App's Managed Identity ---
resource "azurerm_key_vault_access_policy" "func_app_secret_get" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_function_app.sendNotification.identity[0].principal_id

  secret_permissions = [
    "Get", # Allow the Function App to get the secret value
  ]
}


resource "azurerm_windows_function_app" "fetchSummary" {
  name                       = "${var.project_prefix}-fetchsummary"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.consumption_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  site_config {
    ftps_state = "Disabled"

    cors {
      allowed_origins = [*] # ["https://${azurerm_storage_account.static_web.name}.z13.web.core.windows.net"]
      support_credentials = false
    }

    application_stack {
      node_version = "20"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_NODE_DEFAULT_VERSION   = "20"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    COSMOSDB_ENDPOINT     = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOSDB_DATABASE     = azurerm_cosmosdb_sql_database.database.name
    COSMOSDB_CUSTREVIEW   = azurerm_cosmosdb_sql_container.cust_review.name
    COSMOSDB_SENTANALYSIS = azurerm_cosmosdb_sql_container.sent_analysis.name

   }

  tags = {
    Environment = "Development"
  }
}

resource "azurerm_windows_function_app" "sendNotification" {
  name                       = "${var.project_prefix}-sendNotification"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.consumption_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  site_config {
    ftps_state = "Disabled"
   
    application_stack {
      node_version = "20"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_NODE_DEFAULT_VERSION   = "20"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    FROM_EMAIL                     = var.from_email_address
    SENDGRID_API_KEY               = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.kv.vault_uri}/secrets/${var.azure_sendgrid_secret_name}/)"

  }

  tags = {
    Environment = "Development"
  }
}


resource "azurerm_windows_function_app" "sentimentAnalyzer" {
  name                       = "${var.project_prefix}-sentimentAnalyzer"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.consumption_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  site_config {
    ftps_state = "Disabled"
   
    application_stack {
      node_version = "20"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_NODE_DEFAULT_VERSION   = "20"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    COSMOSDB_ENDPOINT     = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOSDB_DATABASE     = azurerm_cosmosdb_sql_database.database.name
    COSMOSDB_CUSTREVIEW   = azurerm_cosmosdb_sql_container.cust_review.name
    COSMOSDB_SENTANALYSIS = azurerm_cosmosdb_sql_container.sent_analysis.name
    AzureWebJobsStorage   = azurerm_storage_account.func_storage.primary_connection_string
    
    QUEUE_URL = "https://${azurerm_storage_account.blob.name}.queue.core.windows.net/${azurerm_storage_queue.notification.name}"
  }

  tags = {
    Environment = "Development"
  }
}

# Duplicate and modify for fetchSummary and sendEmailNotification functions
