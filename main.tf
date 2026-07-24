# ./main.tf

# VPC module
module "vpc" {
  source = "./modules/vpc"
}

# EC2 module
module "ec2" {
  source              = "./modules/ec2"
  public_subnet_1a_id = module.vpc.public_subnet_1a_id
  bastion_sg_id       = module.vpc.bastion_sg_id
}

# Secrets module
module "secrets" {
  source      = "./modules/secrets"
  db_username = var.db_username
  db_password = var.db_password
}

# ECS/ECR module
module "ecs" {
  source                   = "./modules/ecs"
  private_app_subnet_1a_id = module.vpc.private_app_subnet_1a_id
  private_app_subnet_1c_id = module.vpc.private_app_subnet_1c_id
  app_sg_id                = module.vpc.app_sg_id
  ecr_api_endpoint_id      = module.vpc.ecr_api_endpoint_id
  ecr_dkr_endpoint_id      = module.vpc.ecr_dkr_endpoint_id
  s3_endpoint_id           = module.vpc.s3_endpoint_id
  target_group_arn         = module.alb.target_group_arn
  alb_listener_http_arn    = module.alb.alb_listener_http_arn
  db_host                  = module.rds.db_endpoint
  secret_arn               = module.secrets.secret_arn
}

# ALB module
module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = [
    module.vpc.public_subnet_1a_id,
    module.vpc.public_subnet_1c_id
  ]
  alb_security_group_id = module.vpc.alb_security_group_id
}

# RDS module
module "rds" {
  source = "./modules/rds"

  private_db_subnet_1a_id = module.vpc.private_db_subnet_1a_id
  private_db_subnet_1c_id = module.vpc.private_db_subnet_1c_id
  db_security_group_id    = module.vpc.db_security_group_id
  db_username             = var.db_username
  db_password             = var.db_password
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  notification_email      = var.notification_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  db_identifier           = module.rds.db_identifier
}
