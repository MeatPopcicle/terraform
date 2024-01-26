
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


