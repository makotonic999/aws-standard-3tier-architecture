terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "standard-3tier-tfstate"
    key            = "terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "standard-3tier-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}