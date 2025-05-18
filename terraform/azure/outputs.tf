output "blob_static_website_url" {
  description = "Blob storage static website endpoint"
  value       = azurerm_storage_account.static_site.primary_web_endpoint
}

output "sentimentAnalyzer_function_url" {
  value = azurerm_windows_function_app.sentimentAnalyzer.default_hostname
}

output "cosmosdb_tables" {
  value = [
    "${var.project_prefix}-custReview",
    "${var.project_prefix}-sentAnalysis"
  ]
}

output "queue_name" {
  value = azurerm_storage_queue.notification.name
}

output "cosmosdb_endpoint" {
  description = "CosmosDB endpoint URL"
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "cosmosdb_primary_key" {
  description = "Primary key to access CosmosDB"
  value       = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive   = true
}

output "summary_api_url" {
  value = "https://${azurerm_api_management.apim.name}.azure-api.net/summary"
}
