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

# ===========================================================
# Unused Variables (Currently not used since RDS was removed)
# ===========================================================
/*
module "rds" {
  source = "./modules/rds"

  private_db_subnet_1a_id = module.vpc.private_db_subnet_1a_id
  private_db_subnet_1c_id = module.vpc.private_db_subnet_1c_id
  db_security_group_id = module.vpc.default_security_group_id
  db_username = var.db_username
  db_password = var.db_password
}
*/