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
  region = var.region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {  
  vpc_name     = "rdsexample-vpc-${var.deployment_id}"
  subnet_name  = "rdsexample-subnet-${var.deployment_id}"
  sg_name      = "rdsexample-sg-${var.deployment_id}"
  db_params    = "rdsexample-dbparams-${var.deployment_id}"
  db_identifier= "rdsexample-${var.deployment_id}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                 = local.vpc_name
  cidr                 = "10.0.0.0/16"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets       = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = local.subnet_name
  subnet_ids = module.vpc.public_subnets

  tags = {    
    Owner           = var.tag_resource_owner
    OwnerEmailID    = var.tag_resource_owneremail    
  }
}

resource "aws_security_group" "rds" {
  name   = local.sg_name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {    
    Owner           = var.tag_resource_owner
    OwnerEmailID    = var.tag_resource_owneremail    
  }
}

resource "aws_db_parameter_group" "dbparametergroup" {
  name   = local.db_params
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "dbinstance" {
  identifier             = local.db_identifier
  instance_class         = "db.m5.large"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.15"
  username               = "dbadmin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.dbsubnetgroup.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.dbparametergroup.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}