# --- Data Source: AWS Caller Identity (to get account ID) ---
data "aws_caller_identity" "current" {}

# --- Data Source: AWS Secrets Manager Secret ---
# This assumes you have already created the secret named 'sendgrid/api_key'
# in AWS Secrets Manager manually or via another process.
resource "aws_secretsmanager_secret" "sendgrid_api_key_secret" {
  name = var.aws_sendgrid_secret_name # e.g., "sendgrid/api_key"
}

resource "aws_secretsmanager_secret_version" "sendgrid_api_key_version" {
  secret_id     = aws_secretsmanager_secret.sendgrid_api_key_secret.id
  secret_string = var.azure_sendgrid_secret_val
}

resource "aws_lambda_function" "sentimentAnalyzer" {
  function_name = "${var.project_prefix}-sentimentAnalyzer"
  s3_bucket     = "${var.aws_lambda_code_bucket}"
  s3_key        = "sentimentAnalyzer.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.sentimentAnalyzer_role.arn
  timeout       = 30
  environment {
    variables = {
      # Pass the secret ARN to the Lambda function as an environment variable
      # The Lambda code will use the AWS SDK to retrieve the secret value using this ARN
      DB_REVIEW_TABLE = aws_dynamodb_table.customerReviews.name
      DB_SUMM_TABLE   = aws_dynamodb_table.reviewSummary.name # Sender email from Terraform variable
      APPID           = "389801252"
    }
}
}

resource "aws_lambda_function" "fetchSummary" {
  function_name = "${var.project_prefix}-fetchSummary"
  s3_bucket     = "${var.aws_lambda_code_bucket}"
  s3_key        = "fetchSummary.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.fetchSummary_role.arn
  timeout       = 30
  environment {
    variables = {
      # Pass the secret ARN to the Lambda function as an environment variable
      # The Lambda code will use the AWS SDK to retrieve the secret value using this ARN
      DB_REVIEW_TABLE = aws_dynamodb_table.customerReviews.name
      DB_SUMM_TABLE   = aws_dynamodb_table.reviewSummary.name # Sender email from Terraform variable
    }
}
}

resource "aws_lambda_function" "sendEmailNotification" {
  function_name = "${var.project_prefix}-sendNotification"
  s3_bucket     = "${var.aws_lambda_code_bucket}"
  s3_key        = "sendNotification.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.sendNotification_role.arn
  timeout       = 30
  environment {
    variables = {
      # Pass the secret ARN to the Lambda function as an environment variable
      # The Lambda code will use the AWS SDK to retrieve the secret value using this ARN
      SENDGRID_API_KEY_SECRET_ARN = data.aws_secretsmanager_secret.sendgrid_api_key_secret.arn
      FROM_EMAIL                  = var.from_email_address # Sender email from Terraform variable
      TO_EMAIL                    = "testEmail"
    }
}
}

# Lambda permission: Allow EventBridge Scheduler to invoke the Lambda
resource "aws_lambda_permission" "allow_scheduler" {
  statement_id  = "AllowExecutionFromScheduler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sentimentAnalyzer.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_scheduler_schedule.daily_trigger.arn
}

