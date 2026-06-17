resource "aws_ecr_repository" "app" {
  name                 = "standard-webapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 今後のECS構築（タスク定義など）でリポジトリURLを使い回せるようにoutputしておく
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}