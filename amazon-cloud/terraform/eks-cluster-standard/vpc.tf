
provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name  = "eks${var.deployment_id}-cc${var.tag_resource_costcenter}"  
  vpc_name      = "eis-eks-vpc-${var.deployment_id}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  name                 = local.vpc_name
  cidr                 = "10.0.0.0/16"
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24"]
  
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
    
  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# Allow All Network All Incoming Traffic
resource "aws_security_group" "my_access_sg" {
  name = "my-access-${var.deployment_id}-sg"
  description = "Security group for admins subnet for deployment ${var.deployment_id}"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Allow all inbound traffic from My Locations"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [
      module.vpc.vpc_cidr_block,
      "xxx.xxx.xxx.xxx/24",
      "xxx.xxx.xxx.xxx/24"
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "my_access_sg-${var.deployment_id}"
  } 
}
