terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = var.region }
data "aws_availability_zones" "available" {}
locals {
  cluster_name = var.cluster_name
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  azs = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  public_subnet_tags = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  cluster_name = local.cluster_name
  cluster_version = "1.30"
  cluster_endpoint_public_access = true
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  eks_managed_node_groups = {
    default = {
      capacity_type = "SPOT"
      instance_types = var.instance_types
      min_size = 1
      max_size = 4
      desired_size = var.desired_size
    }
  }
  enable_cluster_creator_admin_permissions = true
  tags = { Project = "devops-demo", ManagedBy = "terraform" }
}
resource "aws_ecr_repository" "app" {
  name = "devops-demo-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
}
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description = "Keep only the last 5 images"
      selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 5 }
      action = { type = "expire" }
    }]
  })
}
