# This creates Static Website S3 bucket, SQS, Eventbridge Scheduler and API gateway

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

  # Optional: Only needed if you're using ACLs explicitly.
  # acl = "public-read"
}

resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.static_site.bucket
  key          = "app.js"
  source       = "${path.module}/../../static-website/app.js"
  content_type = "application/javascript"
  acl          = "public-read"
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.static_site.bucket
  key          = "config.js"
  content_type = "application/javascript"
  content = <<EOT
window._env_ = {
  API_ENDPOINT_URL: "${aws_apigatewayv2_api.http_api.api_endpoint}/summary"
};
EOT
  #acl = "public-read"
}

resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "static_website_acl_ownership" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_wsite" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Create SQS
resource "aws_sqs_queue" "notification" {
  name = "js-queue-items"
}


# Calculate future time to schedule the Lambda run using eventbridge scheduler
locals {
  # Add 15 minutes to current time and format as ISO 8601
  future_time = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", timeadd(timestamp(), "15m"))
}

#Eventbridge Scheduler
resource "aws_scheduler_schedule" "daily_trigger" {
  name = "${var.project_prefix}-trigger"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "at(${local.future_time})" #"rate(1 hours)"

  target {
    arn      = aws_lambda_function.sentimentAnalyzer.arn
    role_arn = aws_iam_role.eventbridge_scheduler.arn

  }
  depends_on = [aws_lambda_function.sentimentAnalyzer]
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

