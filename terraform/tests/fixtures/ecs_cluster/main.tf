terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true
}

module "ecs_cluster" {
  source      = "../../../modules/compute/ecs_cluster"
  name        = "fixture-cluster"
  environment = "test"
  tags = {
    Component = "ecs-cluster"
  }
}
