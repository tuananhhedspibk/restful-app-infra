
locals {
  app_name = "restful-app"
  env_name = "stg"

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnets_cidr = ["10.0.30.0/24", "10.0.40.0/24"]

  target_health_check_path = "/v1/health"
  target_health_check_port = 80
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket  = "tfstate-restful-app-stg"
    region  = "ap-northeast-1"
    key     = "terraform.state"
    encrypt = true
    profile = "default"
  }
}

module "network" {
  source = "../../modules/network"

  env_name             = local.env_name
  app_name             = local.app_name
  vpc_cidr             = local.vpc_cidr
  availability_zones   = local.availability_zones
  public_subnets_cidr  = local.public_subnets_cidr
  private_subnets_cidr = local.private_subnets_cidr
}

module "role" {
  source = "../../modules/role"

  env_name = local.env_name
  app_name = local.app_name
}

module "proxy" {
  source = "../../modules/proxy"

  env_name  = local.env_name
  app_name  = local.app_name
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.public_subnet_ids[0]
}

module "eks" {
  source = "../../modules/eks"

  env_name                    = local.env_name
  app_name                    = local.app_name
  iam_cluster_role_arn        = module.role.iam_cluster_role_arn
  iam_node_role_arn           = module.role.iam_node_role_arn
  subnet_ids                  = module.network.private_subnet_ids
  eks_node_group_max_size     = 3
  eks_node_group_min_size     = 1
  eks_node_group_desired_size = 2
}

module "alb" {
  source = "../../modules/alb"

  env_name                 = local.env_name
  app_name                 = local.app_name
  target_health_check_path = local.target_health_check_path
  target_health_check_port = local.target_health_check_port
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
}

data "aws_secretsmanager_secret" "database_secret" {
  name = "database"
}

data "aws_secretsmanager_secret_version" "database_secret_version" {
  secret_id = data.aws_secretsmanager_secret.database_secret.id
}

locals {
  secret_json = jsondecode(data.aws_secretsmanager_secret_version.database_secret_version.secret_string)
}

module "database" {
  source = "../../modules/database"

  env_name             = local.env_name
  app_name             = local.app_name
  vpc_id               = module.network.vpc_id
  port                 = local.secret_json["DATABASE_PORT"]
  proxy_security_group = module.proxy.security_group_id
  vpc_cidr             = local.vpc_cidr
  subnet_ids           = module.network.private_subnet_ids
  master_username      = local.secret_json["DATABASE_USERNAME"]
  master_password      = local.secret_json["DATABASE_PASSWORD"]
  database_name        = local.secret_json["DATABASE_NAME"]
}

module "ecr" {
  source = "../../modules/ecr"
}
