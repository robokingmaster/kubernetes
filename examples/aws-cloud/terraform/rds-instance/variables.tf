
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "db_password" {
  description = "RDS root user password"
  sensitive   = true
}

# Tags For Resources
variable "tag_resource_owner" {
  description = "Tag Owner"
  type        = string
}

variable "tag_resource_owneremail" {
  description = "Tag OwnerEmailID"
  type        = string
}

# Deployment Information
variable "deployment_id" {
  description = "Deployment Unique ID For Suffix"
  type        = string
}