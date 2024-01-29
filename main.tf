###################################################################################################
###################################################################################################
# 
# One main.tf to rule them all. 
# 
###################################################################################################
###################################################################################################

###################################################################################################
#--------------------------------------------------------------------------------------------------
# Variables
#--------------------------------------------------------------------------------------------------
###################################################################################################
variable "app_count" {
  type = number
  default = 1
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# Providers
#--------------------------------------------------------------------------------------------------
###################################################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key 

  default_tags {
    tags = {
      Name = "demo"
    }
  }
}

#--------------------------------------------------------------------------------------------------
# Data source to get the list of available AWS availability zones in the region
#--------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available_zones" {
  state = "available"
}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# Modules
#--------------------------------------------------------------------------------------------------
###################################################################################################

#---------------------------------------------------------------------
# VPC
#---------------------------------------------------------------------
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones   = data.aws_availability_zones.available_zones.names
}

#---------------------------------------------------------------------
# Security
#---------------------------------------------------------------------
module "security" {
  source               = "./modules/security"
  vpc_id               = module.vpc.vpc_id
}

#---------------------------------------------------------------------
# ECS 
#---------------------------------------------------------------------
module "ecs" {
  source                          = "./modules/ecs"
  app_count                       = var.app_count
  vpc_id                          = module.vpc.vpc_id
  public_subnet_ids               = module.vpc.public_subnet_ids
  private_subnet_ids              = module.vpc.private_subnet_ids
  security_group_lb               = module.security.security_group_lb
  security_group_hello_world_task = module.security.security_group_hello_world_task
  # load_balancer_arn               = aws_lb.default.id
  # target_group_arn                = aws_lb_target_group.hello_world.id
  # cluster                         = aws_ecs_cluster.main.id
  # task_definition                 = aws_ecs_task_definition.hello_world.arn
  # target_group_arn                = aws_lb_target_group.hello_world.id
  # depends_on                      = [aws_lb_listener.hello_world]
}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# OUTPUTS.
#--------------------------------------------------------------------------------------------------
###################################################################################################

# output "load_balancer_ip" {
#   value = module.ecs.default.dns_name
# }

