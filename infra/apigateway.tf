resource "aws_apigatewayv2_api" "api" {
  name          = "ThoughtSparkAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "query_lambda_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.query_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "log_lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.log_handler.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "query_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /query"
  target    = "integrations/${aws_apigatewayv2_integration.query_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "log_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /log"
  target    = "integrations/${aws_apigatewayv2_integration.log_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}