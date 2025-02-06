variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

# Networking Informations
variable "vpc_id" {
  description = "VPC ID where this instance will be created"
  type        = string  
}

variable "subnet_id" {
  description = "Subnet ID where this instance will be created"
  type        = string  
}

variable "source_ami" {
  description = "Source AMI from which the instance will be created"
  type        = string  
}

variable "vpc_security_group_ids" {
  description = "Security Group Ids In VPC where this instance will be created"
  type        = list(string)
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