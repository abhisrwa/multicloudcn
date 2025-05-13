resource "aws_s3_bucket" "lambda_code" {
  bucket = "mcloud-code-bucket"
}
# --- Data Source: AWS Caller Identity (to get account ID) ---
data "aws_caller_identity" "current" {}

# --- Data Source: AWS Secrets Manager Secret ---
# This assumes you have already created the secret named 'sendgrid/api_key'
# in AWS Secrets Manager manually or via another process.
data "aws_secretsmanager_secret" "sendgrid_api_key_secret" {
  name = var.aws_sendgrid_secret_name # e.g., "sendgrid/api_key"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# --- IAM Policy for Lambda Logging ---
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "multicloudcn-logging-policy-mc"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = [
            "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:logGroups:/aws/lambda/${var.aws_lambda_function_name_analysis}:*",
            "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:logGroups:/aws/lambda/${var.aws_lambda_function_name_summary}:*",
            "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:logGroups:/aws/lambda/${var.aws_lambda_function_name_sendmail}:*"
        ]
      },
    ]
  })
}

# --- IAM Policy to allow Lambda to read the SendGrid API Key Secret ---
resource "aws_iam_policy" "lambda_secretsmanager_policy" {
  name        = "${var.aws_lambda_function_name_sendmail}-secretsmanager-policy-mc"
  description = "IAM policy for lambda to read SendGrid API Key from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret" # Sometimes needed depending on how the SDK retrieves
        ],
        Effect = "Allow",
        # Grant access to the specific secret
        Resource = data.aws_secretsmanager_secret.sendgrid_api_key_secret.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_policy.arn
}


resource "aws_lambda_function" "sentimentAnalyzer" {
  function_name = "${var.project_prefix}-sentimentAnalyzer"
  s3_bucket     = aws_s3_bucket.lambda_code.bucket
  s3_key        = "sentimentAnalyzer.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30
}

resource "aws_lambda_function" "fetchSummary" {
  function_name = "${var.project_prefix}-fetchSummary"
  s3_bucket     = aws_s3_bucket.lambda_code.bucket
  s3_key        = "fetchSummary.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30
}

resource "aws_lambda_function" "sendEmailNotification" {
  function_name = "${var.project_prefix}-sendNotification"
  s3_bucket     = aws_s3_bucket.lambda_code.bucket
  s3_key        = "sendNotification.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30
  environment {
    variables = {
      # Pass the secret ARN to the Lambda function as an environment variable
      # The Lambda code will use the AWS SDK to retrieve the secret value using this ARN
      SENDGRID_API_KEY_SECRET_ARN = data.aws_secretsmanager_secret.sendgrid_api_key_secret.arn
      FROM_EMAIL                  = var.from_email_address # Sender email from Terraform variable
    }
}
}

resource "aws_scheduler_schedule" "daily_trigger" {
  name = "${var.project_prefix}-daily-trigger"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 hours)"

  target {
    arn      = aws_lambda_function.sentimentAnalyzer.arn
    role_arn = aws_iam_role.lambda_exec.arn

  }
}
