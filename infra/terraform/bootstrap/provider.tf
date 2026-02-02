variable "aws_region" {
  description = "AWS region to deploy bootstrap resources into"
  type        = string
  default     = "us-west-2"
}

provider "aws" {
  region = var.aws_region
}
