resource "aws_iam_policy" "lambda_permissions" {
  name = "${var.project_name}-lambda-permissions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # --- Basic Lambda Execution Permissions ---
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      # --- DynamoDB Permissions (Refine these based on need) ---
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
        ],
        Resource = [
          aws_dynamodb_table.cust_review.arn,
          aws_dynamodb_table.sent_analysis.arn,
        ]
      },
      # --- SQS Send Message Permission (for sendEmailNotification lambda) ---
       {
         Effect = "Allow",
         Action = [
           "sqs:SendMessage"
         ],
         Resource = aws_sqs_queue.notification_queue.arn
       },
      # --- SES Send Email Permission (if sendEmailNotification lambda uses SES) ---
      # {
      #   Effect = "Allow",
      #   Action = [
      #     "ses:SendEmail",
      #     "ses:SendRawEmail"
      #   ],
      #   Resource = "*" # Refine to specific SES resources if possible
      # },
      # --- Add any other necessary permissions here (e.g., S3 access, etc.) ---
    ]
  })
}


# --- S3 Bucket for Static Website ---
resource "aws_s3_bucket" "static_website" {
  bucket = var.static_website_bucket_name

  # Enable versioning (recommended)
  versioning {
    enabled = true
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# WARNING: This bucket policy grants public read access.
# Consider using CloudFront with an Origin Access Identity (OAI) for better security.
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*" # Grants access to everyone
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_website.arn}/*" # Grants access to objects within the bucket
      },
    ]
  })
}

resource "aws_s3_bucket_acl" "static_website_acl" {
  # ACLs are being deprecated, bucket policies are preferred.
  # This is included for compatibility with static website hosting.
  # Ensure your bucket policy grants the necessary permissions.
  bucket = aws_s3_bucket.static_website.bucket
  acl    = "public-read" # Grants public read access to the bucket and its objects
  depends_on = [aws_s3_bucket_ownership_controls.static_website_acl_ownership] # Ensure ownership controls are set first
}

resource "aws_s3_bucket_ownership_controls" "static_website_acl_ownership" {
  # Required to allow setting ACLs
  bucket = aws_s3_bucket.static_website.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


# --- Lambda Functions ---
resource "aws_lambda_function" "sentiment_analyzer_lambda" {
  function_name    = "${var.project_name}-sentimentAnalyzer"
  runtime          = var.lambda_runtime
  handler          = "sentimentAnalyzer.handler" # Update with your handler file and method
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = var.lambda_sentiment_analyzer_zip # Path to your ZIP file
  source_code_hash = filebase64sha256(var.lambda_sentiment_analyzer_zip) # Recalculate hash on file change

  environment {
    variables = {
      # Example: Pass DynamoDB table names as environment variables
      CUST_REVIEW_TABLE = aws_dynamodb_table.cust_review.name
      SENT_ANALYSIS_TABLE = aws_dynamodb_table.sent_analysis.name
      # Add other environment variables your function needs (e.g., SQS URL)
    }
  }
  # Add memory, timeout, VPC config if needed
}

resource "aws_lambda_function" "fetch_summary_lambda" {
  function_name    = "${var.project_name}-fetchSummary"
  runtime          = var.lambda_runtime
  handler          = "fetchSummary.handler" # Update with your handler file and method
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = var.lambda_fetch_summary_zip # Path to your ZIP file
  source_code_hash = filebase64sha256(var.lambda_fetch_summary_zip) # Recalculate hash on file change

  environment {
    variables = {
      # Example: Pass DynamoDB table names as environment variables
      SENT_ANALYSIS_TABLE = aws_dynamodb_table.sent_analysis.name
      # Add other environment variables your function needs
    }
  }
  # Add memory, timeout, VPC config if needed
}

resource "aws_lambda_function" "send_email_notification_lambda" {
  function_name    = "${var.project_name}-sendEmailNotification"
  runtime          = var.lambda_runtime
  handler          = "sendEmailNotification.handler" # Update with your handler file and method
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = var.lambda_send_email_zip # Path to your ZIP file
  source_code_hash = filebase64sha256(var.lambda_send_email_zip) # Recalculate hash on file change

   environment {
    variables = {
      # Example: Pass SQS Queue URL as environment variable
      NOTIFICATION_QUEUE_URL = aws_sqs_queue.notification_queue.url
      # Add other environment variables (e.g., SES sender/recipient email)
    }
  }
  # Add memory, timeout, VPC config if needed
}

# --- EventBridge Scheduler ---
resource "aws_scheduler_schedule" "sentiment_analyzer_schedule" {
  name        = "${var.project_name}-sentiment-analyzer-schedule"
  description = "Schedules the sentimentAnalyzer Lambda function daily."
  schedule_expression = var.sentiment_analyzer_schedule_expression
  flexible_time_window {
    mode = "OFF" # Use "FLEXIBLE" with a maximum window for more flexibility
  }

  target {
    arn     = aws_lambda_function.sentiment_analyzer_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn # Role for EventBridge to invoke Lambda
  }
}

# IAM role for EventBridge Scheduler to invoke Lambda
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "${var.project_name}-scheduler-invoke-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "scheduler_invoke_lambda_policy" {
  name = "${var.project_name}-scheduler-invoke-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = aws_lambda_function.sentiment_analyzer_lambda.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_attach_invoke_lambda" {
  role       = aws_iam_role.scheduler_invoke_lambda_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda_policy.arn
}

# --- DynamoDB Tables ---
resource "aws_dynamodb_table" "cust_review" {
  name             = "${var.project_name}-custReview"
  billing_mode     = "PAY_PER_REQUEST" # Or "PROVISIONED"
  hash_key         = "ReviewId" # Change to your actual hash key attribute

  attribute {
    name = "ReviewId" # Change to your actual hash key attribute name and type
    type = "S" # S (String), N (Number), B (Binary)
  }

  tags = {
    Project = var.project_name
  }

  # Add more attributes, global secondary indexes, etc. as needed
}

resource "aws_dynamodb_table" "sent_analysis" {
  name             = "${var.project_name}-sentAnalysis"
  billing_mode     = "PAY_PER_REQUEST" # Or "PROVISIONED"
  hash_key         = "AnalysisId" # Change to your actual hash key attribute

  attribute {
    name = "AnalysisId" # Change to your actual hash key attribute name and type
    type = "S"
  }

  tags = {
    Project = var.project_name
  }

   # Add more attributes, global secondary indexes, etc. as needed
}

# --- SQS Queue ---
resource "aws_sqs_queue" "notification_queue" {
  name = "${var.project_name}-notification"

  tags = {
    Project = var.project_name
  }

  # Add visibility timeout, message retention, etc. as needed
}

# --- API Gateway ---
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api"
  description = "API for the application."

  tags = {
    Project = var.project_name
  }
}

resource "aws_api_gateway_resource" "summary_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "summary" # The path for the summary endpoint
}

resource "aws_api_gateway_method" "summary_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.summary_resource.id
  http_method   = "POST"
  authorization = "NONE" # Or configure appropriate authorization
}

resource "aws_api_gateway_integration" "summary_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.summary_resource.id
  http_method = aws_api_gateway_method.summary_post_method.http_method

  # Integration type and Lambda ARN
  integration_http_method = "POST" # The method used to call the backend (Lambda)
  type                    = "AWS_PROXY" # Or "AWS" for non-proxy integration
  uri                     = aws_lambda_function.fetch_summary_lambda.invoke_arn # ARN to invoke the Lambda function
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  # Redeploy on changes to methods, resources, or integrations
  # This trigger block ensures a new deployment when relevant resources change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.summary_post_method,
      aws_api_gateway_integration.summary_lambda_integration,
      # Add other resources that should trigger a redeployment
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  # NOTE: api_key_required = true might be needed if you are using API Keys
}

resource "aws_api_gateway_stage" "prod_stage" {
  stage_name    = "prod" # Or 'dev', 'staging', etc.
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# Grant API Gateway permission to invoke the fetchSummary Lambda function
resource "aws_lambda_permission" "allow_api_gateway_invoke_fetch_summary" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_summary_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN is required to restrict invocation to a specific API Gateway.
  # This format includes the execution ARN, the stage, the method, and the resource path.
  # Ensure the path matches the API Gateway resource path defined above.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*" # More restrictive source_arn can be used: "${aws_api_gateway_rest_api.api.execution_arn}/prod/POST/summary"
}