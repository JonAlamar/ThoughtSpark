variable "lambda_function_name" {
  default = "thoughtspark-query-handler"
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
