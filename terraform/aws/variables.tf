variable "project_prefix" {
  description = "Prefix used to name AWS resources"
  type        = string
  default     = "multicloudcn"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "from_email_address" {
  description = "The verified sender email address in SendGrid."
  type        = string
}

variable "aws_lambda_function_name_analysis" {
  description = "The name for the AWS Lambda function."
  type        = string
  default     = "aws-sentiment-analyzer"
}

variable "aws_lambda_function_name_summary" {
  description = "The name for the AWS Lambda function."
  type        = string
  default     = "aws-fetch-summary"
}

variable "aws_lambda_function_name_sendmail" {
  description = "The name for the AWS Lambda function."
  type        = string
  default     = "aws-email-notification"
}

variable "aws_sendgrid_secret_name" {
  description = "The name of the secret in AWS Secrets Manager containing the SendGrid API Key."
  type        = string
  default     = "sendgrid/api_key" # Change if you named your secret differently
}

variable "azure_sendgrid_secret_val" {
  description = "Value of the secret in Azure Key Vault for the SendGrid API key"
  type        = string
  default     = "123"
  
}

variable "aws_lambda_code_bucket" {
  description = "The name of the bucket for code files."
  type        = string
  default     = "mcloud-code-bucket" # Change if you named your secret differently
}

variable "review_table" {
  default = "customerReviews"
}

variable "summary_table" {
  default = "reviewSummary"
}
