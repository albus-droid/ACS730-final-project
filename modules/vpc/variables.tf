variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "GroupX-VPC"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "azs" {
  description = "List of Availability Zones in the region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "environment" {
  description = "Name of the current environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "GroupX-Final-Project"
  }
}
