variable "lambda_function_name" {
  default = "thoughtspark-query-handler"
}

variable "lambda_s3_bucket" {
  default = "thoughtspark-lambda-code"
}

variable "lambda_s3_key" {
  default = "thoughtspark/lambda.zip"
}

variable "pinecone_api_key" {}
variable "pinecone_env" {}
variable "pinecone_index_name" {}
