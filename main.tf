provider "aws" {
  region = var.region
}

# Lambda Function deploy from source
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  function_name = "csv-to-json-lambda"
  description   = "pars csv to json and send it to SQS"
  handler       = "index.lambda_handler"
  runtime       = var.runtime
  publish       = true
  attach_policy = true
  create_role     = false
  lambda_role = "${aws_iam_role.iam_for_lambda.arn}"
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
    aws_iam_role.iam_for_lambda
  ]
}
# S3 bucket with notification
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  bucket  = "csv-pipline-bucket-heartbit"
  force_destroy = true
  tags = {
    Pattern = "terraform"
    Module  = "s3_bucket"
  }
}

module "s3_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "~> 3.0"
  bucket = module.s3_bucket.s3_bucket_id
  eventbridge = true
  lambda_notifications = {
    lambda1 = {
      function_arn  = module.lambda_function.lambda_function_arn
      function_name = module.lambda_function.lambda_function_name
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = ""
      filter_suffix = ""
    }
  }
}

# Create SQS 
resource "aws_sqs_queue" "csv_queue" {
  name = "csv-to-json"
}

# Create IAM role
resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda"

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
# Attache policy to IAM
resource "aws_iam_role_policy_attachment" "lambda_csv_policy" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.iam_for_lambda.name
}
# Create IAM policy
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        "Resource": aws_sqs_queue.csv_queue.arn
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ListQueues"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "lambda:InvokeFunction"
        ],
        "Resource": "*"
      },
  
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "${module.s3_bucket.s3_bucket_arn}",
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
