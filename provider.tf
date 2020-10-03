provider "aws" {
  region = var.region
}
terraform {
  backend "s3" {
    bucket = "mh-technical-recuritment-tf"
    key = "tfstate/"
    region = "eu-west-3"
  }
}