provider "aws" {
  region = "us-east-2"
}

# Creating my VPC
resource "aws_vpc" "socks_shop" {
  cidr_block = "10.0.0.0/16"
}

# Creating a subnet
resource "aws_subnet" "socks_shop" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.socks_shop.id
  availability_zone = "us-east-2a"
}

# Creating my Kubernetes cluster
resource "aws_eks_cluster" "socks_shop" {
  name     = "socks-shop-cluster"
  role_arn = aws_iam_role.socks_shop.arn

  vpc_config {
    subnet_ids = [aws_subnet.socks_shop.id]
  }
}

# Creating my Kubernetes node group
resource "aws_eks_node_group" "socks_shop" {
  cluster_name    = aws_eks_cluster.socks_shop.name
  node_group_name = "socks-shop-nodes"
  node_role_arn   = aws_iam_role.socks_shop.arn
  subnet_ids      = [aws_subnet.socks_shop.id]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }
}

# Creating an IAM role for the Kubernetes cluster
resource "aws_iam_role" "socks_shop" {
  name        = "socks-shop-cluster-role"
  description = "EKS cluster role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

# Creating an IAM policy for the Kubernetes cluster
resource "aws_iam_policy" "socks_shop" {
  name        = "socks-shop-cluster-policy"
  description = "EKS cluster policy"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "cloudwatch:*",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

# Attaching the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "socks_shop" {
  role       = aws_iam_role.socks_shop.name
  policy_arn = aws_iam_policy.socks_shop.arn
}
