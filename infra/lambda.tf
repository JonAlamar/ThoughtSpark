
resource "aws_lambda_function" "query_handler" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/../lambda/lambda.zip"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      PINECONE_ENV         = var.pinecone_env
      PINECONE_INDEX_NAME  = var.pinecone_index_name
    }
  }
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_handler.function_name
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
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" },
      Effect = "Allow",
      Sid    = ""
    },
    {
      Effect = "Allow",
      Action = "secretsmanager:GetSecretValue",
      Resource = "arn:aws:secretsmanager:us-east-1:393800486110:secret:thoughtspark/pinecone-zWcZXG"
    }]
  })
}