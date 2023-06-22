terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
  }
}

provider "aws" {
  default_tags {
    Default = "Tag"
  }
}

module "perm" {
  source = ".."

  vpc_cidr = "10.0.0.0/16"
}

module "temp" {
  source = ".."

  vpc_cidr = "10.1.0.0/16"
}
