variable "name" {
  description = "Name of the ALB"
  type        = string
}

variable "load_balancer_type" {
  description = "Type of load balancer. Usually 'application'"
  type        = string
  default     = "application"
}

variable "subnet_ids" {
  description = "List of subnets where the ALB will be deployed"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security groups to attach to the ALB"
  type        = list(string)
}

variable "idle_timeout" {
  description = "Idle timeout setting for the ALB in seconds"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to ALB resources"
  type        = map(string)
  default     = {}
}

# Variables for the Target Group
variable "vpc_id" {
  description = "VPC ID to associate with the target group"
  type        = string
}

variable "target_group_name_prefix" {
  description = "Prefix for the target group name"
  type        = string
}

variable "target_group_port" {
  description = "Port on which the target group receives traffic"
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the target group (HTTP, HTTPS, etc.)"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda)"
  type        = string
  default     = "instance"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks required before considering an instance healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required before considering an instance unhealthy"
  type        = number
  default     = 3
}

variable "health_check_interval" {
  description = "Interval (in seconds) between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout (in seconds) for a health check"
  type        = number
  default     = 5
}

variable "health_check_path" {
  description = "Path used for the health check"
  type        = string
  default     = "/"
}

# Listener variables
variable "listener_port" {
  description = "Port for the ALB listener"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Protocol for the ALB listener (HTTP, HTTPS, etc.)"
  type        = string
  default     = "HTTP"
}
