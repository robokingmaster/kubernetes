module "eks" {  
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    key_name = "xxxxx-aws-key"
  }

  eks_managed_node_groups = {
    group1 = {
      name = "eks-${var.deployment_id}-nodegroup-1"
      
      instance_types = ["t2.2xlarge"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    # group2 = {
    #   name = "eks-${var.deployment_id}-nodegroup-2"
      
    #   instance_types = ["t2.2xlarge"]

    #   min_size     = 1
    #   max_size     = 2
    #   desired_size = 1
    # }
  }

  tags = {
    Name            = local.cluster_name
    Owner           = var.tag_resource_owner    
    OwnerEmailID    = var.tag_resource_owneremail
  }

  # Allow Jenkins User 
  access_entries = {
    # One access entry with a policy associated
    cluster_admin = {
      principal_arn     = "arn:aws:iam::${var.aws_account_number}:user/IAMUser_xxxxxx"

      policy_associations = {
        cluster = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
# https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "${module.eks.cluster_name}-EKSEBSCSIRole"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}