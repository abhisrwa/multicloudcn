
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



