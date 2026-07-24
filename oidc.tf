# ------------------------------------------------------------------------------
# 1. GitHub OIDC Identity Provider Configuration
# ------------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub's OIDC thumbprint. Securely managed by AWS, this fixed value is standard.
  thumbprint_list = [] # AWS now automatically manages thumbprints
}

# ------------------------------------------------------------------------------
# 2. IAM Role and Assume Role Trust Policy for GitHub Actions
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Restrict access to requests coming from the standard audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict access only to your specific GitHub repository and branches
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:makotonic999/aws-standard-3tier-architecture:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# ------------------------------------------------------------------------------
# 3. IAM Policy for Deployment Permissions (ECR & ECS)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_deploy" {
  # Permissions required to authenticate, build, and push images to ECR
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }

  # Permissions required to register task definitions and update ECS services
  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }

  # Permissions required for Terraform to manage tfstate
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::standard-3tier-tfstate",
      "arn:aws:s3:::standard-3tier-tfstate/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:ap-northeast-1:*:table/standard-3tier-tfstate-lock"]
  }

  # Permissions required for Terraform plan (read-only on all managed resources)
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "secretsmanager:Describe*",
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
      "cloudwatch:Describe*",
      "cloudwatch:GetDashboard",
      "cloudwatch:ListTagsForResource",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTagsForResource",
      "sns:GetSubscriptionAttributes",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRolePolicy",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "logs:Describe*",
      "logs:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

# Create a standalone IAM policy resource
resource "aws_iam_policy" "github_actions_deploy" {
  name        = "github-actions-deploy-policy"
  description = "Policy for GitHub Actions to deploy to ECR and ECS"
  policy      = data.aws_iam_policy_document.github_actions_deploy.json
}

# Attach the policy to the GitHub Actions deployment role
resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}

# ------------------------------------------------------------------------------
# 4. Outputs
# ------------------------------------------------------------------------------
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The ARN of the IAM role for GitHub Actions workflow configuration"
}