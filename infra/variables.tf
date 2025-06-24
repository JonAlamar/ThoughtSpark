variable "query_lambda_function_name" {
  default = "thoughtspark-query-handler"
}

variable "log_lambda_function_name" {
  default = "thoughtspark-log-handler"
}

variable "lambda_s3_bucket" {
  default = "thoughtspark-lambda-code"
}

variable "lambda_s3_key" {
  default = "thoughtspark/lambda.zip"
}

variable "pinecone_env" {
  default = "us-east-1-aws"
}
variable "pinecone_index_name" {
  default = "thoughtspark-index"
}
variable "lambda_source_hash" {
  description = "The source code hash for the Lambda function deployment package."
  type        = string
}