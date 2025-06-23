resource "aws_s3_bucket" "lambda_code" {
  bucket = var.lambda_s3_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lambda_code_block" {
  bucket = aws_s3_bucket.lambda_code.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}
