variable "db_username" {
  description = "RDSのマスタユーザ名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDSのマスタパスワード"
  type        = string
  sensitive   = true
}