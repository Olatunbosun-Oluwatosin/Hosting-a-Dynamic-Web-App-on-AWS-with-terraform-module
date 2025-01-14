provider "aws" {
  region = "us-east-1"
}

module "ecs" {
  source = "./modules/ecs"
  
  app_name    = "tosyeno-webapp"
  environment = "dev"
  app_image   = "509577086085.dkr.ecr.us-east-1.amazonaws.com/tosyeno-webapp:latest"
  
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  
  alb_security_group_id = module.alb.security_group_id
  target_group_arn     = module.alb.target_group_arn
  
  container_port = 3000  # Adjust based on your application
  
  container_environment = [
    {
      name  = "NODE_ENV"
      value = "production"
    }
  ]
}

module "vpc" {
  source = "./modules/vpc"
  
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
}

module "alb" {
  source = "./modules/alb"
  
  app_name          = "tosyeno-webapp"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 3000
  health_check_path = "/"
}