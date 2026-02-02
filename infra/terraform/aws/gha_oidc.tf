data "aws_caller_identity" "current" {}

# GitHub's OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # This thumbprint is GitHub's commonly used root CA thumbprint.
  # If AWS ever requires an update, terraform will tell us during apply.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

locals {
  github_owner = "cj-ledet"
  github_repo  = "learning-repo"
  github_ref   = "refs/heads/main" # restrict to main branch
  ecr_repo_arn = aws_ecr_repository.learning_api.arn
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Lock this role to ONLY your repo AND ONLY main branch
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_owner}/${local.github_repo}:ref:${local.github_ref}"]
    }

    # Extra safety: ensure correct audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = "github-actions-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# Minimum-ish permissions to push images to this ECR repo
data "aws_iam_policy_document" "ecr_push" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages"
    ]
    resources = [local.ecr_repo_arn]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_inline" {
  name   = "github-actions-ecr-push"
  role   = aws_iam_role.github_actions_ecr.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr.arn
}
