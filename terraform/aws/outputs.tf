output "static_website_url" {
  description = "S3 static website endpoint"
  value       = aws_s3_bucket.static_site.website_endpoint
}

output "sentimentAnalyzer_lambda_arn" {
  value = aws_lambda_function.sentimentAnalyzer.arn
}

output "fetchSummary_lambda_arn" {
  value = aws_lambda_function.fetchSummary.arn
}

output "sendEmailNotification_lambda_arn" {
  value = aws_lambda_function.sendEmailNotification.arn
}

output "dynamodb_tables" {
  value = [
    aws_dynamodb_table.customerReviews.name,
    aws_dynamodb_table.reviewSummary.name
  ]
}

output "sqs_queue_url" {
  value = aws_sqs_queue.notification.id
}


output "api_gateway_http_url" {
  description = "Invoke URL for HTTP API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}