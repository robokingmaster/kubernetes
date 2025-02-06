### Multiple EC2 Instances With Different Configurations

locals {
  multiple_instances = {
    ec2instanceone = {
        name                   = "instance-one-${var.deployment_id}"        
        ami                    = var.source_ami
        instance_type          = "t2.micro"
        subnet_id              = var.subnet_id
        vpc_security_group_ids = var.vpc_security_group_ids
        monitoring             = true

        associate_public_ip_address = false

        root_block_device = [{
            volume_size = 50
            volume_type = "gp2"
        }]
    }
    ec2instancetwo = {
        name                   = "instance-two-${var.deployment_id}"        
        ami                    = var.source_ami
        instance_type          = "t2.micro"  
        subnet_id              = var.subnet_id
        monitoring             = true
        vpc_security_group_ids = ["sg-xxxxx","sg-xxxxx","sg-xxxxx"]       
        
        associate_public_ip_address = true

        root_block_device = [{
            volume_size = 100
            volume_type = "gp2"
        }]        
    }
  }
}

module "ec2_multiple" {
    source = "terraform-aws-modules/ec2-instance/aws"

    for_each = local.multiple_instances

    name                   = each.value.name
    ami                    = each.value.ami
    instance_type          = each.value.instance_type    
    subnet_id              = each.value.subnet_id
    vpc_security_group_ids = lookup(each.value, "vpc_security_group_ids", [])    
    key_name               = "xxxx-aws-key"
    root_block_device      = lookup(each.value, "root_block_device", [])

    enable_volume_tags     = true
    associate_public_ip_address = each.value.associate_public_ip_address    

    tags = {
        Name            = each.value.name
        Owner           = var.tag_resource_owner
        CostCenterCode  = var.tag_resource_costcenter
        Department      = var.tag_resource_department
        Manager         = var.tag_resource_manager
        OwnerEmailID    = var.tag_resource_owneremail
    }  
}