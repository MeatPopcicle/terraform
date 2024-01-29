###################################################################################################
###################################################################################################
# 
# VPC Module  
# 
###################################################################################################
###################################################################################################

###################################################################################################
#--------------------------------------------------------------------------------------------------
# VARIABLES.
#--------------------------------------------------------------------------------------------------
###################################################################################################

variable "vpc_cidr" {}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
}

variable "availability_zones" {
  type = list(string)
}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# VPC Resources.
#--------------------------------------------------------------------------------------------------
###################################################################################################
resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, 2 + count.index)
  availability_zone       = var.availability_zones[count.index]
  vpc_id                  = aws_vpc.default.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  vpc_id            = aws_vpc.default.id
}


#--------------------------------------------------------------------------------------------------
# Creating an Internet Gateway and attaching it to the VPC. 
# This enables communication between instances in the VPC and the internet.
#--------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

#--------------------------------------------------------------------------------------------------
# Creating NAT Gateways in the public subnets. 
# This allows instances in private subnets to access the internet.
#--------------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

#--------------------------------------------------------------------------------------------------
# Creating route tables for the private subnets. 
# These route tables will route internet-bound traffic to the NAT Gateways.
#--------------------------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.default.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

#--------------------------------------------------------------------------------------------------
# Associating the created private route tables with the private subnets.
#--------------------------------------------------------------------------------------------------
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

###################################################################################################
#--------------------------------------------------------------------------------------------------
# OUTPUTS.
#--------------------------------------------------------------------------------------------------
###################################################################################################

output "vpc_id" {
  value = aws_vpc.default.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
  # type  = list(string)
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
  # type  = list(string)
}
