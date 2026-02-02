resource "aws_ecr_repository" "learning_api" {
  name                 = "learning-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repo_url" {
  value = aws_ecr_repository.learning_api.repository_url
}
