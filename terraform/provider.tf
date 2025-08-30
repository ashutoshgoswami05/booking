terraform {
  backend "s3" {
    bucket         = "tf-state-bucket-112233"
    key            = "terraform/s3/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}