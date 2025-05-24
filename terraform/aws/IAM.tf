# Lambda IAM Role -- for fetchSummary lambda 
resource "aws_iam_role" "fetchSummary_role" {
  name = "fetchSummary_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Lambda IAM Role -- for sentimentAnalyzer lambda function

resource "aws_iam_role" "sentimentAnalyzer_role" {
  name = "sentimentAnalyzer_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Lambda IAM Role -- for sendNotification lambda 
resource "aws_iam_role" "sendNotification_role" {
  name = "sendNotification_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy Document for DynamoDB Read/Write
data "aws_iam_policy_document" "dynamodb_rw" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.review_table}",
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.summary_table}"
    ]
  }
}

# Create the IAM Policy for DynamoDB
resource "aws_iam_policy" "dynamodb_rw_policy" {
  name   = "lambda-dynamodb-rw-policy"
  policy = data.aws_iam_policy_document.dynamodb_rw.json
}

# Create the IAM Policy for SQS access
resource "aws_iam_policy" "lambda_sqs_write_policy" {
  name = "lambda-sqs-write-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "sqs:SendMessage"
      ],
      Resource = aws_sqs_queue.notification.arn
    }]
  })
  depends_on = [ aws_sqs_queue.notification ]
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
        Resource = aws_secretsmanager_secret.sendgrid_api_key_secret.arn
      },
    ]
  })
  depends_on = [ aws_secretsmanager_secret.sendgrid_api_key_secret ]
}

#Attach policies to Lambda function role##
## for sentimentAnalyzer lambda
resource "aws_iam_role_policy_attachment" "slambda_logs" {
  role       = aws_iam_role.sentimentAnalyzer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "slambda_dynamodb_rw_attach" {
  name       = "lambda-dynamodb-rw-attach"
  roles      = [aws_iam_role.sentimentAnalyzer_role.name]
  policy_arn = aws_iam_policy.dynamodb_rw_policy.arn
}

resource "aws_iam_role_policy_attachment" "slambda_sqs_write_attach" {
  role       = aws_iam_role.sentimentAnalyzer_role.name
  policy_arn = aws_iam_policy.lambda_sqs_write_policy.arn
}

## for sendNotification lambda
resource "aws_iam_role_policy_attachment" "nlambda_logs" {
  role       = aws_iam_role.sendNotification_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "nlambda_sqs_write_attach" {
  role       = aws_iam_role.sendNotification_role.name
  policy_arn = aws_iam_policy.lambda_sqs_write_policy.arn
}
resource "aws_iam_role_policy_attachment" "nlambda_secretsmanager_attachment" {
  role       = aws_iam_role.sendNotification_role.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_policy.arn
}

## for fetcSummary lambda
resource "aws_iam_role_policy_attachment" "flambda_logs" {
  role       = aws_iam_role.fetchSummary_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "flambda_dynamodb_rw_attach" {
  name       = "lambda-dynamodb-rw-attach"
  roles       = [aws_iam_role.fetchSummary_role.name]
  policy_arn = aws_iam_policy.dynamodb_rw_policy.arn
}

# IAM Role that EventBridge Scheduler assumes
resource "aws_iam_role" "eventbridge_scheduler" {
  name = "eventbridge-scheduler-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM policy: Allow this role to invoke the Lambda function
resource "aws_iam_role_policy" "eventbridge_scheduler_invoke_lambda" {
  name = "eventbridge-scheduler-invoke-lambda"
  role = aws_iam_role.eventbridge_scheduler.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = aws_lambda_function.sentimentAnalyzer.arn
    }]
  })
  depends_on = [ aws_lambda_function.sentimentAnalyzer ]
}

