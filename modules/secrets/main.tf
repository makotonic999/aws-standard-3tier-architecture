# modules/secrets/main.tf

resource "aws_secretsmanager_secret" "db" {
  name                    = "standard-db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
