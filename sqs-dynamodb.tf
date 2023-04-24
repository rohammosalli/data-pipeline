# Create Dynamodb table
resource "aws_dynamodb_table" "customer_table" {
  name           = "customer"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "customer_reference"
  attribute {
    name = "customer_reference"
    type = "S"
  }
}
# Lambda Function deploy from source
module "lambda_function_sqs-db" {
  source  = "terraform-aws-modules/lambda/aws"
  function_name = "sqs-to-db"
  description   = "My awesome lambda function"
  handler       = "sqs-db.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  attach_policy = true
  create_role     = false
  lambda_role = "${aws_iam_role.lambda_role.arn}"
  source_path = "./lambda"
  environment_variables = {
     SQS_URL = "${aws_sqs_queue.csv_queue.url}"
  }
  allowed_triggers = {
    AllowExecutionFromS3Bucket = {
      service    = "s3"
      source_arn = module.s3_bucket.s3_bucket_arn
    }
  }
   tags = {
    Pattern = "terraform"
    Module  = "lambda_function"
    Team = "DevOPS"
  }
   depends_on = [
    aws_iam_role.lambda_role
  ]
  }

# trigger lambda function when there is new message in sqs
resource "aws_lambda_event_source_mapping" "csv_to_json_mapping" {
  event_source_arn  = aws_sqs_queue.csv_queue.arn
  function_name     = module.lambda_function_sqs-db.lambda_function_name
  batch_size        = 10
}
# Attache policy to IAM
resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  policy_arn = aws_iam_policy.lambda_policy_sqs.arn
  role       = aws_iam_role.lambda_role.name
}
 
# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "csv-to-dynamodb-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
# Create IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy_sqs" {
  name = "json-to-dynamodb-lambda-policy"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "dynamodb:PutItem"
        ],
        Resource: aws_dynamodb_table.customer_table.arn
      },
      {
        Effect: "Allow",
        Action: [
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "lambda:InvokeFunction"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "arn:aws:logs:*:*:*"
      }
    ]
  })
}

###
