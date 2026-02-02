terraform {
  backend "s3" {
    bucket         = "tfstate-learning-repo-54701e82"
    key            = "aws/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tf-locks-learning-repo"
    encrypt        = true
  }
}
