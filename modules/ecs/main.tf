###################################################################################################
###################################################################################################
# 
# ECS Module 
# 
###################################################################################################
###################################################################################################

###################################################################################################
#--------------------------------------------------------------------------------------------------
# VARIABLES.
#--------------------------------------------------------------------------------------------------
###################################################################################################
variable "app_count" {
  description = "number of app instances to start."
  type        = number
}

variable "vpc_id" {
  description = "The ID for the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "aws_subnet.public.*.id"
  type  = list(string)
}

variable "private_subnet_ids" {
  description = "aws_subnet.private.*.id"
  type  = list(string)
}

variable "security_group_lb" {
  description = "aws_security_group.lb"
  # type  = list(string)
}

variable "security_group_hello_world_task" {
  description = "aws_security_group.hello_world_task"
  # type  = list(string)
}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# ECS Resources.
#--------------------------------------------------------------------------------------------------
###################################################################################################

#--------------------------------------------------------------------------------------------------
# Creating an Application Load Balancer (ALB) and attaching it to 
# the public subnets and the created security group.
#--------------------------------------------------------------------------------------------------
resource "aws_lb" "default" {
  name            = "example-lb"
  subnets         = var.public_subnet_ids
  security_groups = [var.security_group_lb.id]
}

#--------------------------------------------------------------------------------------------------
# Creating a target group for the load balancer, 
# which will be used to route requests to the application.
#--------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "hello_world" {
  name        = "example-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      =  var.vpc_id
  target_type = "ip"
}

#--------------------------------------------------------------------------------------------------
# Creating a listener for the ALB, which checks for incoming HTTP requests on port 80 and 
# forwards them to the target group.
#--------------------------------------------------------------------------------------------------
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
# Defining an ECS task definition for the "hello world" application. 
# This includes the container image, CPU, and memory specifications.
#--------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  #------------------------------------------------------------------------------------------------
  # Container definition in JSON format, specifying the Docker image, CPU and memory allocation, 
  # and port mappings.
  #------------------------------------------------------------------------------------------------
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

#--------------------------------------------------------------------------------------------------
# Creating an ECS cluster named "example-cluster".
#--------------------------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "example-cluster"
}

#--------------------------------------------------------------------------------------------------
# Deploying the "hello world" service on ECS. 
# It defines the number of tasks, the launch type, and network configuration.
#--------------------------------------------------------------------------------------------------
resource "aws_ecs_service" "hello_world" {
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  #------------------------------------------------------------------------------------------------
  # Network configuration for the service, specifying the security groups and subnets.
  #------------------------------------------------------------------------------------------------
  network_configuration {
    security_groups = [var.security_group_hello_world_task.id]
    subnets         = var.private_subnet_ids
  }

  #------------------------------------------------------------------------------------------------
  # Load balancer configuration, linking the service to the ALB's target group.
  #------------------------------------------------------------------------------------------------
  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.id
    container_name   = "hello-world-app"
    container_port   = 3000
  }

  #------------------------------------------------------------------------------------------------
  # Ensuring the load balancer listener is created before the service.
  #------------------------------------------------------------------------------------------------
  depends_on = [aws_lb_listener.hello_world]
}


###################################################################################################
#--------------------------------------------------------------------------------------------------
# OUTPUTS.
#--------------------------------------------------------------------------------------------------
###################################################################################################

output "load_balancer_ip" {
  value = aws_lb.default.dns_name
}
