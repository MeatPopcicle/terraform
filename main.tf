#--------------------------------------------------------------------------------------------------
# Variables
#--------------------------------------------------------------------------------------------------
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


#--------------------------------------------------------------------------------------------------
# Providers
#--------------------------------------------------------------------------------------------------
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


# Data source to get the list of available AWS availability zones in the region
data "aws_availability_zones" "available_zones" {
  state = "available"
}


#--------------------------------------------------------------------------------------------------
# VPC
#--------------------------------------------------------------------------------------------------
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones   = data.aws_availability_zones.available_zones.names
}


#--------------------------------------------------------------------------------------------------
# Security
#--------------------------------------------------------------------------------------------------
module "security" {
  source               = "./modules/security"
  vpc_id               = module.vpc.vpc_id
}


# Creating an Application Load Balancer (ALB) and attaching it to the public subnets and the created security group.
resource "aws_lb" "default" {
  name            = "example-lb"
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.security.security_group_lb.id]
}

# Creating a target group for the load balancer, which will be used to route requests to the application.
resource "aws_lb_target_group" "hello_world" {
  name        = "example-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      =  module.vpc.vpc_id
  target_type = "ip"
}

# Creating a listener for the ALB, which checks for incoming HTTP requests on port 80 and forwards them to the target group.
resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hello_world.id
    type             = "forward"
  }
}


#--------------------------------------------------------------------------------------------------
# 
# Defining an ECS task definition for the "hello world" application. This includes the container image, CPU, and memory specifications.
#--------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  # Container definition in JSON format, specifying the Docker image, CPU and memory allocation, and port mappings.
  container_definitions = <<DEFINITION
[
  {
    "image": "registry.gitlab.com/architect-io/artifacts/nodejs-hello-world:latest",
    "cpu": 1024,
    "memory": 2048,
    "name": "hello-world-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
DEFINITION
}


# Creating an ECS cluster named "example-cluster".
resource "aws_ecs_cluster" "main" {
  name = "example-cluster"
}


#--------------------------------------------------------------------------------------------------
# 
# Deploying the "hello world" service on ECS. It defines the number of tasks, the launch type, and network configuration.
#--------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "hello_world" {
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  # Network configuration for the service, specifying the security groups and subnets.
  network_configuration {
    security_groups = [module.security.security_group_hello_world_task.id]
    subnets         = module.vpc.private_subnet_ids
  }

  # Load balancer configuration, linking the service to the ALB's target group.
  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.id
    container_name   = "hello-world-app"
    container_port   = 3000
  }

  # Ensuring the load balancer listener is created before the service.
  depends_on = [aws_lb_listener.hello_world]
}
