#--------------------------------------------------------------------------------------------------
# 
# Creating a security group for a load balancer with specific ingress and egress rules.
#--------------------------------------------------------------------------------------------------
resource "aws_security_group" "lb" {
  name        = "example-alb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--------------------------------------------------------------------------------------------------
# 
# Creating a security group for the ECS task with specific ingress and egress rules.
#--------------------------------------------------------------------------------------------------
resource "aws_security_group" "hello_world_task" {
  name        = "example-task-security-group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


