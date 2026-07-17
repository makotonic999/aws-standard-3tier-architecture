variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
  default   = "dummydummy"
}

variable "notification_email" {
  description = "Email address for CloudWatch Alarm notifications"
  type        = string
}