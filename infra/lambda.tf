
resource "aws_lambda_function" "query_handler" {
  function_name = var.query_lambda_function_name
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket         = var.lambda_s3_bucket
  s3_key            = var.query_lambda_s3_key
  source_code_hash  = var.query_lambda_source_hash

  environment {
    variables = {
      PINECONE_ENV         = var.pinecone_env
      PINECONE_INDEX_NAME  = var.pinecone_index_name
    }
  }
}

resource "aws_lambda_function" "log_handler" {
  function_name = var.log_lambda_function_name
  handler       = "log.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket         = var.lambda_s3_bucket
  s3_key            = var.log_lambda_s3_key
  source_code_hash  = var.log_lambda_source_hash

  environment {
    variables = {
      PINECONE_ENV         = var.pinecone_env
      PINECONE_INDEX_NAME  = var.pinecone_index_name
    }
  }
}

resource "aws_lambda_permission" "allow_apigw_query" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_log" {
  statement_id  = "AllowExecutionFromAPIGatewayLog"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "thoughtspark_lambda_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
      Action = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" },
      Effect = "Allow",
      Sid    = ""
    }
    ]
  })
}
resource "aws_iam_policy" "lambda_policy" {
  name        = "thoughtspark_lambda_policy"
  description = "Policy for Lambda to access required resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:us-east-1:393800486110:secret:Pinecone_API_key-fL2g0U"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}