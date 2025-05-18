provider "azurerm" {
  features {}
  use_oidc = true
  subscription_id    = var.subscription_id
  tenant_id          = var.tenant_id
  client_id          = var.client_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project_prefix}-rg"
  location = var.azure_location
}

resource "azurerm_storage_account" "static_site" {
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
  storage_account_name = azurerm_storage_account.static_site.name
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
  name                = "mccndb"
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
  scope                = azurerm_storage_account.static_site.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_windows_function_app.sentimentAnalyzer.identity[0].principal_id
}

resource "azurerm_api_management" "apim" {
  name                = "${var.project_prefix}-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "admin@myapp.com"
  publisher_email     = "admin@myapp.com"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "summary_api" {
  name                = "summary-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Summary API"
  path                = "summary"
  protocols           = ["https"]

}

# Define the operation
resource "azurerm_api_management_api_operation" "summary_post" {
  operation_id        = "post-summary"
  api_name            = azurerm_api_management_api.summary_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Post Summary"
  method              = "POST"
  url_template        = "/"
  response {
    status = 200
    description = "OK"
  }
  request {
    description = "Request body"
    query_parameters = []
    representations {
      content_type = "application/json"
      sample = "{\"key\": \"value\"}"
    }
  }
}

resource "azurerm_api_management_api_operation_policy" "summary_post_cors" {
  api_name            = azurerm_api_management_api.summary_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  operation_id        = "post-summary" # Must match operation ID (defined or imported)

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>POST</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
</policies>
XML
}

# Backend setting: connects APIM to the Function App endpoint
resource "azurerm_api_management_api_operation_policy" "backend_forward" {
  api_name            = azurerm_api_management_api.summary_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  operation_id        = azurerm_api_management_api_operation.summary_post.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service base-url="https://${azurerm_windows_function_app.fetchSummary.default_hostname}/api/fetchSummary" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
</policies>
XML
}
