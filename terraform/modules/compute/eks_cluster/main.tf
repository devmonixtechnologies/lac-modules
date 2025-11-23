terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = "eks"
  additional_tags = var.tags
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name                = "${var.environment}-${var.service}-eks-cluster"
  assume_role_policy  = data.aws_iam_policy_document.cluster_assume.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "cluster_additional" {
  count      = length(var.cluster_additional_policy_arns) > 0 ? length(var.cluster_additional_policy_arns) : 0
  role       = aws_iam_role.cluster.name
  policy_arn = var.cluster_additional_policy_arns[count.index]
}

resource "aws_security_group" "cluster" {
  name        = "${var.environment}-${var.service}-eks-cluster-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
    ip_family         = var.ip_family
  }

  dynamic "encryption_config" {
    for_each = var.enable_secrets_encryption ? [1] : []
    content {
      resources = var.encryption_resources
      provider {
        key_arn = aws_kms_key.secrets[0].arn
      }
    }
  }

  dynamic "outpost_config" {
    for_each = var.outpost_config != null ? [var.outpost_config] : []
    content {
      outpost_arns = outpost_config.value.outpost_arns
      control_plane_instance_type = outpost_config.value.control_plane_instance_type
    }
  }

  dynamic "compute_config" {
    for_each = var.compute_config != null ? [var.compute_config] : []
    content {
      enabled = compute_config.value.enabled
      node_roles = compute_config.value.node_roles
      subnet_ids = compute_config.value.subnet_ids
    }
  }

  tags = merge(module.tags.tags, var.tags_override)

  depends_on = [aws_iam_role_policy_attachment.cluster_additional]
}

resource "aws_kms_key" "secrets" {
  count = var.enable_secrets_encryption ? 1 : 0

  description             = "EKS cluster secret encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = var.kms_admin_arns
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:Tag*",
          "kms:Untag*",
          "kms:ScheduleKeyDeletion*",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cluster.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_kms_alias" "secrets" {
  count = var.enable_secrets_encryption ? 1 : 0
  name  = "alias/${var.environment}-${var.service}-eks-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  count = var.create_node_group ? 1 : 0
  name  = "${var.environment}-${var.service}-eks-node"

  assume_role_policy = data.aws_iam_policy_document.node_assume.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "node_additional" {
  count      = var.create_node_group && length(var.node_additional_policy_arns) > 0 ? length(var.node_additional_policy_arns) : 0
  role       = aws_iam_role.node[0].name
  policy_arn = var.node_additional_policy_arns[count.index]
}

resource "aws_security_group" "node" {
  count = var.create_node_group ? 1 : 0
  name  = "${var.environment}-${var.service}-eks-node-sg"

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_eks_node_group" "this" {
  count = var.create_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = var.node_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  ami_type      = var.ami_type
  capacity_type = var.capacity_type

  disk_size = var.disk_size

  remote_access {
    ssh_key_name = var.ssh_key_name
    source_security_group_ids = var.node_remote_access_sg_ids
  }

  labels = merge(var.node_labels, {
    role = var.node_group_name
  })

  taint {
    key    = var.node_taint_key
    value  = var.node_taint_value
    effect = var.node_taint_effect
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  tags = merge(module.tags.tags, var.tags_override)

  depends_on = [
    aws_iam_role_policy_attachment.node_additional
  ]
}

resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  addon_version = var.coredns_addon_version
  resolve_conflicts_on_create = var.coredns_resolve_conflicts
  resolve_conflicts_on_update = var.coredns_resolve_conflicts

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  addon_version = var.kube_proxy_addon_version
  resolve_conflicts_on_create = var.kube_proxy_resolve_conflicts
  resolve_conflicts_on_update = var.kube_proxy_resolve_conflicts

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  addon_version = var.vpc_cni_addon_version
  resolve_conflicts_on_create = var.vpc_cni_resolve_conflicts
  resolve_conflicts_on_update = var.vpc_cni_resolve_conflicts

  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = var.enable_prefix_delegation
      WARM_PREFIX_TARGET       = var.warm_prefix_target
    }
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = each.value.pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = lookup(each.value, "labels", {})
  }

  tags = merge(module.tags.tags, var.tags_override)
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_lb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.aws_lb_controller_chart_version

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller[0].arn
  }

  depends_on = [aws_eks_node_group.this]
}

resource "aws_iam_role" "aws_lb_controller" {
  count = var.enable_aws_lb_controller ? 1 : 0
  name  = "${var.environment}-${var.service}-aws-lb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  count      = var.enable_aws_lb_controller ? 1 : 0
  role       = aws_iam_role.aws_lb_controller[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}

data "aws_caller_identity" "current" {}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data of the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = var.create_node_group ? aws_eks_node_group.this[0].arn : null
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = var.create_node_group ? aws_iam_role.node[0].arn : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = var.enable_secrets_encryption ? aws_kms_key.secrets[0].arn : null
}
