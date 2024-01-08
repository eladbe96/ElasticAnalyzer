provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}


data "archive_file" "init" {
  type        = "zip"
  source_file = "main.py"
  output_path = "my_deployment_package.zip"
}

# S3 related resources - policy and role

resource "aws_s3_bucket" "upload-backet-eladbe" {
  bucket = "user-upload-bucket-eladbe"
}


resource "aws_iam_role_policy" "s3_policy" {
  name = "s3-trigger_policy"
  role = aws_iam_role.lambda-s3-trigger_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*/*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda-s3-trigger_role" {
  name = "lambda-s3-trigger_role"
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

# Adding S3 bucket as trigger to my lambda and giving the permissions

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  depends_on = [aws_s3_bucket.upload-backet-eladbe]
  bucket = aws_s3_bucket.upload-backet-eladbe.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}

resource "aws_lambda_permission" "invoke_permissions" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.upload-backet-eladbe.id}"
}

#Lambda function

resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  filename         = "my_deployment_package.zip"
  source_code_hash = filebase64sha256("my_deployment_package.zip")
  role    = aws_iam_role.lambda-s3-trigger_role.arn
  handler = "main.lambda_handler"
  runtime = var.runtime
  environment {
     variables = {
        BUCKET_NAME = var.bucket_name
        BUCKET_REGION = var.aws_region
     }
  }
