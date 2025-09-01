provider "aws" {
  region = "eu-central-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.minimal_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.minimal_eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.minimal_eks.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.minimal_eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.minimal_eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.minimal_eks.name]
    }
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "booking-app-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "booking-app-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for EBS CSI Driver (IRSA)
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "minimal_eks" {
  name = aws_eks_cluster.minimal_eks.name
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "booking-app-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.minimal_eks.identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.minimal_eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# VPC for EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "booking-app-eks-vpc"
  }
}

# Subnets
resource "aws_subnet" "eks_subnet_a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "booking-app-eks-subnet-a"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/booking-app-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "eks_subnet_b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "booking-app-eks-subnet-b"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/booking-app-eks-cluster" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "booking-app-eks-igw"
  }
}

# Route Table
resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "booking-app-eks-route-table"
  }
}

resource "aws_route_table_association" "eks_subnet_a" {
  subnet_id      = aws_subnet.eks_subnet_a.id
  route_table_id = aws_route_table.eks_route_table.id
}

resource "aws_route_table_association" "eks_subnet_b" {
  subnet_id      = aws_subnet.eks_subnet_b.id
  route_table_id = aws_route_table.eks_route_table.id
}

# Security Group for EKS
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  name   = "booking-app-eks-cluster-sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Restrict to VPC CIDR for better security
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true # Allow communication within the security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "booking-app-eks-sg"
  }
}

# Security Group for Nodes
resource "aws_security_group" "eks_node_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  name   = "booking-app-eks-node-sg"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_sg.id] # Allow traffic from EKS control plane
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true # Allow communication between nodes
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "booking-app-eks-node-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "minimal_eks" {
  name     = "booking-app-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
    security_group_ids = [aws_security_group.eks_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_route_table_association.eks_subnet_a,
    aws_route_table_association.eks_subnet_b
  ]
}

# OIDC Provider for IRSA
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = aws_eks_cluster.minimal_eks.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]
  tags = {
    provider = "eks-oidc"
  }
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"] # Update if needed
}

# EKS Node Group
resource "aws_eks_node_group" "minimal_node_group" {
  cluster_name    = aws_eks_cluster.minimal_eks.name
  node_group_name = "booking-app-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly,
    aws_eks_cluster.minimal_eks
  ]
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.minimal_eks.name
  addon_name              = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn

  depends_on = [
    aws_eks_node_group.minimal_node_group,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
}



# gp2-csi StorageClass
# resource "kubernetes_storage_class" "gp2_csi" {
#   metadata {
#     name = "gp2-csi"
#   }
#   storage_provisioner = "ebs.csi.aws.com"
#   volume_binding_mode = "WaitForFirstConsumer"
#   parameters = {
#     type = "gp2"
#   }
#   reclaim_policy = "Delete"
#
#   depends_on = [
#     aws_eks_addon.ebs_csi_driver
#   ]
# }

# Output



# IAM policy for ALB Controller
data "aws_iam_policy_document" "alb_controller" {
  statement {
    effect = "Allow"
    actions = [
      "acm:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "iam:*",
      "waf:*",
      "wafv2:*",
      "shield:*",

    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "ALBControllerPolicy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.alb_controller.json
}

# IAM Role for ServiceAccount
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.arn, format("arn:aws:iam::%s:oidc-provider/",var.accountId), "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.arn, format("arn:aws:iam::%s:oidc-provider/",var.accountId), "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "ALBControllerRole"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

# Output the role ARN
output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}

