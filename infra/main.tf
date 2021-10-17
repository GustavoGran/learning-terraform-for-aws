terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 3.0"
      }
  }
}

# Configure the AWS Provider Block
provider "aws" {
    region = "us-east-2"
    profile = "dev"
    shared_credentials_file = "../creds_folder/creds"
}