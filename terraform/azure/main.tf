provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_prefix}-rg"
  location = var.azure_location
}

resource "azurerm_storage_account" "blob" {
  name                     = "${var.project_prefix}storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_storage_queue" "notification" {
  name                 = "js-queue-items"
  storage_account_name = azurerm_storage_account.blob.name
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${var.project_prefix}-cosmosdb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless" # Serverless mode (no RU/s)
  }

  enable_free_tier = true

  tags = {
    Environment = "Development"
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "database" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

# Container: custReview
resource "azurerm_cosmosdb_sql_container" "cust_review" {
  name                = "customerReviews"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.database.name
  partition_key_path  = "/id"
  throughput          = null # Serverless, so no fixed throughput
}

# Container: sentAnalysis
resource "azurerm_cosmosdb_sql_container" "sent_analysis" {
  name                = "reviewSummary"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.database.name
  partition_key_path  = "/id"
  throughput          = null
}

resource "azurerm_role_assignment" "sentiment_cosmosdb_access" {
  scope                = azurerm_cosmosdb_account.cosmos.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = azurerm_windows_function_app.sentimentAnalyzer.identity[0].principal_id
}

resource "azurerm_role_assignment" "fetchsummary_cosmosdb_access" {
  scope                = azurerm_cosmosdb_account.cosmos.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = azurerm_windows_function_app.fetchSummary.identity[0].principal_id
}

resource "azurerm_role_assignment" "queue_send_permission" {
  scope                = azurerm_storage_account.blob.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_windows_function_app.sentimentAnalyzer.identity[0].principal_id
}


