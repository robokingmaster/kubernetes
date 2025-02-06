terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {  
  region = var.aws_region 
}

locals {  
  instance_name     = "eis-jump-box-${var.deployment_id}"
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                   = local.instance_name
  ami                    = var.source_ami
  instance_type          = "t2.micro"
  key_name               = "xxxx-aws-key"
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  monitoring             = true

  associate_public_ip_address = true 

  root_block_device = [{
    volume_size = 100
    volume_type = "gp3"
  }]

  tags = {
    Name            = local.instance_name
    Owner           = var.tag_resource_owner
    OwnerEmailID    = var.tag_resource_owneremail    
  }
}