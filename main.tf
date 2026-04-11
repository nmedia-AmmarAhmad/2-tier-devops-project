terraform {
  backend "s3" {
    bucket = "ammar-tf-state-storage-unique-id" # You must create this manually once
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
provider "aws" {
  region = "us-east-1"
}

# 1. THE DATABASE (RDS MySQL)
resource "aws_db_instance" "support_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "support_portal"
  username               = "admin"
  password               = "AmmarSupport2026"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# 2. SECURITY GROUP (The Firewall)
resource "aws_security_group" "db_sg" {
  name        = "allow_lambda_to_db"
  description = "Allow Lambda to talk to MySQL"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. IAM ROLE (The "Security Badge" you were missing)
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "my_app" {
  filename         = "lambda_function_payload.zip"
  function_name    = "my-python-app"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"

  # THIS LINE IS THE FIX:
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}

# 5. API GATEWAY (The Front Door)
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "serverless_lambda_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.my_app.arn
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# 1. THE STORAGE (S3 Bucket)
resource "aws_s3_bucket" "uploads" {
  bucket = "ammar-portal-uploads-2026" # Must be unique globally
}

# 2. THE PERMISSION (Policy for S3)
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_upload_policy"
  description = "Allows Lambda to upload to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:PutObject", "s3:PutObjectAcl"]
      Effect   = "Allow"
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

# Attach this policy to your existing role
resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# 6. OUTPUT THE URL
output "base_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}