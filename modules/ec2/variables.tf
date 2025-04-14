variable "instances" {
  description = "List of maps containing configuration for each EC2 instance."
  type = list(object({
    name                        = string
    instance_type               = string
    ami                         = string
    subnet_id                   = string
    key_name                    = string
    security_group_ids          = list(string)
    associate_public_ip_address = optional(bool, false)
    user_data                   = optional(string, "")
  }))
}

variable "environment" {
  description = "The environment for this deployment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags to apply to all instances."
  type        = map(string)
  default     = {}
}
