# =================================================================
# 各モジュール（カプセル）の呼び出しとバケツリレー
# =================================================================

# 1. VPC module
module "vpc" {
  source = "./modules/vpc"
}

# 2. EC2 module
/*
module "ec2" {
  source = "./modules/ec2"

  # VPC側から受け取ったデータをEC2側の窓口へ渡す
  vpc_id                   = module.vpc.vpc_id
  public_subnet_1a_id      = module.vpc.public_subnet_1a_id
  private_app_subnet_1a_id = module.vpc.private_app_subnet_1a_id
}
*/

# 3. RDS module
module "rds" {
  source = "./modules/rds"

  # VPCからネットワーク情報を渡す
  private_db_subnet_1a_id = module.vpc.private_db_subnet_1a_id
  private_db_subnet_1c_id = module.vpc.private_db_subnet_1c_id

  # EC2モジュールから「RDS用のセキュリティグループID」を受け取って渡す
  db_security_group_id = module.vpc.default_security_group_id

  # 直下の variables.tf を経由して届いたパスワードを流し込む
  db_username = var.db_username
  db_password = var.db_password
}

# 4. ECS/ECR module ( コンテナ環境の追加)
module "ecs" {
  source = "./modules/ecs"

  # vpc_id              = module.vpc.vpc_id
  # public_subnet_1a_id = module.vpc.public_subnet_1a_id
}