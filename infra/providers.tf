provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "thoughtspark-tf-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}
