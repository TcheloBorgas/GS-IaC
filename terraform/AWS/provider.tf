terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.23"
    }
  }
  backend "s3" {
    bucket         = "gs-iac"
    key            = "terraform.tfstate"
    dynamodb_table = "gs-iac"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}