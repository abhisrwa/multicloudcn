provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {}
}

resource "aws_s3_bucket" "static_site" {
  bucket = "${var.project_prefix}-static-site"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "app.js"
  source       = "${path.module}/../../static-website/app.js"
  content_type = "application/javascript"
  acl          = "public-read"
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "config.js"
  content_type = "application/javascript"
  content = <<EOT
window._env_ = {
  API_ENDPOINT_URL: "${aws_apigatewayv2_api.http_api.api_endpoint}/summary"
};
EOT
  acl = "public-read"
}


resource "aws_sqs_queue" "notification" {
  name = "js-queue-items"
}

#Eventbridge Scheduler
resource "aws_scheduler_schedule" "daily_trigger" {
  name = "${var.project_prefix}-daily-trigger"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 hours)"

  target {
    arn      = aws_lambda_function.sentimentAnalyzer.arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn

  }
}

resource "aws_dynamodb_table" "customerReviews" {
  name           = "customerReviews"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key     = "updated"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "updated"
    type = "S"
  }
}

resource "aws_dynamodb_table" "reviewSummary" {
  name           = "reviewSummary"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key     = "mrange"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "mrange"
    type = "S"
  }
}

# Create the HTTP API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_prefix}-summary-http-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins     = ["*"] # Or restrict to ["https://your-site.com"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age           = 3600
    expose_headers    = ["*"]
  }
}

# Lambda integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fetchSummary.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Route for POST /summary
resource "aws_apigatewayv2_route" "summary_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /summary"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_invoke_permission" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetchSummary.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# API Deployment
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "dev"
  auto_deploy = true
}

