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
    AzureWebJobsStorage            = azurerm_storage_account.func_storage.primary_connection_string
    
    QUEUE_URL = "https://${azurerm_storage_account.blob.name}.queue.core.windows.net/${azurerm_storage_queue.notification.name}"
  }

  tags = {
    Environment = "Development"
  }
}

# Duplicate and modify for fetchSummary and sendEmailNotification functions
