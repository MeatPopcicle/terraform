terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAVJ2FQHIHTZ2N7CGB"
  secret_key = "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"

  default_tags {
    tags = {
      Name = "demo"
    }
  }
}
