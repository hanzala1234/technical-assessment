provider "aws" {
  region = var.region
}
terraform {
  required_providers {
     aws = {
        source = "hashicorp/aws"
        version = "~> 3.9.0"
     }

  }
  backend "s3" {
    bucket = "mh-technical-recuritment-tf"
    key = "tfstate/"
    region = "eu-west-3"
  }
}