output "lambda_function_name" {
  value = aws_lambda_function.query_handler.function_name
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}
