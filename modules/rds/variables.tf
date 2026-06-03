variable "private_db_subnet_1a_id" {
  type        = string
  description = "The ID of the private DB subnet 1a"
}

variable "private_db_subnet_1c_id" {
  type        = string
  description = "The ID of the private DB subnet 1c"
}

variable "db_security_group_id" {
  type        = string
  description = "The ID of the security group for RDS"
}

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